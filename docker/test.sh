#!/bin/bash
# ============================================
# RocketMQ 多语言客户端测试集编排脚本
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LANGUAGES=("java" "golang" "rust" "python" "nodejs" "csharp" "cpp" "php")

usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  setup              Copy .env.example to .env"
    echo "  build [lang...]    Build Docker images for specified languages (or all)"
    echo "  test [lang...]     Run tests for specified languages (or all)"
    echo "  run [lang...]      Build + run tests for specified languages sequentially"
    echo "  run-parallel       Build + run all languages in parallel"
    echo "  list               List available languages"
    echo "  clean              Remove all Docker images and build cache"
    echo ""
    echo "Examples:"
    echo "  $0 build java golang           # Build only Java and Go"
    echo "  $0 test java                   # Run only Java tests"
    echo "  $0 run java golang rust         # Build + run Java, Go, Rust sequentially"
    echo "  $0 run-parallel                 # Build + run all languages in parallel"
    echo "  TEST_TYPE=normal $0 test java  # Run only normal message test for Java"
    echo ""
    echo "Environment:"
    echo "  TEST_TYPE        Test type: all(默认), normal, fifo, delay, transaction, push, simple"
    echo "  ROCKETMQ_ENDPOINT     RocketMQ endpoint"
    echo "  ROCKETMQ_ACCESS_KEY   Access key"
    echo "  ROCKETMQ_SECRET_KEY   Secret key"
    exit 1
}

check_env() {
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        echo -e "${YELLOW}Warning: .env not found. Copying from .env.example...${NC}"
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        echo -e "${YELLOW}Please edit $SCRIPT_DIR/.env and set your RocketMQ credentials.${NC}"
        echo -e "${YELLOW}Continuing with empty values (will fail if ACL is enabled).${NC}"
    fi
    # Load env
    set -a
    source "$SCRIPT_DIR/.env" 2>/dev/null || true
    set +a
}

do_build() {
    check_env
    local langs=("$@")
    if [ ${#langs[@]} -eq 0 ]; then
        langs=("${LANGUAGES[@]}")
    fi

    for lang in "${langs[@]}"; do
        if [[ ! " ${LANGUAGES[*]} " =~ " ${lang} " ]]; then
            echo -e "${RED}Unknown language: $lang${NC}"
            continue
        fi
        echo -e "${BLUE}Building $lang...${NC}"
        docker compose build "$lang"
        echo -e "${GREEN}$lang build complete.${NC}"
    done
}

do_test() {
    check_env
    local langs=("$@")
    if [ ${#langs[@]} -eq 0 ]; then
        langs=("${LANGUAGES[@]}")
    fi

    for lang in "${langs[@]}"; do
        if [[ ! " ${LANGUAGES[*]} " =~ " ${lang} " ]]; then
            echo -e "${RED}Unknown language: $lang${NC}"
            continue
        fi
        echo -e "${BLUE}Testing $lang (TEST_TYPE=${TEST_TYPE:-all})...${NC}"
        docker compose up --no-deps "$lang" 2>&1 || echo -e "${RED}$lang test failed (exit code: $?)${NC}"
        echo -e "${GREEN}$lang test complete.${NC}"
        echo ""
    done
}

do_run() {
    check_env
    local langs=("$@")
    if [ ${#langs[@]} -eq 0 ]; then
        langs=("${LANGUAGES[@]}")
    fi

    for lang in "${langs[@]}"; do
        if [[ ! " ${LANGUAGES[*]} " =~ " ${lang} " ]]; then
            echo -e "${RED}Unknown language: $lang${NC}"
            continue
        fi
        echo -e "${BLUE}Building and testing $lang...${NC}"
        docker compose up --build --no-deps "$lang" 2>&1 || echo -e "${RED}$lang failed (exit code: $?)${NC}"
        echo -e "${GREEN}$lang complete.${NC}"
        echo ""
    done
}

do_run_parallel() {
    check_env
    echo -e "${BLUE}Building and testing all languages in parallel...${NC}"
    docker compose up --build
}

do_clean() {
    echo -e "${YELLOW}Removing all Docker images and build cache...${NC}"
    docker compose down --rmi all --remove-orphans 2>/dev/null || true
    docker compose build --no-cache 2>/dev/null || true
}

do_list() {
    echo "Available languages:"
    for lang in "${LANGUAGES[@]}"; do
        echo "  - $lang"
    done
}

# Main
case "${1:-}" in
    setup)
        if [ -f "$SCRIPT_DIR/.env" ]; then
            echo -e "${YELLOW}.env already exists. To reset:${NC}"
            echo "  cp .env.example .env"
        else
            cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
            echo -e "${GREEN}Created .env from .env.example. Edit it with your credentials.${NC}"
        fi
        ;;
    build)
        shift
        do_build "$@"
        ;;
    test)
        shift
        do_test "$@"
        ;;
    run)
        shift
        do_run "$@"
        ;;
    run-parallel)
        do_run_parallel
        ;;
    list)
        do_list
        ;;
    clean)
        do_clean
        ;;
    *)
        usage
        ;;
esac
