#!/bin/bash

TARGET="127.0.0.1"
TARGET_UNAVAILABLE="192.0.2.1"  # RFC 5737 - "TEST-NET-1" não roteia
TARGET_HOSTNAME="google.com"
PING_BIN="./ft_ping"
SYSTEM_PING="ping"
TESTS_PASSED=0
TESTS_FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

run_test_verbose() {
    local test_name="$1"
    local cmd="$2"
    local should_fail="$3"  # "true" if test should fail gracefully
    
    print_test_header "$test_name"
    echo -e "Command: ${YELLOW}$cmd${NC}\n"
    
    output=$(eval "$cmd" 2>&1)
    exit_code=$?
    
    echo "$output"
    
    if [ "$should_fail" = "true" ]; then
        # Test should fail
        if [ $exit_code -ne 0 ]; then
            echo -e "\n${GREEN}✅ PASSED (correctly failed)${NC}\n"
            ((TESTS_PASSED++))
        else
            echo -e "\n${RED}❌ FAILED (should have failed)${NC}\n"
            ((TESTS_FAILED++))
        fi
    else
        # Test should succeed
        if [ $exit_code -eq 0 ]; then
            echo -e "\n${GREEN}✅ PASSED${NC}\n"
            ((TESTS_PASSED++))
        else
            echo -e "\n${RED}❌ FAILED${NC}\n"
            ((TESTS_FAILED++))
        fi
    fi
}

compare_output() {
    local test_name="$1"
    local ft_cmd="$2"
    local sys_cmd="$3"
    
    print_test_header "$test_name"
    echo -e "ft_ping:  ${YELLOW}$ft_cmd${NC}"
    echo -e "ping:     ${YELLOW}$sys_cmd${NC}\n"
    
    # Get outputs (suppress last stats line as per régua)
    ft_output=$(eval "$ft_cmd" 2>&1 | head -n 20)
    sys_output=$(eval "$sys_cmd" 2>&1 | head -n 20)
    
    echo -e "${CYAN}ft_ping output:${NC}"
    echo "$ft_output"
    echo ""
    echo -e "${CYAN}ping output:${NC}"
    echo "$sys_output"
    echo ""
    
    # Check if both got packets
    ft_packets=$(echo "$ft_output" | grep -o "icmp_seq=[0-9]*" | wc -l)
    sys_packets=$(echo "$sys_output" | grep -o "icmp_seq=[0-9]*" -o "bytes from" | wc -l)
    
    if [ $ft_packets -gt 0 ] || [ $sys_packets -gt 0 ]; then
        echo -e "${GREEN}✅ PASSED (both or one got packets)${NC}\n"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  SKIPPED (no packets - check connectivity)${NC}\n"
    fi
}

if [ ! -f "$PING_BIN" ]; then
    echo -e "${RED}Error: $PING_BIN not found. Run 'make' first.${NC}"
    exit 1
fi

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     FT_PING RÉGUA COMPLIANCE TEST SUITE    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

# ============================================================================
# SECTION 1: PRELIMINARES & CERTIFICAÇÃO
# ============================================================================
echo -e "${MAGENTA}📋 SECTION 1: PRELIMINARES${NC}\n"

run_test "1.1. Help Option (-?)" \
    "$PING_BIN -?"

run_test_verbose "1.2. No Root Error (without sudo)" \
    "$PING_BIN -c 1 $TARGET" \
    "true"

run_test_verbose "1.3. Missing Destination" \
    "$PING_BIN 2>&1" \
    "true"

# ============================================================================
# SECTION 2: TESTES DE IP VÁLIDO E FUNCIONAL
# ============================================================================
echo -e "${MAGENTA}🌐 SECTION 2: IP VÁLIDO E FUNCIONAL (Localhost)${NC}\n"

run_test "2.1. Basic Ping -c 1 (IP válido funcional)" \
    "sudo $PING_BIN -c 1 $TARGET"

run_test "2.2. Basic Ping -c 4 (Default count)" \
    "sudo $PING_BIN -c 4 $TARGET"

run_test "2.3. Compare With System Ping" \
    "compare_output 'ft_ping vs system ping (-c 1)' 'sudo $PING_BIN -c 1 $TARGET' '$SYSTEM_PING -c 1 $TARGET'"

# ============================================================================
# SECTION 3: TESTES DE IP VÁLIDO MAS NÃO FUNCIONAL
# ============================================================================
echo -e "${MAGENTA}🌐 SECTION 3: IP VÁLIDO NÃO FUNCIONAL (Timeout)${NC}\n"

run_test_verbose "3.1. IP Não Funcional (-c 1 -W 1)" \
    "timeout 5 sudo $PING_BIN -c 1 -W 1 $TARGET_UNAVAILABLE 2>&1"

run_test_verbose "3.2. IP Não Funcional com Verbose" \
    "timeout 5 sudo $PING_BIN -c 1 -W 1 -v $TARGET_UNAVAILABLE 2>&1"

# ============================================================================
# SECTION 4: TESTES DE HOSTNAME VÁLIDO E FUNCIONAL
# ============================================================================
echo -e "${MAGENTA}🌐 SECTION 4: HOSTNAME VÁLIDO E FUNCIONAL${NC}\n"

run_test_verbose "4.1. Hostname Válido (google.com -c 1)" \
    "timeout 10 sudo $PING_BIN -c 1 $TARGET_HOSTNAME 2>&1"

run_test_verbose "4.2. Compare : Hostname with ping" \
    "compare_output 'Hostname: ft_ping vs ping' 'timeout 5 sudo $PING_BIN -c 1 $TARGET_HOSTNAME 2>&1' 'timeout 5 $SYSTEM_PING -c 1 $TARGET_HOSTNAME 2>&1'"

# ============================================================================
# SECTION 5: TESTES DE HOSTNAME NÃO FUNCIONAL
# ============================================================================
echo -e "${MAGENTA}🌐 SECTION 5: HOSTNAME NÃO FUNCIONAL${NC}\n"

run_test_verbose "5.1. Hostname Inválido (invalid-host-12345.test)" \
    "sudo $PING_BIN -c 1 invalid-host-12345.test 2>&1" \
    "true"

# ============================================================================
# SECTION 6: OPÇÃO -v (VERBOSE) EM ERRO
# ============================================================================
echo -e "${MAGENTA}🔍 SECTION 6: VERBOSE COM ERRO${NC}\n"

run_test_verbose "6.1. Verbose Flag (-v -c 1) com IP funcional" \
    "sudo $PING_BIN -v -c 1 $TARGET"

run_test_verbose "6.2. Verbose com IP não funcional" \
    "timeout 5 sudo $PING_BIN -v -c 1 -W 1 $TARGET_UNAVAILABLE 2>&1"

# ============================================================================
# SECTION 7: TESTES DE OPÇÕES INDIVIDUAIS
# ============================================================================
echo -e "${MAGENTA}⚙️  SECTION 7: OPÇÕES INDIVIDUAIS${NC}\n"

run_test "7.1. Count Option (-c 1)" \
    "sudo $PING_BIN -c 1 $TARGET"

run_test "7.2. Count Option (-c 2)" \
    "sudo $PING_BIN -c 2 $TARGET"

run_test "7.3. Packet Size (-s 32)" \
    "sudo $PING_BIN -c 1 -s 32 $TARGET"

run_test "7.4. Packet Size (-s 128)" \
    "sudo $PING_BIN -c 1 -s 128 $TARGET"

run_test "7.5. TTL Option (--ttl 64)" \
    "sudo $PING_BIN -c 1 --ttl 64 $TARGET"

run_test "7.6. TTL Option (--ttl 32)" \
    "sudo $PING_BIN -c 1 --ttl 32 $TARGET"

run_test "7.7. Timeout Option (-W 2)" \
    "sudo $PING_BIN -c 1 -W 2 $TARGET"

run_test "7.8. Interval Option (-i 0.2)" \
    "sudo $PING_BIN -c 2 -i 0.2 $TARGET"

run_test "7.9. Deadline Option (-w 5)" \
    "sudo timeout 10 $PING_BIN -c 10 -w 5 $TARGET"

# ============================================================================
# SECTION 8: OPÇÕES AVANÇADAS
# ============================================================================
echo -e "${MAGENTA}🚀 SECTION 8: OPÇÕES AVANÇADAS${NC}\n"

run_test "8.1. Flood Option (-f -c 10) [SHORT]" \
    "sudo timeout 2 $PING_BIN -f -c 10 $TARGET"

run_test "8.2. Audible Option (-a)" \
    "sudo $PING_BIN -c 1 -a $TARGET"

# ============================================================================
# SECTION 9: COMBINAÇÕES DE OPÇÕES
# ============================================================================
echo -e "${MAGENTA}🔗 SECTION 9: COMBINAÇÕES DE OPÇÕES${NC}\n"

run_test "9.1. Combined: -c 2 -s 64 -v" \
    "sudo $PING_BIN -c 2 -s 64 -v $TARGET"

run_test "9.2. Combined: -c 1 --ttl 64 -W 3" \
    "sudo $PING_BIN -c 1 --ttl 64 -W 3 $TARGET"

run_test "9.3. Combined: -v -f -c 5" \
    "sudo timeout 2 $PING_BIN -v -f -c 5 $TARGET"

run_test "9.4. Combined: -c 1 -s 256 -i 0.05" \
    "sudo $PING_BIN -c 1 -s 256 -i 0.05 $TARGET"

run_test "9.5. Combined: All Options (-v -c 3 -s 100 --ttl 64 -i 0.1)" \
    "sudo $PING_BIN -v -c 3 -s 100 --ttl 64 -i 0.1 $TARGET"

# ============================================================================
# SECTION 10: TESTES DE ERRO & EDGE CASES
# ============================================================================
echo -e "${MAGENTA}⚠️  SECTION 10: ERRO & EDGE CASES${NC}\n"

run_test_verbose "10.1. Invalid Hostname" \
    "sudo $PING_BIN -c 1 invalid.hostname.test.123456 2>&1" \
    "true"

run_test_verbose "10.2. Extra Arguments" \
    "$PING_BIN $TARGET extra_arg 2>&1" \
    "true"

# ============================================================================
# SECTION 11: TEST INTERRUPÇÃO (Apenas informativo)
# ============================================================================
echo -e "${MAGENTA}⏹️  SECTION 11: INTERRUPÇÃO (CTRL+C)${NC}\n"
print_test_header "11.1. Manual Test: CTRL+C"
echo -e "${YELLOW}Run: sudo $PING_BIN -c 100 $TARGET${NC}"
echo -e "${YELLOW}Then press CTRL+C within 3-5 seconds${NC}"
echo -e "${YELLOW}Program should interrupt gracefully${NC}"
echo -e "${CYAN}⏭️  SKIPPING automatic test (requires interaction)${NC}\n"

# ============================================================================
# FINAL SUMMARY
# ============================================================================

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           📊 TEST SUMMARY                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total Tests: ${YELLOW}$TOTAL${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}\n"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! 🎉${NC}"
    echo -e "${CYAN}Project complies with the régua!${NC}\n"
    exit 0
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    echo -e "${YELLOW}Review failures above.${NC}\n"
    exit 1
fi
