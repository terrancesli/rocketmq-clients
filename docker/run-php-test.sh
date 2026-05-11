#!/bin/bash
set -e
echo "=== PHP RocketMQ Client Test (WIP) ==="
echo "Endpoint: ${ROCKETMQ_ENDPOINT}"

case "${TEST_TYPE:-all}" in
    normal)
        echo "--- Running: PHP Producer ---"
        php /app/examples/Producer.php || echo "FAILED: PHP Producer"
        ;;
    all)
        echo "--- Running: PHP Producer ---"
        php /app/examples/Producer.php || echo "FAILED: PHP Producer"
        ;;
    *) echo "Unknown TEST_TYPE: $TEST_TYPE" ;;
esac

echo "=== PHP tests complete (WIP) ==="
