#!/bin/bash
# ============================================================================
# Collection Conflict Fix Script
# ============================================================================
# This script resolves common Ansible collection conflicts
# 
# Usage: ./scripts/fix-collections.sh
# ============================================================================

set -e

echo "🔧 Fixing Ansible Collection Conflicts..."

# Check if we have conflicting versions
echo "🔍 Checking for collection conflicts..."
if ansible-galaxy collection list | grep -q "community.general.*11\|community.general.*1\."; then
    echo "⚠️  Multiple versions of community.general detected!"
    
    # Show current versions
    echo "📋 Current installations:"
    ansible-galaxy collection list | grep community.general || true
    
    echo ""
    echo "🧹 Cleaning up conflicting versions..."
    
    # Remove all versions to start clean
    rm -rf ~/.ansible/collections/ansible_collections/community/general || true
    
    # Also clean system-wide if needed (requires sudo)
    if [ -d "/usr/share/ansible/collections/ansible_collections/community/general" ]; then
        echo "🔑 System-wide collections detected. You may need to run:"
        echo "   sudo rm -rf /usr/share/ansible/collections/ansible_collections/community/general"
        echo ""
    fi
    
    # Install a specific stable version
    echo "📦 Installing stable version of community.general..."
    ansible-galaxy collection install community.general:==9.4.0 --force
    
    # Install other required collections
    echo "📦 Installing other required collections..."
    ansible-galaxy collection install community.libvirt --force
    ansible-galaxy collection install ansible.posix --force
    ansible-galaxy collection install community.crypto --force
    
    echo ""
    echo "✅ Collection cleanup complete!"
    
else
    echo "✅ No collection conflicts detected!"
fi

# Verify final state
echo ""
echo "📊 Final collection status:"
ansible-galaxy collection list | grep -E "(community\.|ansible\.)" || echo "No matching collections found"

echo ""
echo "🧪 Testing configuration..."
if ansible-playbook playbooks/validate-config.yml 2>&1 | grep -q "unhashable type"; then
    echo "❌ Still experiencing issues. Manual cleanup may be required:"
    echo "   1. Check: ansible --version"
    echo "   2. Check: python3 --version" 
    echo "   3. Consider upgrading Ansible: pip3 install --upgrade ansible"
else
    echo "✅ Collections working correctly!"
fi

echo ""
echo "🎉 Fix script complete!"
echo "   If issues persist, try: pip3 install --upgrade ansible-core"
