<?php

require_once __DIR__ . '/database.php';

function getFcmAccessToken(): ?string {
    $cacheFile = __DIR__ . '/fcm_token_cache.json';

    if (file_exists($cacheFile)) {
        $cache = json_decode(file_get_contents($cacheFile), true);
        if ($cache && isset($cache['expires_at']) && $cache['expires_at'] > time() + 60) {
            return $cache['access_token'];
        }
    }

    $accountFile = __DIR__ . '/cinetrack-firebase-service-account.json';
    if (!file_exists($accountFile)) {
        error_log('Firebase service account file not found');
        return null;
    }

    $account = json_decode(file_get_contents($accountFile), true);
    if (!$account || !isset($account['client_email'], $account['private_key'])) {
        error_log('Invalid Firebase service account JSON');
        return null;
    }

    $now = time();
    $header = base64url_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    $claims = base64url_encode(json_encode([
        'iss' => $account['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now,
    ]));

    $signature = '';
    $privateKey = openssl_pkey_get_private($account['private_key']);
    if (!$privateKey) {
        error_log('Failed to load private key');
        return null;
    }
    openssl_sign("$header.$claims", $signature, $privateKey, OPENSSL_ALGO_SHA256);
    openssl_free_key($privateKey);
    $jwt = "$header.$claims." . base64url_encode($signature);

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => 'https://oauth2.googleapis.com/token',
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
        CURLOPT_POSTFIELDS => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
        error_log("FCM token exchange failed: HTTP $httpCode - $response");
        return null;
    }

    $result = json_decode($response, true);
    if (!isset($result['access_token'], $result['expires_in'])) {
        error_log('FCM token exchange invalid response');
        return null;
    }

    $cacheData = [
        'access_token' => $result['access_token'],
        'expires_at' => $now + (int) $result['expires_in'],
    ];
    file_put_contents($cacheFile, json_encode($cacheData), LOCK_EX);

    return $result['access_token'];
}

function base64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function sendFcmNotification(int $userId, string $title, string $body, array $data = []): void {
    $pdo = getDb();
    $stmt = $pdo->prepare('SELECT token FROM fcm_tokens WHERE user_id = ?');
    $stmt->execute([$userId]);
    $tokens = $stmt->fetchAll(PDO::FETCH_COLUMN);

    if (empty($tokens)) {
        return;
    }

    $accessToken = getFcmAccessToken();
    if ($accessToken === null) {
        error_log('Cannot send FCM: no access token');
        return;
    }

    $projectId = getenv('FIREBASE_PROJECT_ID') ?: 'cinetrack-48c15';

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
    ]);

    $tokensToDelete = [];

    foreach ($tokens as $token) {
        $message = [
            'message' => [
                'token' => $token,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
            ],
        ];

        if (!empty($data)) {
            $message['message']['data'] = $data;
        }

        curl_setopt($ch, CURLOPT_URL, "https://fcm.googleapis.com/v1/projects/$projectId/messages:send");
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($httpCode === 404) {
            $result = json_decode($response, true);
            if (isset($result['error']['details'][0]['errorCode']) &&
                ($result['error']['details'][0]['errorCode'] === 'UNREGISTERED')) {
                $tokensToDelete[] = $token;
            }
        } elseif ($httpCode !== 200) {
            error_log("FCM send error (HTTP $httpCode): $response");
        }
    }

    curl_close($ch);

    if (!empty($tokensToDelete)) {
        $placeholders = implode(',', array_fill(0, count($tokensToDelete), '?'));
        $deleteStmt = $pdo->prepare("DELETE FROM fcm_tokens WHERE user_id = ? AND token IN ($placeholders)");
        $deleteStmt->execute(array_merge([$userId], $tokensToDelete));
    }
}
