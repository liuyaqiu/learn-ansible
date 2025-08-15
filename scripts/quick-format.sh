#!/bin/bash
# ============================================================================
# Quick Ansible Formatter - Fast and Simple
# ============================================================================
# Usage: ./scripts/quick-format.sh [--check-only]
# ============================================================================

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_ONLY=false

# Parse arguments
if [[ "${1:-}" == "--check-only" ]]; then
    CHECK_ONLY=true
fi

cd "$PROJECT_ROOT"

echo -e "${BLUE}🚀 Quick Ansible Formatter${NC}"
echo "============================="

if [[ "$CHECK_ONLY" == true ]]; then
    echo -e "${YELLOW}ℹ️  CHECK-ONLY mode${NC}"
fi

# Find YAML files
FILES=$(find . -name "*.yml" -o -name "*.yaml" | grep -v -E "^./(.git|node_modules)" | sort)
TOTAL_FILES=$(echo "$FILES" | wc -l)
CHANGED=0

echo -e "${BLUE}ℹ️  Processing $TOTAL_FILES files...${NC}"

# Process each file
for file in $FILES; do
    if [[ -f "$file" ]]; then
        # Check if file needs changes
        NEEDS_CHANGE=false
        
        # Check for trailing whitespace
        if grep -q '[[:space:]]$' "$file" 2>/dev/null; then
            NEEDS_CHANGE=true
        fi
        
        # Check for missing final newline
        if [[ -s "$file" && $(tail -c1 "$file" | wc -l) -eq 0 ]]; then
            NEEDS_CHANGE=true
        fi
        
        if [[ "$NEEDS_CHANGE" == true ]]; then
            if [[ "$CHECK_ONLY" == true ]]; then
                echo -e "${YELLOW}Would fix: $file${NC}"
            else
                # Remove trailing whitespace
                sed -i 's/[[:space:]]*$//' "$file"
                
                # Ensure file ends with newline
                if [[ -s "$file" ]]; then
                    sed -i -e '$a\' "$file"
                fi
                
                echo -e "${GREEN}✅ Fixed: $file${NC}"
            fi
            ((CHANGED++))
        fi
    fi
done

echo "============================="
echo -e "${BLUE}📊 Summary:${NC}"
echo "Files processed: $TOTAL_FILES"

if [[ "$CHECK_ONLY" == true ]]; then
    echo "Files needing changes: $CHANGED"
    if [[ $CHANGED -gt 0 ]]; then
        echo -e "${YELLOW}Run without --check-only to apply fixes${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ All files are properly formatted!${NC}"
    fi
else
    echo "Files changed: $CHANGED"
    if [[ $CHANGED -gt 0 ]]; then
        echo -e "${GREEN}✅ Successfully formatted $CHANGED files!${NC}"
    else
        echo -e "${GREEN}✅ All files were already properly formatted!${NC}"
    fi
fi
