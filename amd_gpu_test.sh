#!/bin/bash

# AMD GPU Test Script for Ubuntu
# This script performs various GPU tests and collects system logs

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create timestamp for files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_FILE="amd_gpu_test_results_${TIMESTAMP}.txt"
LOG_DIR="./logs_${TIMESTAMP}"

# Create logs directory
mkdir -p "$LOG_DIR"

# Function to write to result file
write_result() {
    echo "$1" | tee -a "$RESULT_FILE"
    }

    # Function to run test and check result
    run_test() {
        local test_name="$1"
            local test_command="$2"
                
                    echo -e "${YELLOW}Running $test_name...${NC}"
                        write_result "----------------------------------------"
                            write_result "Test: $test_name"
                                write_result "Time: $(date)"
                                    
                                        # Run the test command and capture output
                                            if eval "$test_command" &> "$LOG_DIR/${test_name// /_}.log"; then
                                                    echo -e "${GREEN}✓ $test_name: PASS${NC}"
                                                            write_result "Result: PASS"
                                                                else
                                                                        echo -e "${RED}✗ $test_name: FAIL${NC}"
                                                                                write_result "Result: FAIL"
                                                                                    fi
                                                                                        write_result "----------------------------------------"
                                                                                            echo
                                                                                            }

                                                                                            # Start testing
                                                                                            echo -e "${YELLOW}AMD GPU Testing Suite${NC}"
                                                                                            echo -e "${YELLOW}Testing started at: $(date)${NC}"
                                                                                            echo

                                                                                            write_result "AMD GPU Test Results"
                                                                                            write_result "===================="
                                                                                            write_result "Test started: $(date)"
                                                                                            write_result "System: $(uname -a)"
                                                                                            write_result ""

                                                                                            # Check if running as root
                                                                                            if [ "$EUID" -ne 0 ]; then
                                                                                                echo -e "${RED}Warning: Some tests require root privileges. Please run with sudo for complete testing.${NC}"
                                                                                                    write_result "Warning: Running without root privileges"
                                                                                                    fi

                                                                                                    # 1. Check AMD GPU Detection
                                                                                                    run_test "AMD GPU Detection" "lspci | grep -i 'VGA\|3D\|Display' | grep -i AMD"

                                                                                                    # 2. Check AMDGPU Driver Status
                                                                                                    run_test "AMDGPU Driver Status" "lsmod | grep amdgpu"

                                                                                                    # 3. Check for AMD GPU in /sys
                                                                                                    run_test "AMD GPU in /sys" "ls /sys/class/drm/ | grep card"

                                                                                                    # 4. Check DRM Devices
                                                                                                    run_test "DRM Devices Check" "ls -la /dev/dri/"

                                                                                                    # 5. Check Radeon Top (if available)
                                                                                                    if command -v radeontop &> /dev/null; then
                                                                                                        run_test "RadeonTop GPU Load Test" "timeout 5 radeontop -d - -l 1"
                                                                                                        else
                                                                                                            echo -e "${YELLOW}RadeonTop not installed. Skipping GPU load test.${NC}"
                                                                                                                write_result "RadeonTop: SKIPPED (not installed)"
                                                                                                                fi

                                                                                                                # 6. Check ROCm Status (if available)
                                                                                                                if command -v rocm-smi &> /dev/null; then
                                                                                                                    run_test "ROCm SMI Test" "rocm-smi"
                                                                                                                        run_test "ROCm Clock Speeds" "rocm-smi --showclocks"
                                                                                                                            run_test "ROCm Temperature" "rocm-smi --showtemp"
                                                                                                                                run_test "ROCm Power Usage" "rocm-smi --showpower"
                                                                                                                                else
                                                                                                                                    echo -e "${YELLOW}ROCm not installed. Skipping ROCm tests.${NC}"
                                                                                                                                        write_result "ROCm Tests: SKIPPED (not installed)"
                                                                                                                                        fi

                                                                                                                                        # 7. Check Vulkan Support
                                                                                                                                        if command -v vulkaninfo &> /dev/null; then
                                                                                                                                            run_test "Vulkan Support" "vulkaninfo --summary"
                                                                                                                                            else
                                                                                                                                                echo -e "${YELLOW}Vulkan tools not installed. Skipping Vulkan test.${NC}"
                                                                                                                                                    write_result "Vulkan Tests: SKIPPED (vulkan-tools not installed)"
                                                                                                                                                    fi

                                                                                                                                                    # 8. OpenGL Information
                                                                                                                                                    if command -v glxinfo &> /dev/null; then
                                                                                                                                                        run_test "OpenGL Information" "glxinfo | grep -i 'OpenGL\|renderer'"
                                                                                                                                                        else
                                                                                                                                                            echo -e "${YELLOW}glxinfo not installed. Skipping OpenGL test.${NC}"
                                                                                                                                                                write_result "OpenGL Tests: SKIPPED (mesa-utils not installed)"
                                                                                                                                                                fi

                                                                                                                                                                # 9. Memory Test using clpeak (if available)
                                                                                                                                                                if command -v clpeak &> /dev/null; then
                                                                                                                                                                    run_test "OpenCL Memory Bandwidth Test" "clpeak --global-bandwidth --global-bandwidth-only"
                                                                                                                                                                    else
                                                                                                                                                                        echo -e "${YELLOW}clpeak not installed. Skipping OpenCL memory test.${NC}"
                                                                                                                                                                            write_result "OpenCL Memory Test: SKIPPED (clpeak not installed)"
                                                                                                                                                                            fi

                                                                                                                                                                            # Collect System Logs
                                                                                                                                                                            echo -e "${YELLOW}Collecting system logs...${NC}"

                                                                                                                                                                            # Kernel logs (dmesg)
                                                                                                                                                                            echo "Collecting kernel logs..."
                                                                                                                                                                            dmesg > "$LOG_DIR/dmesg.log"

                                                                                                                                                                            # System logs
                                                                                                                                                                            if [ -f /var/log/syslog ]; then
                                                                                                                                                                                echo "Collecting syslog..."
                                                                                                                                                                                    tail -n 1000 /var/log/syslog > "$LOG_DIR/syslog.log"
                                                                                                                                                                                    fi

                                                                                                                                                                                    # Xorg logs (if available)
                                                                                                                                                                                    if [ -f /var/log/Xorg.0.log ]; then
                                                                                                                                                                                        echo "Collecting Xorg logs..."
                                                                                                                                                                                            cp /var/log/Xorg.0.log "$LOG_DIR/"
                                                                                                                                                                                            fi

                                                                                                                                                                                            # Journal logs for GPU related messages
                                                                                                                                                                                            if command -v journalctl &> /dev/null; then
                                                                                                                                                                                                echo "Collecting journal logs..."
                                                                                                                                                                                                    journalctl -b 0 --no-pager | grep -i 'amd\|gpu\|drm\|radeon' > "$LOG_DIR/journal_gpu.log"
                                                                                                                                                                                                    fi

                                                                                                                                                                                                    # Collect hardware information
                                                                                                                                                                                                    echo "Collecting hardware information..."
                                                                                                                                                                                                    lshw -C display > "$LOG_DIR/lshw_display.txt" 2>/dev/null

                                                                                                                                                                                                    # Summary
                                                                                                                                                                                                    echo
                                                                                                                                                                                                    echo -e "${YELLOW}Testing completed at: $(date)${NC}"
                                                                                                                                                                                                    write_result ""
                                                                                                                                                                                                    write_result "Test completed: $(date)"

                                                                                                                                                                                                    # Count results
                                                                                                                                                                                                    TOTAL_TESTS=$(grep -c "^Test:" "$RESULT_FILE")
                                                                                                                                                                                                    PASSED_TESTS=$(grep -c "Result: PASS" "$RESULT_FILE")
                                                                                                                                                                                                    FAILED_TESTS=$(grep -c "Result: FAIL" "$RESULT_FILE")
                                                                                                                                                                                                    SKIPPED_TESTS=$(grep -c "SKIPPED" "$RESULT_FILE")

                                                                                                                                                                                                    write_result ""
                                                                                                                                                                                                    write_result "Test Summary:"
                                                                                                                                                                                                    write_result "============="
                                                                                                                                                                                                    write_result "Total Tests: $TOTAL_TESTS"
                                                                                                                                                                                                    write_result "Passed: $PASSED_TESTS"
                                                                                                                                                                                                    write_result "Failed: $FAILED_TESTS"
                                                                                                                                                                                                    write_result "Skipped: $SKIPPED_TESTS"

                                                                                                                                                                                                    echo
                                                                                                                                                                                                    echo -e "${GREEN}Results written to: $RESULT_FILE${NC}"
                                                                                                                                                                                                    echo -e "${GREEN}Logs collected in: $LOG_DIR${NC}"

                                                                                                                                                                                                    # Display summary to terminal
                                                                                                                                                                                                    echo
                                                                                                                                                                                                    echo -e "${YELLOW}Test Summary:${NC}"
                                                                                                                                                                                                    echo -e "Total Tests: $TOTAL_TESTS"
                                                                                                                                                                                                    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
                                                                                                                                                                                                    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
                                                                                                                                                                                                    echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"