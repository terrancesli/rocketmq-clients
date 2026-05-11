<?php
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

namespace Apache\Rocketmq;

require 'vendor/autoload.php';


use Apache\Rocketmq\V2\MessageQueue;
use Apache\Rocketmq\V2\MessagingServiceClient;
use Apache\Rocketmq\V2\QueryRouteRequest;
use Apache\Rocketmq\V2\ReceiveMessageRequest;
use Apache\Rocketmq\V2\Resource;
use Grpc\ChannelCredentials;
use const Grpc\STATUS_OK;

class Producer
{

    public function init()
    {
        $clientId = 'missyourlove' . '@' . posix_getpid() . '@' . rand(0, 10) . '@' . $this->getRandStr(10);
        $endpoint = getenv('ROCKETMQ_ENDPOINTS') ?: '127.0.0.1:8080';
        $accessKey = getenv('ROCKETMQ_ACCESS_KEY') ?: '';
        $secretKey = getenv('ROCKETMQ_SECRET_KEY') ?: '';
        $client = new MessagingServiceClient($endpoint, [
            'credentials' => ChannelCredentials::createInsecure(),
            'update_metadata' => function ($metaData) use ($clientId, $accessKey, $secretKey) {
                if ($accessKey && $secretKey) {
                    $metaData['authorization'] = $accessKey . ':' . $secretKey;
                }
                $metaData['headers'] = ['clientID' => $clientId];
                return $metaData;
            }
        ]);

        $qr = new QueryRouteRequest();
        $rs = new Resource();
        $rs->setResourceNamespace('');
        $rs->setName('NormalTest');
        $qr->setTopic($rs);
        $status = $client->QueryRoute($qr)->wait();
        var_dump($status);
    }

    public function getRandStr($length){
        //Character combinations
        $str = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        $len = strlen($str)-1;
        $randstr = '';
        for ($i=0;$i<$length;$i++) {
            $num=mt_rand(0,$len);
            $randstr .= $str[$num];
        }
        return $randstr;
    }
}

$xx = new Producer();
$xx->init();
