#!/bin/sh
set -e
echo "=== Go RocketMQ Client Test ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINT}"

run_test() {
    local name=$1
    local bin=$2
    echo "--- Running: $name ---"
    $bin || echo "FAILED: $name"
    echo "--- Done: $name ---"
}

case "${TEST_TYPE:-all}" in
    normal)    run_test "Normal Producer"   /bin/producer_normal ;;
    fifo)      run_test "FIFO Producer"     /bin/producer_fifo ;;
    delay)     run_test "Delay Producer"    /bin/producer_delay ;;
    transaction) run_test "Transaction Producer" /bin/producer_transaction ;;
    push)      run_test "Push Consumer"     /bin/consumer_push ;;
    simple)    run_test "Simple Consumer"   /bin/consumer_simple ;;
    all)
        run_test "Normal Producer"   /bin/producer_normal
        run_test "FIFO Producer"     /bin/producer_fifo
        run_test "Delay Producer"    /bin/producer_delay
        run_test "Transaction Producer" /bin/producer_transaction
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== Go tests complete ==="
