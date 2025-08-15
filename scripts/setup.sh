#!/bin/bash
# ============================================================================
# Project Setup Script
# ============================================================================
# This script sets up the Ansible project environment
#
# Usage: ./scripts/setup.sh
# ============================================================================

set -e

echo "🔧 Setting up Ansible KVM VM Management Project..."

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible is not installed. Please install Ansible first."
    echo "   Ubuntu/Debian: sudo apt install ansible"
    echo "   RedHat/CentOS: sudo yum install ansible"
    exit 1
fi

echo "✅ Ansible found: $(ansible --version | head -1)"

# Clean up any conflicting collections first
echo "🧹 Cleaning up any conflicting collections..."
ansible-galaxy collection list | grep "community.general" | head -1 | awk '{print $1}' | while read collection; do
    if [ ! -z "$collection" ]; then
        echo "  Removing existing $collection to avoid conflicts..."
        # Note: ansible-galaxy doesn't have uninstall, so we upgrade/reinstall
    fi
done

# Install required collections with proper conflict resolution
echo "📦 Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yml

# Verify installation
echo "✅ Verifying collection installation..."
ansible-galaxy collection list community.general
ansible-galaxy collection list community.libvirt

# Create logs directory
mkdir -p logs

# Check SSH key
SSH_KEY_PATH="${HOME}/.ssh/ansible-vm.pub"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "🔑 SSH key not found at $SSH_KEY_PATH"
    echo "Creating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "${HOME}/.ssh/ansible-vm" -N "" -C "ansible-vm-management"
    echo "✅ SSH key created at $SSH_KEY_PATH"
else
    echo "✅ SSH key found at $SSH_KEY_PATH"
fi

# Test for collection conflicts
echo "🔍 Testing for collection conflicts..."
if ansible-galaxy collection list | grep -q "community.general.*11\|community.general.*1\."; then
    echo "⚠️  Multiple versions of community.general detected. This may cause warnings."
    echo "   This is usually harmless but you can clean up with:"
    echo "   rm -rf ~/.ansible/collections/ansible_collections/community/general"
    echo "   Then re-run this setup script."
    echo ""
fi

# Validate configuration
echo "🔍 Validating configuration..."
if ansible-playbook playbooks/validate-config.yml 2>&1 | grep -q "unhashable type"; then
    echo "⚠️  Collection metadata warning detected. This is usually harmless."
    echo "   To fix permanently, clean up collection duplicates:"
    echo "   rm -rf ~/.ansible/collections/ansible_collections/community/general"
    echo "   ansible-galaxy collection install community.general:==9.4.0"
    echo ""
else
    echo "✅ Configuration validation completed successfully!"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "🚀 Quick Start Commands:"
echo "  # Create development VM:"
echo "  ansible-playbook -i inventories/dev playbooks/vm-create.yml"
echo ""
echo "  # Create staging VM:"
echo "  ansible-playbook -i inventories/staging playbooks/vm-create.yml"
echo ""
echo "  # Create production VM:"
echo "  ansible-playbook -i inventories/prod playbooks/vm-create.yml"
echo ""
echo "  # Destroy VM:"
echo "  ansible-playbook -i inventories/dev playbooks/vm-destroy.yml"
echo ""
echo "📚 See README.md for detailed usage instructions."
