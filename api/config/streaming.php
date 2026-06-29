<?php

function getStreamingSources(): array {
    return [
        ['name' => 'API Player',          'url' => 'https://apiplayer.ru/embed/movie/%d'],    // unreliable host
        ['name' => 'VidLink',             'url' => 'https://vidlink.pro/movie/%d'],
        ['name' => 'vidsrcme.su',         'url' => 'https://vidsrcme.su/embed/movie/%d'],
        ['name' => 'vidsrcme.ru',          'url' => 'https://vidsrcme.ru/embed/movie/%d'],
    ];
}
