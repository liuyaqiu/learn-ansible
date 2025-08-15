#!/bin/bash
# Pre-commit hook for Ansible syntax checking
set -e

echo "🔍 Running Ansible syntax checks..."

for playbook in playbooks/*.yml; do
    if [[ -f "$playbook" ]]; then
        echo "Checking: $playbook"
        ansible-playbook --syntax-check -i inventories/dev "$playbook"
    fi
done

echo "✅ All syntax checks passed"
