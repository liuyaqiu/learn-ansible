#!/bin/bash
# Pre-commit hook for inventory validation
set -e

echo "📋 Validating inventories..."

for env in dev prod staging; do
    if [[ -d "inventories/$env" ]]; then
        echo "Validating $env inventory..."
        ansible-inventory -i "inventories/$env" --list > /dev/null
    fi
done

echo "✅ All inventories validated"
