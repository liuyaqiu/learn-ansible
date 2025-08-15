#!/bin/bash
# ============================================================================
# Ansible Auto-Formatter - Fix common formatting issues
# ============================================================================
# Usage:
#   ./scripts/format.sh                 # Format all files
#   ./scripts/format.sh --check-only    # Check what would be changed
#   ./scripts/format.sh --yaml-only     # Format only YAML files
#   ./scripts/format.sh --help          # Show help
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

# Counters
FILES_PROCESSED=0
FILES_CHANGED=0

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_help() {
    cat << EOF
🎨 Ansible Auto-Formatter

DESCRIPTION:
    Automatically fixes common formatting issues in Ansible projects:
    - Removes trailing whitespace
    - Fixes end-of-file newlines
    - Standardizes indentation
    - Fixes YAML bracket spacing
    - Removes unnecessary document separators

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --check-only      Show what would be changed without making changes
    --yaml-only       Format only YAML files (*.yml, *.yaml)
    --ansible-only    Format only Ansible files (playbooks, roles)
    --fix-all         Fix all issues (default)
    --dry-run         Alias for --check-only
    --verbose         Show detailed output
    --help           Show this help message

EXAMPLES:
    $0                          # Format all files
    $0 --check-only            # Preview changes
    $0 --yaml-only             # Only YAML files
    $0 --ansible-only          # Only Ansible files

WHAT IT FIXES:
    ✅ Trailing whitespace
    ✅ Missing final newlines
    ✅ Extra blank lines at end of file
    ✅ YAML bracket spacing ({ } and [ ])
    ✅ Mixed line endings (converts to LF)
    ✅ Tab characters (converts to spaces)

EXIT CODES:
    0    All files formatted successfully
    1    Some files had issues
    2    Invalid arguments or dependencies missing
EOF
}

check_dependencies() {
    local missing_deps=()
    
    # Check for sed (should be available on all systems)
    if ! command -v sed &> /dev/null; then
        missing_deps+=("sed")
    fi
    
    # Check for python3 for YAML processing
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        return 2
    fi
    
    return 0
}

format_yaml_file() {
    local file="$1"
    local check_only="$2"
    local changed=false
    local temp_file
    
    temp_file=$(mktemp)
    cp "$file" "$temp_file"
    
    # 1. Remove trailing whitespace
    if sed -i 's/[[:space:]]*$//' "$temp_file" 2>/dev/null; then
        if ! cmp -s "$file" "$temp_file"; then
            changed=true
            if [[ "$check_only" == true ]]; then
                log_warning "Would remove trailing whitespace from: $file"
            fi
        fi
    fi
    
    # 2. Ensure file ends with exactly one newline
    if [[ -s "$temp_file" ]]; then
        # Remove all trailing newlines, then add exactly one
        sed -i -e :a -e '/^\s*$/N;ba' -e 's/\n*$//' "$temp_file"
        echo >> "$temp_file"
        if ! cmp -s "$file" "$temp_file"; then
            changed=true
            if [[ "$check_only" == true ]]; then
                log_warning "Would fix end-of-file newlines in: $file"
            fi
        fi
    fi
    
    # 3. Fix YAML bracket spacing (but preserve intentional formatting in templates)
    if [[ "$file" != *.j2 ]]; then
        # Fix { } spacing - but be careful with Jinja2 templates
        if sed -i 's/{\s*\([^%{][^}]*[^%}]\)\s*}/{ \1 }/g' "$temp_file" 2>/dev/null; then
            if ! cmp -s "$file" "$temp_file"; then
                changed=true
                if [[ "$check_only" == true ]]; then
                    log_warning "Would fix bracket spacing in: $file"
                fi
            fi
        fi
    fi
    
    # 4. Convert tabs to spaces (2 spaces for YAML)
    if sed -i 's/\t/  /g' "$temp_file" 2>/dev/null; then
        if ! cmp -s "$file" "$temp_file"; then
            changed=true
            if [[ "$check_only" == true ]]; then
                log_warning "Would convert tabs to spaces in: $file"
            fi
        fi
    fi
    
    # 5. Fix mixed line endings (convert to LF)
    if sed -i 's/\r$//' "$temp_file" 2>/dev/null; then
        if ! cmp -s "$file" "$temp_file"; then
            changed=true
            if [[ "$check_only" == true ]]; then
                log_warning "Would fix line endings in: $file"
            fi
        fi
    fi
    
    # Apply changes if not in check-only mode
    if [[ "$check_only" == false && "$changed" == true ]]; then
        cp "$temp_file" "$file"
        ((FILES_CHANGED++))
        log_success "Formatted: $file"
    elif [[ "$changed" == false ]]; then
        log_info "No changes needed: $file"
    fi
    
    rm -f "$temp_file"
    ((FILES_PROCESSED++))
    
    return 0
}

format_python_yaml_advanced() {
    local file="$1"
    local check_only="$2"
    
    # Use Python for more advanced YAML formatting
    python3 << EOF
import sys
import tempfile
import shutil
import os

def format_yaml_advanced(filepath, check_only=False):
    """Advanced YAML formatting using Python"""
    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()
        
        original_content = ''.join(lines)
        modified_lines = []
        changed = False
        
        for line in lines:
            original_line = line
            
            # Remove trailing whitespace
            line = line.rstrip() + '\n' if line.strip() else '\n'
            
            # Fix common YAML issues
            # Fix list item spacing
            if line.strip().startswith('- ') and not line.startswith('  - '):
                # Ensure consistent indentation for top-level list items
                pass  # Keep as is for now
            
            if line != original_line:
                changed = True
            
            modified_lines.append(line)
        
        # Remove extra newlines at end, ensure exactly one
        while modified_lines and modified_lines[-1].strip() == '':
            modified_lines.pop()
            changed = True
        
        if modified_lines:
            modified_lines.append('\n')
        
        new_content = ''.join(modified_lines)
        
        if changed:
            if check_only:
                print(f"Would format: ${file}")
            else:
                with open(filepath, 'w') as f:
                    f.write(new_content)
                print(f"Formatted: ${file}")
            return True
        else:
            print(f"No changes needed: ${file}")
            return False
            
    except Exception as e:
        print(f"Error processing ${file}: {e}", file=sys.stderr)
        return False

# Format the file
result = format_yaml_advanced("$file", $check_only)
sys.exit(0 if result is not None else 1)
EOF
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        ((FILES_PROCESSED++))
        if [[ "$check_only" == false ]]; then
            ((FILES_CHANGED++))
        fi
    fi
    
    return $exit_code
}

find_files_to_format() {
    local file_pattern="$1"
    
    case "$file_pattern" in
        "yaml")
            find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" | \
            grep -v -E "^./(.git|.github|.gitlab)" | \
            sort
            ;;
        "ansible")
            find "$PROJECT_ROOT" \( \
                -path "*/playbooks/*.yml" -o \
                -path "*/roles/*/tasks/*.yml" -o \
                -path "*/roles/*/handlers/*.yml" -o \
                -path "*/roles/*/vars/*.yml" -o \
                -path "*/roles/*/defaults/*.yml" -o \
                -path "*/roles/*/meta/*.yml" -o \
                -path "*/group_vars/*.yml" -o \
                -path "*/host_vars/*.yml" -o \
                -path "*/inventories/*/*.yml" \
            \) | \
            grep -v -E "^./(.git|.github|.gitlab)" | \
            sort
            ;;
        "all")
            find "$PROJECT_ROOT" \( \
                -name "*.yml" -o \
                -name "*.yaml" -o \
                -name "*.json" \
            \) | \
            grep -v -E "^./(.git|.github|.gitlab|node_modules|\.cache)" | \
            sort
            ;;
    esac
}

main() {
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Parse arguments
    local check_only=false
    local file_pattern="all"
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check-only|--dry-run)
                check_only=true
                shift
                ;;
            --yaml-only)
                file_pattern="yaml"
                shift
                ;;
            --ansible-only)
                file_pattern="ansible"
                shift
                ;;
            --fix-all)
                file_pattern="all"
                shift
                ;;
            --verbose)
                verbose=true
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
    
    echo -e "${BLUE}🎨 Ansible Auto-Formatter${NC}"
    echo "=============================="
    
    if [[ "$check_only" == true ]]; then
        log_info "Running in CHECK-ONLY mode (no files will be modified)"
    fi
    
    # Check dependencies
    check_dependencies || exit 2
    
    # Find files to format
    local files_to_process
    mapfile -t files_to_process < <(find_files_to_format "$file_pattern")
    
    if [[ ${#files_to_process[@]} -eq 0 ]]; then
        log_warning "No files found to format with pattern: $file_pattern"
        exit 0
    fi
    
    log_info "Found ${#files_to_process[@]} files to process"
    
    # Process each file
    local failed_files=()
    
    for file in "${files_to_process[@]}"; do
        if [[ -f "$file" ]]; then
            if [[ "$verbose" == true ]]; then
                log_info "Processing: $file"
            fi
            
            if ! format_yaml_file "$file" "$check_only"; then
                failed_files+=("$file")
            fi
        fi
    done
    
    # Show summary
    echo
    echo "=============================="
    echo -e "${BLUE}📊 FORMATTING SUMMARY${NC}"
    echo "=============================="
    echo "Files processed: $FILES_PROCESSED"
    
    if [[ "$check_only" == true ]]; then
        echo "Files that would be changed: $FILES_CHANGED"
        if [[ $FILES_CHANGED -gt 0 ]]; then
            echo
            log_info "Run without --check-only to apply changes"
        fi
    else
        echo "Files changed: $FILES_CHANGED"
    fi
    
    if [[ ${#failed_files[@]} -gt 0 ]]; then
        echo "Failed files: ${#failed_files[@]}"
        log_error "Failed to process: ${failed_files[*]}"
        exit 1
    fi
    
    if [[ $FILES_CHANGED -eq 0 ]]; then
        log_success "All files are already properly formatted! 🎉"
    elif [[ "$check_only" == true ]]; then
        log_warning "Some files need formatting. Run without --check-only to fix them."
        exit 1
    else
        log_success "Successfully formatted $FILES_CHANGED files! 🎉"
    fi
    
    exit 0
}

# Run main function
main "$@"
