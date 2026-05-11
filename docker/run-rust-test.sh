#!/bin/sh
set -e
echo "=== Rust RocketMQ Client Test ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINTS}"

run_test() {
    local name=$1
    local bin=$2
    echo "--- Running: $name ---"
    $bin || echo "FAILED: $name"
    echo "--- Done: $name ---"
}

case "${TEST_TYPE:-all}" in
    normal)    run_test "Normal Producer"   /bin/producer ;;
    fifo)      run_test "FIFO Producer"     /bin/fifo_producer ;;
    delay)     run_test "Delay Producer"    /bin/delay_producer ;;
    transaction) run_test "Transaction Producer" /bin/transaction_producer ;;
    push)      run_test "Push Consumer"     /bin/push_consumer ;;
    simple)    run_test "Simple Consumer"   /bin/simple_consumer ;;
    all)
        run_test "Normal Producer"   /bin/producer
        run_test "FIFO Producer"     /bin/fifo_producer
        run_test "Delay Producer"    /bin/delay_producer
        run_test "Transaction Producer" /bin/transaction_producer
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== Rust tests complete ==="
