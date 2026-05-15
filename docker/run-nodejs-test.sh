#!/bin/sh
set -e
echo "=== Node.js RocketMQ Client Test ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINT}"

cd /app/nodejs

run_test() {
    local name=$1
    local script=$2
    echo "--- Running: $name ---"
    npx ts-node examples/"$script" || echo "FAILED: $name"
    echo "--- Done: $name ---"
}

case "${TEST_TYPE:-all}" in
    normal)    run_test "Normal Producer"   "ProducerNormalMessageExample.ts" ;;
    fifo)      run_test "FIFO Producer"     "ProducerFifoMessageExample.ts" ;;
    delay)     run_test "Delay Producer"    "ProducerDelayMessageExample.ts" ;;
    transaction) run_test "Transaction Producer" "ProducerTransactionMessageExample.ts" ;;
    push)      run_test "Push Consumer"     "PushConsumer.ts" ;;
    simple)    run_test "Simple Consumer"   "SimpleConsumer.ts" ;;
    all)
        run_test "Normal Producer"   "ProducerNormalMessageExample.ts"
        run_test "FIFO Producer"     "ProducerFifoMessageExample.ts"
        run_test "Delay Producer"    "ProducerDelayMessageExample.ts"
        run_test "Transaction Producer" "ProducerTransactionMessageExample.ts"
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== Node.js tests complete ==="
