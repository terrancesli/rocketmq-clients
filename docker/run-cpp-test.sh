#!/bin/bash
set -e
echo "=== C++ RocketMQ Client Test ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINT}"

ENDPOINT="${ROCKETMQ_ENDPOINT}"
AK="${ROCKETMQ_ACCESS_KEY}"
SK="${ROCKETMQ_SECRET_KEY}"

run_test() {
    local name=$1
    local bin=$2
    local topic=$3
    echo "--- Running: $name ---"
    "$bin" \
        --access_point="$ENDPOINT" \
        --topic="$topic" \
        --access_key="$AK" \
        --access_secret="$SK" || echo "FAILED: $name"
    echo "--- Done: $name ---"
}

case "${TEST_TYPE:-all}" in
    normal)    run_test "Normal Producer"   /app/bin/ExampleProducer "NormalTest" ;;
    fifo)      run_test "FIFO Producer"     /app/bin/ExampleFifoProducer "OrderTest" ;;
    delay)     run_test "Delay Producer"    /app/bin/ExampleProducerWithTimedMessage "TimerTest" ;;
    transaction) run_test "Transaction Producer" /app/bin/ExampleProducerWithTransactionalMessage "TransTest" ;;
    push)      run_test "Push Consumer"     /app/bin/ExamplePushConsumer "NormalTest" ;;
    simple)    run_test "Simple Consumer"   /app/bin/ExampleSimpleConsumer "NormalTest" ;;
    all)
        run_test "Normal Producer"   /app/bin/ExampleProducer "NormalTest"
        run_test "FIFO Producer"     /app/bin/ExampleFifoProducer "OrderTest"
        run_test "Delay Producer"    /app/bin/ExampleProducerWithTimedMessage "TimerTest"
        run_test "Transaction Producer" /app/bin/ExampleProducerWithTransactionalMessage "TransTest"
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== C++ tests complete ==="
