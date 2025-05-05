#!/bin/bash

# NVIDIA GPU Test Script for Ubuntu
# This script performs various GPU tests and collects system logs

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create timestamp for files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_FILE="nvidia_gpu_test_results_${TIMESTAMP}.txt"
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
                                                                                            echo -e "${YELLOW}NVIDIA GPU Testing Suite${NC}"
                                                                                            echo -e "${YELLOW}Testing started at: $(date)${NC}"
                                                                                            echo

                                                                                            write_result "NVIDIA GPU Test Results"
                                                                                            write_result "======================"
                                                                                            write_result "Test started: $(date)"
                                                                                            write_result "System: $(uname -a)"
                                                                                            write_result ""

                                                                                            # Check if running as root
                                                                                            if [ "$EUID" -ne 0 ]; then
                                                                                                echo -e "${RED}Warning: Some tests require root privileges. Please run with sudo for complete testing.${NC}"
                                                                                                    write_result "Warning: Running without root privileges"
                                                                                                    fi

                                                                                                    # 1. Check NVIDIA GPU Detection
                                                                                                    run_test "NVIDIA GPU Detection" "lspci | grep -i 'VGA\|3D\|Display' | grep -i NVIDIA"

                                                                                                    # 2. Check NVIDIA Driver Status
                                                                                                    run_test "NVIDIA Driver Status" "lsmod | grep nvidia"

                                                                                                    # 3. Check nvidia-smi availability
                                                                                                    if command -v nvidia-smi &> /dev/null; then
                                                                                                        run_test "NVIDIA SMI Basic Test" "nvidia-smi"
                                                                                                            run_test "NVIDIA Driver Version" "nvidia-smi --query-gpu=driver_version --format=csv,noheader"
                                                                                                                run_test "GPU Temperature" "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader"
                                                                                                                    run_test "GPU Power Usage" "nvidia-smi --query-gpu=power.draw --format=csv,noheader"
                                                                                                                        run_test "GPU Memory Usage" "nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader"
                                                                                                                            run_test "GPU Utilization" "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader"
                                                                                                                                run_test "GPU Clock Speeds" "nvidia-smi --query-gpu=clocks.gr,clocks.mem --format=csv,noheader"
                                                                                                                                    run_test "GPU ECC Errors" "nvidia-smi --query-gpu=ecc.errors.corrected.volatile.total,ecc.errors.uncorrected.volatile.total --format=csv,noheader"
                                                                                                                                    else
                                                                                                                                        echo -e "${RED}nvidia-smi not found. NVIDIA drivers may not be installed properly.${NC}"
                                                                                                                                            write_result "NVIDIA SMI Tests: FAILED (nvidia-smi not found)"
                                                                                                                                            fi

                                                                                                                                            # 4. CUDA Information (if available)
                                                                                                                                            if command -v nvcc &> /dev/null; then
                                                                                                                                                run_test "CUDA Version" "nvcc --version"
                                                                                                                                                else
                                                                                                                                                    echo -e "${YELLOW}CUDA toolkit not installed. Skipping CUDA version test.${NC}"
                                                                                                                                                        write_result "CUDA Version Test: SKIPPED (CUDA toolkit not installed)"
                                                                                                                                                        fi

                                                                                                                                                        # 5. CUDA Bandwidth Test (if available)
                                                                                                                                                        if [ -f /usr/local/cuda/samples/1_Utilities/bandwidthTest/bandwidthTest ]; then
                                                                                                                                                            run_test "CUDA Bandwidth Test" "/usr/local/cuda/samples/1_Utilities/bandwidthTest/bandwidthTest"
                                                                                                                                                            elif [ -f /usr/local/cuda/extras/demo_suite/bandwidthTest ]; then
                                                                                                                                                                run_test "CUDA Bandwidth Test" "/usr/local/cuda/extras/demo_suite/bandwidthTest"
                                                                                                                                                                else
                                                                                                                                                                    echo -e "${YELLOW}CUDA bandwidth test not found. Skipping bandwidth test.${NC}"
                                                                                                                                                                        write_result "CUDA Bandwidth Test: SKIPPED (test program not found)"
                                                                                                                                                                        fi

                                                                                                                                                                        # 6. Device Query Test (if available)
                                                                                                                                                                        if [ -f /usr/local/cuda/samples/1_Utilities/deviceQuery/deviceQuery ]; then
                                                                                                                                                                            run_test "CUDA Device Query" "/usr/local/cuda/samples/1_Utilities/deviceQuery/deviceQuery"
                                                                                                                                                                            elif [ -f /usr/local/cuda/extras/demo_suite/deviceQuery ]; then
                                                                                                                                                                                run_test "CUDA Device Query" "/usr/local/cuda/extras/demo_suite/deviceQuery"
                                                                                                                                                                                else
                                                                                                                                                                                    echo -e "${YELLOW}CUDA device query not found. Skipping device query test.${NC}"
                                                                                                                                                                                        write_result "CUDA Device Query: SKIPPED (test program not found)"
                                                                                                                                                                                        fi

                                                                                                                                                                                        # 7. Check for NVIDIA Persistence Daemon
                                                                                                                                                                                        run_test "NVIDIA Persistence Daemon" "systemctl status nvidia-persistenced"

                                                                                                                                                                                        # 8. Check Vulkan Support
                                                                                                                                                                                        if command -v vulkaninfo &> /dev/null; then
                                                                                                                                                                                            run_test "Vulkan Support" "vulkaninfo --summary | grep -i NVIDIA"
                                                                                                                                                                                            else
                                                                                                                                                                                                echo -e "${YELLOW}Vulkan tools not installed. Skipping Vulkan test.${NC}"
                                                                                                                                                                                                    write_result "Vulkan Tests: SKIPPED (vulkan-tools not installed)"
                                                                                                                                                                                                    fi

                                                                                                                                                                                                    # 9. OpenGL Information
                                                                                                                                                                                                    if command -v glxinfo &> /dev/null; then
                                                                                                                                                                                                        run_test "OpenGL Information" "glxinfo | grep -i 'OpenGL\|renderer'"
                                                                                                                                                                                                        else
                                                                                                                                                                                                            echo -e "${YELLOW}glxinfo not installed. Skipping OpenGL test.${NC}"
                                                                                                                                                                                                                write_result "OpenGL Tests: SKIPPED (mesa-utils not installed)"
                                                                                                                                                                                                                fi

                                                                                                                                                                                                                # 10. GPU Burn Test (if available)
                                                                                                                                                                                                                if command -v gpu-burn &> /dev/null; then
                                                                                                                                                                                                                    echo -e "${YELLOW}Running GPU stress test (10 seconds)...${NC}"
                                                                                                                                                                                                                        run_test "GPU Stress Test" "gpu-burn 10"
                                                                                                                                                                                                                        else
                                                                                                                                                                                                                            echo -e "${YELLOW}gpu-burn not installed. Skipping GPU stress test.${NC}"
                                                                                                                                                                                                                                write_result "GPU Stress Test: SKIPPED (gpu-burn not installed)"
                                                                                                                                                                                                                                fi

                                                                                                                                                                                                                                # 11. NVIDIA Bug Report (comprehensive diagnostics)
                                                                                                                                                                                                                                if command -v nvidia-bug-report.sh &> /dev/null; then
                                                                                                                                                                                                                                    echo -e "${YELLOW}Generating NVIDIA bug report (this may take a while)...${NC}"
                                                                                                                                                                                                                                        nvidia-bug-report.sh --output-file "$LOG_DIR/nvidia-bug-report.log.gz" &>/dev/null
                                                                                                                                                                                                                                            write_result "NVIDIA Bug Report: Generated"
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
                                                                                                                                                                                                                                                                    journalctl -b 0 --no-pager | grep -i 'nvidia\|gpu\|cuda' > "$LOG_DIR/journal_gpu.log"
                                                                                                                                                                                                                                                                    fi

                                                                                                                                                                                                                                                                    # Collect hardware information
                                                                                                                                                                                                                                                                    echo "Collecting hardware information..."
                                                                                                                                                                                                                                                                    lshw -C display > "$LOG_DIR/lshw_display.txt" 2>/dev/null

                                                                                                                                                                                                                                                                    # NVIDIA-specific logs
                                                                                                                                                                                                                                                                    if [ -d /proc/driver/nvidia ]; then
                                                                                                                                                                                                                                                                        echo "Collecting NVIDIA proc information..."
                                                                                                                                                                                                                                                                            cp -r /proc/driver/nvidia "$LOG_DIR/proc_nvidia" 2>/dev/null
                                                                                                                                                                                                                                                                            fi

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