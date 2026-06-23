<?php

function getStreamingSources(): array {
    return [
        ['name' => 'API Player',          'url' => 'https://apiplayer.ru/embed/movie/%d'],
        ['name' => 'VidLink',             'url' => 'https://vidlink.pro/movie/%d'],
    ];
}
