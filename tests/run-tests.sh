#!/usr/bin/env bash
# VM Test Runner for Dotfiles Configuration
# Usage: ./run-tests.sh [test-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"

# Detect operating system and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Set platform-specific variables
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="aarch64-darwin"
    IS_DARWIN=true
    IS_LINUX=false
else
    PLATFORM="x86_64-linux"
    IS_DARWIN=false
    IS_LINUX=true
fi

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

# Available tests - platform specific
if [[ "$IS_DARWIN" == true ]]; then
    AVAILABLE_TESTS=(
        "darwin-system-test"
        "darwin-home-manager-test"
        "darwin-packages-test"
    )
else
    AVAILABLE_TESTS=(
        "basic-system-test"
        # "auto-update-test"  # Commented out - needs fixing
        "machine-specific-test"
        "home-manager-test"
    )
fi

# Function to run a specific test
run_test() {
    local test_name="$1"
    log_info "Running test: $test_name on $PLATFORM"

    if [[ "$IS_DARWIN" == true ]]; then
        # For Darwin, we'll use different test approach since VMs aren't practical
        case "$test_name" in
            "darwin-system-test")
                run_darwin_system_test
                ;;
            "darwin-home-manager-test")
                run_darwin_home_manager_test
                ;;
            "darwin-packages-test")
                run_darwin_packages_test
                ;;
            *)
                log_error "Unknown Darwin test: $test_name"
                return 1
                ;;
        esac
    else
        # Linux VM-based tests
        if nix build ".#checks.x86_64-linux.${test_name}" --show-trace; then
            log_success "Test $test_name passed!"
            return 0
        else
            log_error "Test $test_name failed!"
            return 1
        fi
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

# Function to build VM configurations (Linux) or system configurations (Darwin)
build_vm_configs() {
    if [[ "$IS_DARWIN" == true ]]; then
        log_info "Building Darwin system configuration..."

        if nix build ".#darwinConfigurations.reepicheep.system" --show-trace; then
            log_success "Built Darwin system configuration"
            return 0
        else
            log_error "Failed to build Darwin system configuration"
            return 1
        fi
    else
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
    fi
}

# Function to run interactive VM (Linux only)
run_interactive_vm() {
    if [[ "$IS_DARWIN" == true ]]; then
        log_error "Interactive VMs are not supported on Darwin"
        log_info "Use 'darwin-rebuild switch --flake .#reepicheep' to apply Darwin configuration"
        return 1
    fi

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
    echo "Platform: $PLATFORM"
    echo ""
    echo "Usage: $0 [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  test [test-name]     Run a specific test (or all tests if no name given)"
    echo "  build               Build system configurations"
    if [[ "$IS_LINUX" == true ]]; then
        echo "  vm <vm-name>        Run an interactive VM"
    fi
    echo "  list                List available tests"
    echo "  help                Show this help message"
    echo ""
    echo "Available tests:"
    for test in "${AVAILABLE_TESTS[@]}"; do
        echo "  - $test"
    done

    if [[ "$IS_LINUX" == true ]]; then
        echo ""
        echo "Available VMs:"
        echo "  - nixos-wsl-abadar"
        echo "  - nixos-wsl-wizardfoot"
    fi

    echo ""
    echo "Examples:"
    echo "  $0 test                    # Run all tests"
    if [[ "$IS_DARWIN" == true ]]; then
        echo "  $0 test darwin-system-test # Run Darwin system test"
        echo "  $0 build                   # Build Darwin configuration"
    else
        echo "  $0 test basic-system-test  # Run specific test"
        echo "  $0 build                   # Build all VM configs"
        echo "  $0 vm nixos-wsl-abadar     # Run interactive abadar VM"
    fi
}

# Darwin-specific test functions
run_darwin_system_test() {
    log_info "Testing Darwin system configuration build..."

    if nix build ".#darwinConfigurations.reepicheep.system" --show-trace; then
        log_success "Darwin system configuration builds successfully!"
        return 0
    else
        log_error "Darwin system configuration failed to build!"
        return 1
    fi
}

run_darwin_home_manager_test() {
    log_info "Testing Darwin Home Manager configuration..."

    if nix build ".#darwinConfigurations.reepicheep.config.home-manager.users.rictic.home.activationPackage" --show-trace; then
        log_success "Darwin Home Manager configuration builds successfully!"
        return 0
    else
        log_error "Darwin Home Manager configuration failed to build!"
        return 1
    fi
}

run_darwin_packages_test() {
    log_info "Testing Darwin package availability..."

    # Test that we can build a simple derivation to validate packages are available
    if nix build ".#darwinConfigurations.reepicheep.config.system.build.toplevel" --show-trace; then
        log_success "Darwin system packages build successfully!"
        return 0
    else
        log_error "Darwin system packages failed to build!"
        return 1
    fi
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
            if [[ "$IS_DARWIN" == true ]]; then
                log_error "Interactive VMs are not supported on Darwin"
                log_info "Use 'darwin-rebuild switch --flake .#reepicheep' to apply Darwin configuration"
                exit 1
            fi
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
            if [[ "$IS_LINUX" == true ]]; then
                echo ""
                echo "Available VMs:"
                echo "  - nixos-wsl-abadar"
                echo "  - nixos-wsl-wizardfoot"
            fi
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
