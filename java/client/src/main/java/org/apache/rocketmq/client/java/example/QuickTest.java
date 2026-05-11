package org.apache.rocketmq.client.java.example;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import org.apache.rocketmq.client.apis.ClientConfiguration;
import org.apache.rocketmq.client.apis.ClientException;
import org.apache.rocketmq.client.apis.ClientServiceProvider;
import org.apache.rocketmq.client.apis.SessionCredentialsProvider;
import org.apache.rocketmq.client.apis.StaticSessionCredentialsProvider;
import org.apache.rocketmq.client.apis.message.Message;
import org.apache.rocketmq.client.apis.producer.Producer;
import org.apache.rocketmq.client.apis.producer.SendReceipt;
import org.apache.rocketmq.client.apis.producer.Transaction;
import org.apache.rocketmq.client.apis.producer.TransactionChecker;
import org.apache.rocketmq.client.apis.producer.TransactionResolution;

public class QuickTest {

    private static final String ACCESS_KEY = "Mhbct2T68T0zsbC3";
    private static final String SECRET_KEY = "qxi3NLwMMy7sL431";
    private static final String ENDPOINTS = "rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080";

    private static final String TOPIC_NORMAL = "NormalTest";
    private static final String TOPIC_FIFO = "OrderTest";
    private static final String TOPIC_DELAY = "TimerTest";
    private static final String TOPIC_TRANSACTION = "TransTest";

    private static final ClientServiceProvider provider = ClientServiceProvider.loadService();

    private static ClientConfiguration buildConfig() {
        SessionCredentialsProvider credentials =
            new StaticSessionCredentialsProvider(ACCESS_KEY, SECRET_KEY);
        return ClientConfiguration.newBuilder()
            .setEndpoints(ENDPOINTS)
            .setCredentialProvider(credentials)
            .build();
    }

    // ---- Normal ----

    private static void testNormal() throws ClientException {
        System.out.println("=== [1/4] Normal Producer ===");
        ClientConfiguration config = buildConfig();
        Producer producer = provider.newProducerBuilder()
            .setClientConfiguration(config)
            .setTopics(TOPIC_NORMAL)
            .build();

        byte[] body = "Java Normal Message Test".getBytes(StandardCharsets.UTF_8);
        Message msg = provider.newMessageBuilder()
            .setTopic(TOPIC_NORMAL)
            .setBody(body)
            .setKeys("java-normal-" + System.currentTimeMillis())
            .build();

        SendReceipt receipt = producer.send(msg);
        System.out.println("[OK] Normal: " + receipt.getMessageId());
        try { producer.close(); } catch (IOException e) {}
    }

    // ---- FIFO (Order) ----

    private static void testFifo() throws ClientException {
        System.out.println("=== [2/4] FIFO/Order Producer ===");
        ClientConfiguration config = buildConfig();
        Producer producer = provider.newProducerBuilder()
            .setClientConfiguration(config)
            .setTopics(TOPIC_FIFO)
            .build();

        byte[] body = "Java FIFO Message Test".getBytes(StandardCharsets.UTF_8);
        Message msg = provider.newMessageBuilder()
            .setTopic(TOPIC_FIFO)
            .setBody(body)
            .setKeys("java-fifo-" + System.currentTimeMillis())
            .setMessageGroup("group-0")
            .build();

        SendReceipt receipt = producer.send(msg);
        System.out.println("[OK] FIFO: " + receipt.getMessageId());
        try { producer.close(); } catch (IOException e) {}
    }

    // ---- Delay/Timed ----

    private static void testDelay() throws ClientException {
        System.out.println("=== [3/4] Delay/Timed Producer ===");
        ClientConfiguration config = buildConfig();
        Producer producer = provider.newProducerBuilder()
            .setClientConfiguration(config)
            .setTopics(TOPIC_DELAY)
            .build();

        byte[] body = "Java Delay Message Test".getBytes(StandardCharsets.UTF_8);
        long deliveryTimestamp = System.currentTimeMillis() + Duration.ofMinutes(1).toMillis();
        Message msg = provider.newMessageBuilder()
            .setTopic(TOPIC_DELAY)
            .setBody(body)
            .setKeys("java-delay-" + System.currentTimeMillis())
            .setDeliveryTimestamp(deliveryTimestamp)
            .build();

        SendReceipt receipt = producer.send(msg);
        System.out.println("[OK] Delay: " + receipt.getMessageId());
        try { producer.close(); } catch (IOException e) {}
    }

    // ---- Transaction ----

    private static void testTransaction() throws ClientException {
        System.out.println("=== [4/4] Transaction Producer ===");
        ClientConfiguration config = buildConfig();
        TransactionChecker checker = messageView -> {
            System.out.println("[TX] Checker called for message: " + messageView.getMessageId());
            return TransactionResolution.COMMIT;
        };

        Producer producer = provider.newProducerBuilder()
            .setClientConfiguration(config)
            .setTopics(TOPIC_TRANSACTION)
            .setTransactionChecker(checker)
            .build();

        byte[] body = "Java Transaction Message Test".getBytes(StandardCharsets.UTF_8);
        Message msg = provider.newMessageBuilder()
            .setTopic(TOPIC_TRANSACTION)
            .setBody(body)
            .setKeys("java-tx-" + System.currentTimeMillis())
            .build();

        Transaction tx = producer.beginTransaction();
        SendReceipt receipt = producer.send(msg, tx);
        System.out.println("[OK] Transaction (sent): " + receipt.getMessageId());
        tx.commit();
        System.out.println("[OK] Transaction committed");
        try { producer.close(); } catch (IOException e) {}
    }

    // ---- Main ----

    public static void main(String[] args) throws ClientException, IOException {
        System.out.println("========== Java All Producer Types Test ==========");
        System.out.println("Endpoints: " + ENDPOINTS);

        int passed = 0, failed = 0;

        String[] tests = {"normal", "fifo", "delay", "transaction"};
        if (args.length > 0) {
            tests = args;
        }

        for (String t : tests) {
            try {
                switch (t.toLowerCase()) {
                    case "normal":
                        testNormal();
                        break;
                    case "fifo":
                        testFifo();
                        break;
                    case "delay":
                        testDelay();
                        break;
                    case "transaction":
                        testTransaction();
                        break;
                    case "all":
                        testNormal();
                        testFifo();
                        testDelay();
                        testTransaction();
                        break;
                    default:
                        System.out.println("[WARN] Unknown test: " + t);
                }
                passed++;
            } catch (Throwable e) {
                failed++;
                System.out.println("[FAIL] " + t + ": " + e.getClass().getSimpleName() + " - " + e.getMessage());
            }
        }

        System.out.println("========== Summary: " + passed + " passed, " + failed + " failed ==========");
    }
}
