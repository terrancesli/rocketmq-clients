#!/bin/bash
set -e
echo "=== C# (.NET) RocketMQ Client Test ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINT}"

cd /app/bin

run_test() {
    local name=$1
    local dll=$2
    echo "--- Running: $name ---"
    dotnet "$dll" || echo "FAILED: $name"
    echo "--- Done: $name ---"
}

case "${TEST_TYPE:-all}" in
    normal)    run_test "Normal Producer"   "examples.dll" ;;
    fifo)      run_test "FIFO Producer"     "examples.dll" ;;
    delay)     run_test "Delay Producer"    "examples.dll" ;;
    transaction) run_test "Transaction Producer" "examples.dll" ;;
    push)      run_test "Push Consumer"     "examples.dll" ;;
    simple)    run_test "Simple Consumer"   "examples.dll" ;;
    all)
        run_test "Normal Producer"   "examples.dll"
        run_test "FIFO Producer"     "examples.dll"
        run_test "Delay Producer"    "examples.dll"
        run_test "Transaction Producer" "examples.dll"
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== C# tests complete ==="
