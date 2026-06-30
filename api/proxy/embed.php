<?php
require_once __DIR__ . '/../config/streaming.php';

header('Content-Type: text/html; charset=utf-8');
header('Access-Control-Allow-Origin: ' . (getenv('CORS_ORIGIN') ?: '*'));

function createStreamContext()
{
    return stream_context_create([
        'http' => [
            'method' => 'GET',
            'timeout' => 15,
            'follow_location' => true,
            'max_redirects' => 5,
            'header' => implode("\r\n", [
                'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
                'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language: en-US,en;q=0.5',
                'Referer: https://www.themoviedb.org/',
            ]),
        ],
        'ssl' => [
            'verify_peer' => false,
            'verify_peer_name' => false,
        ],
    ]);
}

function fetchWithCurl(string $url): string|false
{
    if (!function_exists('curl_init')) return false;
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_MAXREDIRS => 5,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_USERAGENT => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        CURLOPT_HTTPHEADER => [
            'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language: en-US,en;q=0.5',
            'Referer: https://www.themoviedb.org/',
        ],
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false,
    ]);
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    return ($httpCode >= 200 && $httpCode < 400) ? $result : false;
}

$sourceIndex = isset($_GET['source']) ? (int) $_GET['source'] : 0;
$tmdbId = isset($_GET['tmdb']) ? (int) $_GET['tmdb'] : 0;
$platform = isset($_GET['platform']) ? $_GET['platform'] : 'mobile';

if ($tmdbId <= 0) {
    http_response_code(400);
    echo '<html><body><h2>Missing or invalid tmdb parameter</h2></body></html>';
    exit;
}

$sources = getStreamingSources();
$sourceIndex = min($sourceIndex, count($sources) - 1);
$source = $sources[$sourceIndex];
$embedUrl = sprintf($source['url'], $tmdbId);

// Source 1 (VidLink): redirect directly — player controls now work
if ($sourceIndex === 1) {
    header('Location: ' . $embedUrl);
    exit;
}

// Sources 2 & 3 (vidsrcme.su / vidsrcme.ru):
//   - Web (Chrome HtmlElementView): direct redirect — single iframe from Flutter avoids "Please Disable Sandbox"
//   - Mobile (InAppWebView): iframe wrapper — avoids Adscore anti-bot detection
if ($sourceIndex === 2 || $sourceIndex === 3) {
    if ($platform === 'web') {
        header('Location: ' . $embedUrl);
        exit;
    }
    $escaped = htmlspecialchars($embedUrl, ENT_QUOTES, 'UTF-8');
    echo '<!DOCTYPE html><html><head><meta name="referrer" content="no-referrer"><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{margin:0;overflow:hidden;background:#000}iframe{width:100vw;height:100vh;border:none}</style></head><body><iframe src="' . $escaped . '" allow="autoplay; encrypted-media; fullscreen" allowfullscreen></iframe></body></html>';
    exit;
}

$context = createStreamContext();
$html = @file_get_contents($embedUrl, false, $context);

if ($html === false) {
    $html = fetchWithCurl($embedUrl);
}

if ($html === false) {
    $err = error_get_last();
    $logDir = __DIR__ . '/../../logs';
    if (!is_dir($logDir)) @mkdir($logDir, 0777, true);
    @file_put_contents($logDir . '/proxy_errors.log', date('Y-m-d H:i:s') . ' | source=' . $sourceIndex . ' | tmdb=' . $tmdbId . ' | ' . ($err['message'] ?? 'unknown') . PHP_EOL, FILE_APPEND);

    // Auto-fallback to the next source in the list
    $fallbackIndex = ($sourceIndex + 1) % count($sources);
    $fallbackUrl = sprintf($sources[$fallbackIndex]['url'], $tmdbId);
    header('Location: ' . $fallbackUrl);
    exit;
}

function sanitizeProxiedHtml(string $html): string
{
    $inside = '(?:(?!</script>).)*?';

    $patterns = [
        // Remove disable-devtool script tags
        '#<script\s+disable-devtool-auto[^>]*>' . $inside . '</script>#is' => '',
        // Remove DisableDevtool() calls
        '#<script[^>]*>\s*DisableDevtool\s*\([^}]*}\s*\)\s*;?\s*</script>#is' => '',
        // Keep sojson.v4 — it uses document.write() to inject player setup code.
        // Removing it would also remove the player initialization.
        // '#<script[^>]*>' . $inside . 'sojson\.v4' . $inside . '</script>#is' => '',
        // Remove detectDevTool eval scripts
        '#<script[^>]*>' . $inside . 'detectDevTool' . $inside . '</script>#is' => '',
        // Remove referrer tracking scripts (refcheck.php)
        '#<script[^>]*>' . $inside . '(?:navigator\.sendBeacon|new\s+Image\(\)\.src)' . $inside . 'refcheck\.php' . $inside . '</script>#is' => '',
        // Remove scripts from known tracker domains
        '#<script[^>]*src=[\'"][^\'"]*flintarchedsignature\.com[^\'"]*[\'"][^>]*>' . $inside . '</script>#is' => '',
        '#<script[^>]*src=[\'"][^\'"]*cloudnestra\.com[^\'"]*[\'"][^>]*>' . $inside . '</script>#is' => '',
        // Remove standalone debugger statements
        '#\bdebugger\s*;?#i' => ';',
    ];

    foreach ($patterns as $pattern => $replacement) {
        if (str_contains($pattern, 'flintarchedsignature')) {
            if (!str_contains($html, 'flintarchedsignature')) continue;
        } elseif (str_contains($pattern, 'cloudnestra')) {
            if (!str_contains($html, 'cloudnestra')) continue;
        } elseif (str_contains($pattern, 'detectDevTool')) {
            if (!str_contains($html, 'detectDevTool')) continue;
        } elseif (str_contains($pattern, 'refcheck')) {
            if (!str_contains($html, 'refcheck.php')) continue;
        } elseif (str_contains($pattern, 'DisableDevtool')) {
            if (!str_contains($html, 'DisableDevtool')) continue;
        } elseif (str_contains($pattern, 'disable-devtool-auto')) {
            if (!str_contains($html, 'disable-devtool-auto')) continue;
        }
        $result = preg_replace($pattern, $replacement, $html);
        if (is_string($result)) $html = $result;
    }

    return $html;
}

$scheme = parse_url($embedUrl, PHP_URL_SCHEME);
$host = parse_url($embedUrl, PHP_URL_HOST);
$baseUrl = $scheme . '://' . $host . '/';
if (preg_match('/<head[^>]*>/i', $html)) {
    $html = preg_replace('/<head[^>]*>/i', '<head><base href="' . $baseUrl . '">', $html, 1);
} elseif (stripos($html, '<html') !== false) {
    $html = preg_replace('/<html[^>]*>/i', '$0><head><base href="' . $baseUrl . '"></head>', $html, 1);
} else {
    $html = '<!DOCTYPE html><html><head><base href="' . $baseUrl . '"></head><body>' . $html . '</body></html>';
}

$html = preg_replace('/\bsandbox\s*=\s*"[^"]*"\s*/i', '', $html);

// Stop browsers sending Referer, bypassing remote hotlink protection
$html = preg_replace('/<head[^>]*>/i', '$0<meta name="referrer" content="no-referrer">', $html);

// Override sandbox detection early — inject into <head> before page scripts run
$html = preg_replace(
    '/<head[^>]*>/i',
    '$0<script>window.isReallySandboxed=function(){return false;};window.checkSandbox=function(){return false;};try{Object.defineProperty(window,\'frameElement\',{get:function(){return null},configurable:true})}catch(e){};try{Object.defineProperty(window,\'parent\',{get:function(){return window},configurable:true})}catch(e){};try{Object.defineProperty(window,\'top\',{get:function(){return window},configurable:true})}catch(e){};</script>',
    $html,
    1
);

// Strip top-level redirect only
$html = preg_replace('/if\s*\(\s*window\s*={2,3}\s*window\.top\s*\)\s*\{[^}]*window\.location[^}]*\}/i', 'if (false) {}', $html);
$html = preg_replace('/if\s*\(\s*window\s*==\s*window\.top\s*\)\s*\{[^}]*window\.location[^}]*\}/i', 'if (false) {}', $html);

$html = sanitizeProxiedHtml($html);

// Fix protocol-relative iframe URLs (resolve //... to https://...)
// When served over HTTP, // resolves to http:// which some servers reject
$html = preg_replace_callback(
    '/\b(src|data-src)\s*=\s*["\']\/\/([^"\']+)["\']/i',
    function ($m) { return $m[1] . '="https://' . $m[2] . '"'; },
    $html
);

echo $html;
