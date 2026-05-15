<?php
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.
 */

namespace Apache\Rocketmq;

require 'vendor/autoload.php';

use Apache\Rocketmq\V2\Message;
use Apache\Rocketmq\V2\MessageQueue;
use Apache\Rocketmq\V2\MessagingServiceClient;
use Apache\Rocketmq\V2\QueryRouteRequest;
use Apache\Rocketmq\V2\Resource;
use Apache\Rocketmq\V2\SendResultEntry;
use Apache\Rocketmq\V2\SendMessageRequest;
use Apache\Rocketmq\V2\SystemProperties;
use Grpc\Channel;
use Grpc\ChannelCredentials;
use Grpc\Call;
use Grpc\Timeval;

class Producer
{
    private $channel;
    private $clientId;
    private $endpoint;
    private $accessKey;
    private $secretKey;

    public function init()
    {
        $this->clientId = 'php-client@' . posix_getpid() . '@0@' . $this->getRandStr(10);
        $this->endpoint = getenv('ROCKETMQ_ENDPOINT') ?: '127.0.0.1:8080';
        // gRPC needs the endpoint in dns:/// format for proper resolution
        $grpcEndpoint = 'dns:///' . $this->endpoint;
        $this->accessKey = getenv('ROCKETMQ_ACCESS_KEY') ?: '';
        $this->secretKey = getenv('ROCKETMQ_SECRET_KEY') ?: '';

        echo "Endpoint: {$this->endpoint}, ClientId: {$this->clientId}\n";

        $this->channel = new Channel($this->endpoint, [
            'credentials' => ChannelCredentials::createInsecure(),
        ]);

        // Query route first
        $topic = 'NormalTest';
        $route = $this->queryRoute($topic);
        echo "Route query result: code=" . ($route ? $route->status->code : 'null') . "\n";

        // Send a message
        $this->sendMessage($topic, 'Hello from PHP RocketMQ!');

        $this->channel->close();
    }

    private function queryRoute($topic)
    {
        $method = "/apache.rocketmq.v2.MessagingService/QueryRoute";
        $qr = new QueryRouteRequest();
        $rs = new Resource();
        $rs->setResourceNamespace('');
        $rs->setName($topic);
        $qr->setTopic($rs);

        $serialized = $qr->serializeToString();
        $deadline = new Timeval(10000000);
        $call = new Call($this->channel, $method, $deadline, null);
        $metadata = [];
        if ($this->accessKey && $this->secretKey) {
            $metadata['authorization'] = [$this->accessKey . ':' . $this->secretKey];
        }
        $result = $call->startBatch([
            \Grpc\OP_SEND_INITIAL_METADATA => $metadata,
            \Grpc\OP_SEND_MESSAGE => ["message" => $serialized],
            \Grpc\OP_SEND_CLOSE_FROM_CLIENT => true,
            \Grpc\OP_RECV_INITIAL_METADATA => true,
            \Grpc\OP_RECV_MESSAGE => true,
            \Grpc\OP_RECV_STATUS_ON_CLIENT => true,
        ]);

        if ($result->status->code === 0 && isset($result->message)) {
            $response = new \Apache\Rocketmq\V2\QueryRouteResponse();
            $response->mergeFromString($result->message);
            return $response;
        }
        echo "QueryRoute failed: code={$result->status->code}, details={$result->status->details}\n";
        return null;
    }

    private function sendMessage($topic, $body)
    {
        $method = "/apache.rocketmq.v2.MessagingService/SendMessage";
        $msg = new Message();
        $resource = new Resource();
        $resource->setName($topic);
        $resource->setResourceNamespace('');
        $msg->setTopic($resource);

        $sysProps = new SystemProperties();
        $msg->setSystemProperties($sysProps);

        $msg->setBody($body);

        $req = new SendMessageRequest();
        $req->setMessages([$msg]);

        $serialized = $req->serializeToString();
        $deadline = new Timeval(10000000);
        $call = new Call($this->channel, $method, $deadline, null);
        $metadata = [];
        if ($this->accessKey && $this->secretKey) {
            $metadata['authorization'] = [$this->accessKey . ':' . $this->secretKey];
        }
        $result = $call->startBatch([
            \Grpc\OP_SEND_INITIAL_METADATA => $metadata,
            \Grpc\OP_SEND_MESSAGE => ["message" => $serialized],
            \Grpc\OP_SEND_CLOSE_FROM_CLIENT => true,
            \Grpc\OP_RECV_INITIAL_METADATA => true,
            \Grpc\OP_RECV_MESSAGE => true,
            \Grpc\OP_RECV_STATUS_ON_CLIENT => true,
        ]);

        if ($result->status->code === 0) {
            $response = new \Apache\Rocketmq\V2\SendMessageResponse();
            $response->mergeFromString($result->message);
            echo "Message sent successfully\n";
        } else {
            echo "SendMessage failed: code={$result->status->code}, details={$result->status->details}\n";
        }
    }

    public function getRandStr($length)
    {
        $str = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        $len = strlen($str) - 1;
        $randstr = '';
        for ($i = 0; $i < $length; $i++) {
            $num = mt_rand(0, $len);
            $randstr .= $str[$num];
        }
        return $randstr;
    }
}

$producer = new Producer();
$producer->init();
