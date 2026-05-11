#!/bin/bash
set -e
echo "=== Java RocketMQ Client Test ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINTS}"

CLASSPATH="/app/classes:/app/lib/*"

run_test() {
    local name=$1
    local class=$2
    echo "--- Running: $name ---"
    java -cp "$CLASSPATH:/app/examples" -Dfile.encoding=UTF-8 "$class" || echo "FAILED: $name"
    echo "--- Done: $name ---"
}

case "${TEST_TYPE:-all}" in
    normal)    run_test "Normal Producer"   "org.apache.rocketmq.client.java.example.ProducerNormalMessageExample" ;;
    fifo)      run_test "FIFO Producer"     "org.apache.rocketmq.client.java.example.ProducerFifoMessageExample" ;;
    delay)     run_test "Delay Producer"    "org.apache.rocketmq.client.java.example.ProducerDelayMessageExample" ;;
    transaction) run_test "Transaction Producer" "org.apache.rocketmq.client.java.example.ProducerTransactionMessageExample" ;;
    push)      run_test "Push Consumer"     "org.apache.rocketmq.client.java.example.PushConsumerExample" ;;
    simple)    run_test "Simple Consumer"   "org.apache.rocketmq.client.java.example.SimpleConsumerExample" ;;
    all)
        run_test "Normal Producer"   "org.apache.rocketmq.client.java.example.ProducerNormalMessageExample"
        run_test "FIFO Producer"     "org.apache.rocketmq.client.java.example.ProducerFifoMessageExample"
        run_test "Delay Producer"    "org.apache.rocketmq.client.java.example.ProducerDelayMessageExample"
        run_test "Transaction Producer" "org.apache.rocketmq.client.java.example.ProducerTransactionMessageExample"
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== Java tests complete ==="
