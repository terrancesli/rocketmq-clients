#!/bin/bash
set -e
echo "=== Python RocketMQ Client Test ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINTS}"

run_test() {
    local name=$1
    local script=$2
    echo "--- Running: $name ---"
    python3 /app/examples/"$script" || echo "FAILED: $name"
    echo "--- Done: $name ---"
}

case "${TEST_TYPE:-all}" in
    normal)    run_test "Normal Producer"   "normal_producer_example.py" ;;
    fifo)      run_test "FIFO Producer"     "fifo_producer_example.py" ;;
    delay)     run_test "Delay Producer"    "delay_producer_example.py" ;;
    transaction) run_test "Transaction Producer" "transaction_producer_example.py" ;;
    push)      run_test "Push Consumer"     "push_consumer_example.py" ;;
    simple)    run_test "Simple Consumer"   "simple_consumer_example.py" ;;
    all)
        run_test "Normal Producer"   "normal_producer_example.py"
        run_test "FIFO Producer"     "fifo_producer_example.py"
        run_test "Delay Producer"    "delay_producer_example.py"
        run_test "Transaction Producer" "transaction_producer_example.py"
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== Python tests complete ==="
