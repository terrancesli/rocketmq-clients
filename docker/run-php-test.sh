#!/bin/bash
set -e
echo "=== PHP RocketMQ Client Test ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINT}"

cd /app/examples

run_test() {
    local name=$1
    local script=$2
    echo "--- Running: $name ---"
    php "$script" || echo "FAILED: $name"
    echo "--- Done: $name ---"
}

case "${TEST_TYPE:-all}" in
    normal)    run_test "Producer" "Producer.php" ;;
    all)       run_test "Producer" "Producer.php" ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== PHP tests complete ==="
