# VM Tests for Dotfiles Configuration

This directory contains comprehensive VM tests for the dotfiles configuration to ensure all components work correctly across different machines and setups.

## Overview

The test suite includes:
- **System Integration Tests**: Verify basic system functionality and package installation
- **Auto-Update Tests**: Test the automatic dotfiles update service
- **Machine-Specific Tests**: Ensure each machine configuration works correctly
- **Home-Manager Tests**: Verify user-level configuration and packages

## Test Structure

```
tests/
├── vm-tests.nix      # Test definitions and VM configurations
├── run-tests.sh      # Test runner script
└── README.md         # This file
```

## Running Tests

### Prerequisites

Ensure you have:
- Nix with flakes enabled
- Sufficient disk space for VM images (~2GB per VM)
- KVM support for faster virtualization (optional but recommended)

### Quick Start

```bash
# Run all tests
cd /path/to/dotfiles
./tests/run-tests.sh test

# Run a specific test
./tests/run-tests.sh test basic-system-test

# Build VM configurations
./tests/run-tests.sh build

# List available tests and VMs
./tests/run-tests.sh list
```

### Interactive Testing

You can also run interactive VMs for manual testing:

```bash
# Start an interactive abadar VM
./tests/run-tests.sh vm nixos-wsl-abadar

# Start an interactive wizardfoot VM
./tests/run-tests.sh vm nixos-wsl-wizardfoot
```

## Test Descriptions

### Basic System Test (`basic-system-test`)

Tests fundamental system functionality:
- User account creation and authentication
- Essential package installation (git, vim, nodejs, python3, etc.)
- Service startup (Docker, SSH)
- Home-manager configuration application
- Nix flakes functionality
- Shell configuration and aliases

### Auto-Update Test (`auto-update-test`)

Verifies the automatic dotfiles update system:
- Auto-update timer service
- Hello server demo service
- Control script functionality
- Configuration file presence and correctness

### Machine-Specific Test (`machine-specific-test`)

Tests machine-specific configurations:
- Hostname configuration for each machine
- Environment variables (MACHINE_NAME)
- Machine-specific auto-update configuration
- Service configuration per machine

### Home-Manager Test (`home-manager-test`)

Validates user-level configuration:
- User package installation via home-manager
- Shell configuration (zsh, aliases, environment variables)
- Git configuration
- Development tool configuration (starship, tmux, direnv)
- User service configuration

## VM Configurations

### nixos-wsl-abadar

Test VM based on the abadar machine configuration:
- Inherits from `nixos-wsl/abadar/configuration.nix`
- WSL disabled for VM testing
- Test user with password authentication
- 2GB RAM, 8GB disk, 2 CPU cores

### nixos-wsl-wizardfoot

Test VM based on the wizardfoot machine configuration:
- Inherits from `nixos-wsl/wizardfoot/configuration.nix`
- WSL disabled for VM testing
- Test user with password authentication
- 2GB RAM, 8GB disk, 2 CPU cores

## Test Framework

The tests use the NixOS testing framework, which provides:
- Isolated VM environments
- Declarative test scripts
- Automatic cleanup
- Parallel test execution
- Integration with the Nix build system

## Troubleshooting

### Common Issues

1. **VM Build Failures**
   - Ensure flake.lock is up to date: `nix flake update`
   - Check disk space: `df -h`
   - Verify Nix configuration: `nix doctor`

2. **Test Timeouts**
   - Increase VM memory: Edit `virtualisation.memorySize` in vm-tests.nix
   - Check system resources: `htop`

3. **Package Conflicts**
   - Review nixpkgs version compatibility
   - Check overlay definitions in `shared/claude-overlay.nix`

### Debugging Tests

```bash
# Run with verbose output
nix build .#checks.x86_64-linux.basic-system-test --show-trace -v

# Interactive debugging
nix develop
cd tests
./run-tests.sh vm nixos-wsl-abadar
# Inside VM: debug interactively
```

### Log Locations

- Test output: Standard output during test run
- VM logs: Available in nix store path after build
- System logs in VM: `/var/log/` (accessible in interactive mode)

## Extending Tests

### Adding New Tests

1. Add test definition to `vm-tests.nix` in the `integration-tests` section
2. Update `AVAILABLE_TESTS` array in `run-tests.sh`
3. Document the new test in this README

### Test Best Practices

- Keep tests focused and isolated
- Use descriptive test names
- Include both positive and negative test cases
- Test configuration changes thoroughly
- Clean up test resources

### Example Test Template

```nix
my-new-test = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
  name = "dotfiles-my-feature";
  
  nodes.machine = { config, pkgs, ... }: {
    imports = [
      # Your configuration imports
    ];
    
    # Test-specific overrides
    wsl.enable = testLib.mkForce false;
    users.users.rictic.password = testPassword;
  };

  testScript = ''
    machine.wait_for_unit("default.target")
    
    # Your test assertions
    machine.succeed("test-command")
    machine.fail("should-fail-command")
  '';
};
```

## Integration with CI/CD

These tests can be integrated into continuous integration:

```yaml
# Example GitHub Actions workflow
- name: Run VM Tests
  run: |
    nix develop --command ./tests/run-tests.sh test
```

## Performance Considerations

- VM tests require significant resources (CPU, RAM, disk)
- Run tests on machines with adequate specs
- Consider running tests in parallel on multi-core systems
- Use `nix-store --gc` periodically to clean up test artifacts

## Security Notes

- Test VMs use weak passwords for convenience
- VMs are isolated and don't persist beyond test runs
- No sensitive data should be included in test configurations
- WSL integration is disabled in test VMs for security
