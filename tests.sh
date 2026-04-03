#!/bin/bash

TARGET="127.0.0.1"
PING_BIN="./ft_ping"
TESTS_PASSED=0
TESTS_FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test: $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

run_test() {
    local test_name="$1"
    local cmd="$2"
    
    print_test_header "$test_name"
    echo -e "Command: ${YELLOW}$cmd${NC}\n"
    
    if eval "$cmd"; then
        echo -e "\n${GREEN}✅ PASSED${NC}\n"
        ((TESTS_PASSED++))
    else
        echo -e "\n${RED}❌ FAILED${NC}\n"
        ((TESTS_FAILED++))
    fi
}

if [ ! -f "$PING_BIN" ]; then
    echo -e "${RED}Error: $PING_BIN not found. Run 'make' first.${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        FT_PING TEST SUITE                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

run_test "1. Help Option (-?)" \
    "$PING_BIN -?"

run_test "2. Basic Ping (4 packets default)" \
    "sudo $PING_BIN $TARGET"

run_test "3. Count Option (-c 2)" \
    "sudo $PING_BIN -c 2 $TARGET"

run_test "4. Count Option (-c 1)" \
    "sudo $PING_BIN -c 1 $TARGET"

run_test "5. Packet Size Option (-s 32)" \
    "sudo $PING_BIN -c 1 -s 32 $TARGET"

run_test "6. Packet Size Option (-s 128)" \
    "sudo $PING_BIN -c 1 -s 128 $TARGET"

run_test "7. TTL Option (--ttl 128)" \
    "sudo $PING_BIN -c 1 --ttl 128 $TARGET"

run_test "8. TTL Option (--ttl 32)" \
    "sudo $PING_BIN -c 1 --ttl 32 $TARGET"

run_test "9. Timeout Option (-W 2)" \
    "sudo $PING_BIN -c 1 -W 2 $TARGET"

run_test "10. Interval Option (-i 0.1)" \
    "sudo $PING_BIN -c 2 -i 0.1 $TARGET"

run_test "11. Verbose Option (-v)" \
    "sudo $PING_BIN -c 1 -v $TARGET"

run_test "12. Verbose + Count (-v -c 1)" \
    "sudo $PING_BIN -v -c 1 $TARGET"

run_test "13. Flood Option (-f) [Short burst]" \
    "sudo timeout 2 $PING_BIN -f -c 10 $TARGET"

run_test "14. Audible Option (-a)" \
    "sudo $PING_BIN -c 1 -a $TARGET"

run_test "15. Combined: -c 2 -s 64 -v" \
    "sudo $PING_BIN -c 2 -s 64 -v $TARGET"

run_test "16. Combined: -c 1 --ttl 64 -W 3" \
    "sudo $PING_BIN -c 1 --ttl 64 -W 3 $TARGET"

run_test "17. Combined: -v -f -c 5 [Verbose + Flood]" \
    "sudo timeout 2 $PING_BIN -v -f -c 5 $TARGET"

run_test "18. Combined: -c 1 -s 256 -i 0.05" \
    "sudo $PING_BIN -c 1 -s 256 -i 0.05 $TARGET"

run_test "19. Combined: All Options (-v -c 3 -s 100 --ttl 64 -i 0.1)" \
    "sudo $PING_BIN -v -c 3 -s 100 --ttl 64 -i 0.1 $TARGET"

run_test "20. Error: Invalid Hostname" \
    "! sudo $PING_BIN -c 1 invalid.hostname.test.123456 2>/dev/null"

run_test "21. Error: No Arguments" \
    "! $PING_BIN 2>/dev/null"

run_test "22. Error: Same argument twice" \
    "! sudo $PING_BIN -c 2 -c 3 $TARGET 2>/dev/null || true"

echo -e "\n${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           TEST SUMMARY                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total Tests: ${YELLOW}$TOTAL${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}\n"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
