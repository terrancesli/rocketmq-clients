/*
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

package org.apache.rocketmq.client.java.example;

import org.apache.rocketmq.client.apis.ClientConfiguration;
import org.apache.rocketmq.client.apis.ClientException;
import org.apache.rocketmq.client.apis.ClientServiceProvider;
import org.apache.rocketmq.client.apis.SessionCredentialsProvider;
import org.apache.rocketmq.client.apis.StaticSessionCredentialsProvider;
import org.apache.rocketmq.client.apis.producer.Producer;
import org.apache.rocketmq.client.apis.producer.ProducerBuilder;
import org.apache.rocketmq.client.apis.producer.TransactionChecker;

/**
 * Each client will establish an independent connection to the server node within a process.
 *
 * <p>In most cases, the singleton mode can meet the requirements of higher concurrency.
 * If multiple connections are desired, consider increasing the number of clients appropriately.
 */
public class ProducerSingleton {
    private static volatile Producer PRODUCER;
    private static volatile Producer TRANSACTIONAL_PRODUCER;
    private static final String ACCESS_KEY = System.getenv("ROCKETMQ_ACCESS_KEY");
    private static final String SECRET_KEY = System.getenv("ROCKETMQ_SECRET_KEY");
    private static final String ENDPOINTS = System.getenv("ROCKETMQ_ENDPOINT");

    private ProducerSingleton() {
    }

    private static Producer buildProducer(TransactionChecker checker, String... topics) throws ClientException {
        final ClientServiceProvider provider = ClientServiceProvider.loadService();
        ClientConfiguration clientConfiguration;
        if (!ACCESS_KEY.isEmpty() && !SECRET_KEY.isEmpty()) {
            SessionCredentialsProvider sessionCredentialsProvider =
                new StaticSessionCredentialsProvider(ACCESS_KEY, SECRET_KEY);
            clientConfiguration = ClientConfiguration.newBuilder()
                .setEndpoints(ENDPOINTS)
                .setCredentialProvider(sessionCredentialsProvider)
                .build();
        } else {
            clientConfiguration = ClientConfiguration.newBuilder()
                .setEndpoints(ENDPOINTS)
                .build();
        }
        final ProducerBuilder builder = provider.newProducerBuilder()
            .setClientConfiguration(clientConfiguration)
            .setTopics(topics);
        if (checker != null) {
            builder.setTransactionChecker(checker);
        }
        return builder.build();
    }

    public static Producer getInstance(String... topics) throws ClientException {
        if (null == PRODUCER) {
            synchronized (ProducerSingleton.class) {
                if (null == PRODUCER) {
                    PRODUCER = buildProducer(null, topics);
                }
            }
        }
        return PRODUCER;
    }

    public static Producer getTransactionalInstance(TransactionChecker checker,
        String... topics) throws ClientException {
        if (null == TRANSACTIONAL_PRODUCER) {
            synchronized (ProducerSingleton.class) {
                if (null == TRANSACTIONAL_PRODUCER) {
                    TRANSACTIONAL_PRODUCER = buildProducer(checker, topics);
                }
            }
        }
        return TRANSACTIONAL_PRODUCER;
    }
}
