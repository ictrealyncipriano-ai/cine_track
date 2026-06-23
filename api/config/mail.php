<?php

require_once __DIR__ . '/env.php';
require_once __DIR__ . '/../vendor/phpmailer/PHPMailer.php';
require_once __DIR__ . '/../vendor/phpmailer/SMTP.php';
require_once __DIR__ . '/../vendor/phpmailer/Exception.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

function getMailer(): PHPMailer {
    loadEnv();

    $mail = new PHPMailer(true);

    $mail->isSMTP();
    $mail->Host       = getenv('MAIL_HOST') ?: 'smtp.gmail.com';
    $mail->SMTPAuth   = true;
    $mail->Username   = getenv('MAIL_USERNAME') ?: '';
    $mail->Password   = getenv('MAIL_PASSWORD') ?: '';
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = (int)(getenv('MAIL_PORT') ?: 587);

    $fromAddress = getenv('MAIL_FROM_ADDRESS') ?: $mail->Username;
    $fromName    = getenv('MAIL_FROM_NAME') ?: 'CineTrack';
    $mail->setFrom($fromAddress, $fromName);

    $mail->CharSet = 'UTF-8';

    return $mail;
}
