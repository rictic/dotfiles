#!/usr/bin/env bash
# VM Test Runner for Dotfiles Configuration
# Usage: ./run-tests.sh [test-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Available tests
AVAILABLE_TESTS=(
    "basic-system-test"
    # "auto-update-test"  # Commented out - needs fixing
    "machine-specific-test"
    "home-manager-test"
)

# Function to run a specific test
run_test() {
    local test_name="$1"
    log_info "Running test: $test_name"
    
    if nix build ".#checks.x86_64-linux.${test_name}" --show-trace; then
        log_success "Test $test_name passed!"
        return 0
    else
        log_error "Test $test_name failed!"
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    local failed_tests=()
    local passed_tests=()
    
    log_info "Running all VM tests..."
    
    for test in "${AVAILABLE_TESTS[@]}"; do
        if run_test "$test"; then
            passed_tests+=("$test")
        else
            failed_tests+=("$test")
        fi
        echo ""
    done
    
    # Summary
    echo "=========================="
    echo "TEST SUMMARY"
    echo "=========================="
    
    if [ ${#passed_tests[@]} -gt 0 ]; then
        log_success "Passed tests (${#passed_tests[@]}):"
        for test in "${passed_tests[@]}"; do
            echo "  ✓ $test"
        done
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        log_error "Failed tests (${#failed_tests[@]}):"
        for test in "${failed_tests[@]}"; do
            echo "  ✗ $test"
        done
        return 1
    fi
    
    log_success "All tests passed!"
    return 0
}

# Function to build VM configurations
build_vm_configs() {
    log_info "Building VM configurations..."
    
    local configs=(
        "nixos-wsl-abadar"
        "nixos-wsl-wizardfoot"
    )
    
    for config in "${configs[@]}"; do
        log_info "Building $config..."
        if nix build ".#vmTests.${config}.config.system.build.vm" --show-trace; then
            log_success "Built $config VM"
        else
            log_error "Failed to build $config VM"
            return 1
        fi
    done
}

# Function to run interactive VM
run_interactive_vm() {
    local vm_name="$1"
    log_info "Starting interactive VM: $vm_name"
    
    # Build the VM first
    if ! nix build ".#vmTests.${vm_name}.config.system.build.vm" --show-trace; then
        log_error "Failed to build VM: $vm_name"
        return 1
    fi
    
    # Run the VM
    log_info "Starting VM (use Ctrl+C to quit)..."
    result/bin/run-*-vm
}

# Function to show available tests
show_help() {
    echo "VM Test Runner for Dotfiles Configuration"
    echo ""
    echo "Usage: $0 [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  test [test-name]     Run a specific test (or all tests if no name given)"
    echo "  build               Build all VM configurations"
    echo "  vm <vm-name>        Run an interactive VM"
    echo "  list                List available tests and VMs"
    echo "  help                Show this help message"
    echo ""
    echo "Available tests:"
    for test in "${AVAILABLE_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
    echo "Available VMs:"
    echo "  - nixos-wsl-abadar"
    echo "  - nixos-wsl-wizardfoot"
    echo ""
    echo "Examples:"
    echo "  $0 test                    # Run all tests"
    echo "  $0 test basic-system-test  # Run specific test"
    echo "  $0 build                   # Build all VM configs"
    echo "  $0 vm nixos-wsl-abadar     # Run interactive abadar VM"
}

# Main script logic
main() {
    cd "$FLAKE_DIR"
    
    case "${1:-help}" in
        "test")
            if [ $# -eq 1 ]; then
                run_all_tests
            else
                test_name="$2"
                if [[ " ${AVAILABLE_TESTS[*]} " =~ " ${test_name} " ]]; then
                    run_test "$test_name"
                else
                    log_error "Unknown test: $test_name"
                    echo "Available tests: ${AVAILABLE_TESTS[*]}"
                    exit 1
                fi
            fi
            ;;
        "build")
            build_vm_configs
            ;;
        "vm")
            if [ $# -lt 2 ]; then
                log_error "VM name required"
                echo "Available VMs: nixos-wsl-abadar, nixos-wsl-wizardfoot"
                exit 1
            fi
            run_interactive_vm "$2"
            ;;
        "list")
            echo "Available tests:"
            for test in "${AVAILABLE_TESTS[@]}"; do
                echo "  - $test"
            done
            echo ""
            echo "Available VMs:"
            echo "  - nixos-wsl-abadar"
            echo "  - nixos-wsl-wizardfoot"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
