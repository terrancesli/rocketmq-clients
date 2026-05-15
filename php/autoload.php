<?php
/**
 * Manual PSR-4 autoload for RocketMQ PHP client.
 * Handles: Apache\Rocketmq\V2\*, GPBMetadata\*, Grpc\*
 */
spl_autoload_register(function ($class) {
    // Grpc stubs are in the same vendor directory
    if (strpos($class, 'Grpc\\') === 0) {
        $relativeClass = str_replace('\\', '/', substr($class, 5));
        $file = __DIR__ . '/grpc/Grpc/' . $relativeClass . '.php';
        if (file_exists($file)) { require $file; return; }
    }

    // Project proto classes - look relative to vendor dir
    $projectPrefixes = [
        'GPBMetadata\\' => '../grpc/GPBMetadata/',
        'Apache\\Rocketmq\\V2\\' => '../grpc/Apache/Rocketmq/V2/',
    ];

    foreach ($projectPrefixes as $prefix => $baseDir) {
        if (strpos($class, $prefix) === 0) {
            $relativeClass = str_replace('\\', '/', substr($class, strlen($prefix)));
            $file = __DIR__ . '/' . $baseDir . $relativeClass . '.php';
            if (file_exists($file)) { require $file; return; }
        }
    }
});
