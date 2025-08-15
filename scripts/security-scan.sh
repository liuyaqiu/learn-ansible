#!/bin/bash
# Pre-commit hook for security scanning

echo "🛡️ Running security scans..."

# Check for hardcoded passwords (exclude Ansible variable references)
echo "Checking for hardcoded secrets..."
password_matches=$(grep -r -n "password.*:" playbooks/ roles/ --include="*.yml" --include="*.yaml" 2>/dev/null | grep -v "{{.*}}" | grep -v "#" || true)
if [[ -n "$password_matches" ]]; then
    echo "$password_matches"
    echo "❌ Potential hardcoded passwords found!"
    exit 1
fi

# Check for private keys
private_key_matches=$(grep -r -n "-----BEGIN.*PRIVATE KEY-----" playbooks/ roles/ --include="*.yml" --include="*.yaml" 2>/dev/null || true)
if [[ -n "$private_key_matches" ]]; then
    echo "$private_key_matches"
    echo "❌ Private keys found in code!"
    exit 1
fi

echo "✅ Security scan completed - no issues found"
