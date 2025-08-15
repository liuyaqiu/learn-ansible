#!/bin/bash
# ============================================================================
# Ansible Lint Script - Standalone CI/CD Integration
# ============================================================================
# Usage:
#   ./scripts/lint.sh                 # Run all checks
#   ./scripts/lint.sh --syntax-only   # Run syntax checks only
#   ./scripts/lint.sh --install-deps  # Install dependencies first
#   ./scripts/lint.sh --help          # Show help
# ============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly ANSIBLE_INVENTORY="${ANSIBLE_INVENTORY:-inventories/dev}"

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_TOTAL=0

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((CHECKS_PASSED++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((CHECKS_FAILED++))
}

increment_total() {
    ((CHECKS_TOTAL++))
}

show_help() {
    cat << EOF
🚀 Ansible Lint Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --syntax-only     Run only syntax checks
    --install-deps    Install required dependencies
    --no-color        Disable colored output
    --verbose         Show verbose output
    --help           Show this help message

ENVIRONMENT VARIABLES:
    ANSIBLE_INVENTORY    Inventory path (default: inventories/dev)
    NO_COLOR            Set to disable colors
    LINT_VERBOSE        Set to enable verbose mode

EXAMPLES:
    $0                          # Run all checks
    $0 --syntax-only           # Only syntax checks
    $0 --install-deps          # Install deps and run all checks
    ANSIBLE_INVENTORY=inventories/prod $0  # Use prod inventory

EXIT CODES:
    0    All checks passed
    1    Some checks failed  
    2    Critical error (missing dependencies, etc.)
EOF
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check required commands
    local deps=("python3" "ansible-playbook")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies or run with --install-deps"
        return 2
    fi
    
    # Check optional tools
    local optional_tools=("ansible-lint" "yamllint")
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool is available"
        else
            log_warning "$tool not found (run --install-deps to install)"
        fi
    done
    
    log_success "Core dependencies satisfied"
    return 0
}

install_dependencies() {
    log_info "Installing dependencies..."
    
    # Update pip
    python3 -m pip install --upgrade pip --user
    
    # Install required packages
    local packages=(
        "ansible>=6.0.0"
        "ansible-lint>=6.0.0"
        "yamllint>=1.26.0"
        "jinja2>=3.0.0"
    )
    
    for package in "${packages[@]}"; do
        log_info "Installing $package..."
        python3 -m pip install "$package" --user
    done
    
    log_success "Dependencies installed successfully"
}

run_yaml_lint() {
    increment_total
    log_info "Running YAML lint checks..."
    
    if ! command -v yamllint &> /dev/null; then
        log_warning "yamllint not available, using Python YAML parser..."
        if python3 -c "
import yaml
import glob
import sys

files = (
    glob.glob('playbooks/*.yml') + 
    glob.glob('roles/**/tasks/*.yml', recursive=True) + 
    glob.glob('roles/**/handlers/*.yml', recursive=True) +
    glob.glob('roles/**/vars/*.yml', recursive=True) +
    glob.glob('roles/**/defaults/*.yml', recursive=True) +
    glob.glob('group_vars/*.yml') + 
    glob.glob('inventories/**/group_vars/*.yml', recursive=True)
)

errors = 0
for file_path in files:
    try:
        with open(file_path, 'r') as f:
            yaml.safe_load(f)
        print(f'✅ {file_path}')
    except yaml.YAMLError as e:
        print(f'❌ {file_path}: {e}')
        errors += 1
    except Exception as e:
        print(f'❌ {file_path}: {e}')
        errors += 1

if errors > 0:
    print(f'Found {errors} YAML errors')
    sys.exit(1)
else:
    print('All YAML files are valid')
"; then
            log_success "YAML syntax check passed"
        else
            log_error "YAML syntax check failed"
            return 1
        fi
    else
        if yamllint playbooks/ roles/ group_vars/ inventories/ 2>/dev/null; then
            log_success "YAML lint passed"
        else
            log_error "YAML lint failed"
            return 1
        fi
    fi
}

run_ansible_syntax() {
    increment_total
    log_info "Running Ansible syntax checks..."
    
    local failed_playbooks=()
    
    for playbook in playbooks/*.yml; do
        if [[ -f "$playbook" ]]; then
            log_info "Checking syntax: $playbook"
            if ansible-playbook --syntax-check -i "$ANSIBLE_INVENTORY" "$playbook" &>/dev/null; then
                log_success "$(basename "$playbook") syntax OK"
            else
                log_error "$(basename "$playbook") syntax FAILED"
                failed_playbooks+=("$playbook")
            fi
        fi
    done
    
    if [[ ${#failed_playbooks[@]} -eq 0 ]]; then
        log_success "All playbooks passed syntax check"
        return 0
    else
        log_error "Failed playbooks: ${failed_playbooks[*]}"
        return 1
    fi
}

run_ansible_lint() {
    increment_total
    log_info "Running Ansible lint..."
    
    if ! command -v ansible-lint &> /dev/null; then
        log_warning "ansible-lint not available, skipping..."
        return 0
    fi
    
    if ansible-lint playbooks/ roles/ 2>/dev/null; then
        log_success "Ansible lint passed"
    else
        log_error "Ansible lint failed"
        return 1
    fi
}

run_inventory_validation() {
    increment_total
    log_info "Validating inventories..."
    
    local failed_inventories=()
    
    for env in dev prod staging; do
        local inventory_path="inventories/$env"
        if [[ -d "$inventory_path" ]]; then
            log_info "Validating $env inventory..."
            if ansible-inventory -i "$inventory_path" --list > /dev/null 2>&1; then
                log_success "$env inventory is valid"
            else
                log_error "$env inventory validation failed"
                failed_inventories+=("$env")
            fi
        fi
    done
    
    if [[ ${#failed_inventories[@]} -eq 0 ]]; then
        log_success "All inventories are valid"
        return 0
    else
        log_error "Failed inventories: ${failed_inventories[*]}"
        return 1
    fi
}

run_security_checks() {
    increment_total
    log_info "Running security checks..."
    
    local issues_found=0
    
    # Check for hardcoded passwords
    log_info "Checking for hardcoded passwords..."
    if grep -r -n "password.*:" playbooks/ roles/ --include="*.yml" --include="*.yaml" | grep -v "cloud_init_password.*ubuntu" | grep -v "#" > /dev/null; then
        log_error "Potential hardcoded passwords found!"
        grep -r -n "password.*:" playbooks/ roles/ --include="*.yml" --include="*.yaml" | grep -v "cloud_init_password.*ubuntu" | grep -v "#" || true
        ((issues_found++))
    fi
    
    # Check for SSH keys in code
    log_info "Checking for embedded SSH keys..."
    if grep -r -n "-----BEGIN.*PRIVATE KEY-----" playbooks/ roles/ --include="*.yml" --include="*.yaml" > /dev/null; then
        log_error "Private keys found in code!"
        ((issues_found++))
    fi
    
    # Check for suspicious patterns
    log_info "Checking for suspicious patterns..."
    if grep -r -i -n "todo.*password\|fixme.*password" playbooks/ roles/ --include="*.yml" --include="*.yaml" > /dev/null; then
        log_warning "TODO/FIXME comments about passwords found"
    fi
    
    if [[ $issues_found -eq 0 ]]; then
        log_success "No security issues found"
        return 0
    else
        log_error "$issues_found security issues found"
        return 1
    fi
}

run_functional_tests() {
    increment_total
    log_info "Running functional validation tests..."
    
    if ansible-playbook -i "$ANSIBLE_INVENTORY" playbooks/validate-config.yml > /dev/null 2>&1; then
        log_success "Validation tests passed"
        return 0
    else
        log_error "Validation tests failed"
        return 1
    fi
}

show_summary() {
    echo
    echo "=============================================="
    echo -e "${BLUE}📊 LINT SUMMARY${NC}"
    echo "=============================================="
    echo -e "Total checks: ${CHECKS_TOTAL}"
    echo -e "${GREEN}Passed: ${CHECKS_PASSED}${NC}"
    echo -e "${RED}Failed: ${CHECKS_FAILED}${NC}"
    echo
    
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All checks passed! Your Ansible code is ready for deployment.${NC}"
        return 0
    else
        echo -e "${RED}💥 Some checks failed. Please fix the issues before proceeding.${NC}"
        return 1
    fi
}

main() {
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Parse arguments
    local syntax_only=false
    local install_deps=false
    local run_tests=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --syntax-only)
                syntax_only=true
                shift
                ;;
            --install-deps)
                install_deps=true
                shift
                ;;
            --no-color)
                export NO_COLOR=1
                shift
                ;;
            --verbose)
                set -x
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 2
                ;;
        esac
    done
    
    # Disable colors if requested
    if [[ -n "${NO_COLOR:-}" ]]; then
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        NC=''
    fi
    
    echo -e "${BLUE}🚀 Ansible Lint Pipeline${NC}"
    echo "======================================"
    
    # Install dependencies if requested
    if [[ "$install_deps" == true ]]; then
        install_dependencies
    fi
    
    # Check dependencies
    check_dependencies || exit 2
    
    # Run checks
    local exit_code=0
    
    run_yaml_lint || exit_code=1
    run_ansible_syntax || exit_code=1
    run_inventory_validation || exit_code=1
    
    if [[ "$syntax_only" == false ]]; then
        run_ansible_lint || exit_code=1
        run_security_checks || exit_code=1
        if [[ "$run_tests" == true ]]; then
            run_functional_tests || exit_code=1
        fi
    fi
    
    # Show summary
    show_summary || exit_code=1
    
    exit $exit_code
}

# Run main function
main "$@"
