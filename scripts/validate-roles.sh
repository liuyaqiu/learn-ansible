#!/bin/bash
# Pre-commit hook for role structure validation  
set -e

echo "🎭 Validating role structures..."

for role_dir in roles/*/; do
    if [[ -d "$role_dir" ]]; then
        role_name=$(basename "$role_dir")
        echo "Checking role: $role_name"
        
        # Check for required directories
        required_dirs=("tasks" "vars")
        for dir in "${required_dirs[@]}"; do
            if [[ ! -d "$role_dir/$dir" ]]; then
                echo "❌ Missing required directory: $role_dir/$dir"
                exit 1
            fi
        done
        
        # Check for main.yml files
        required_files=("tasks/main.yml" "vars/main.yml")
        for file in "${required_files[@]}"; do
            if [[ ! -f "$role_dir/$file" ]]; then
                echo "❌ Missing required file: $role_dir/$file"
                exit 1
            fi
        done
    fi
done

echo "✅ All role structures validated"
