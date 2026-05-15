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
    normal)    run_test "Normal Producer"   /app/bin/example_producer "NormalTest" ;;
    fifo)      run_test "FIFO Producer"     /app/bin/example_fifo_producer "OrderTest" ;;
    delay)     run_test "Delay Producer"    /app/bin/example_producer_with_timed_message "TimerTest" ;;
    transaction) run_test "Transaction Producer" /app/bin/example_producer_with_transactional_message "TransTest" ;;
    push)      run_test "Push Consumer"     /app/bin/example_push_consumer "NormalTest" ;;
    simple)    run_test "Simple Consumer"   /app/bin/example_simple_consumer "NormalTest" ;;
    all)
        run_test "Normal Producer"   /app/bin/example_producer "NormalTest"
        run_test "FIFO Producer"     /app/bin/example_fifo_producer "OrderTest"
        run_test "Delay Producer"    /app/bin/example_producer_with_timed_message "TimerTest"
        run_test "Transaction Producer" /app/bin/example_producer_with_transactional_message "TransTest"
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== C++ tests complete ==="
