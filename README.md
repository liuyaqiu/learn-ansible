# KVM Virtual Machine Management with Ansible

A professional-grade Ansible project for complete KVM virtual machine lifecycle management, following enterprise best practices and scalable architecture patterns.

## 🏗️ Project Architecture

This project demonstrates **enterprise-level Ansible practices** including:

- ✅ **Role-based architecture** for reusable components
- ✅ **Multi-environment support** (dev/staging/prod)
- ✅ **Centralized configuration management**
- ✅ **Comprehensive validation and error handling**
- ✅ **Professional project structure** following Ansible best practices

## 📁 Project Structure

```
ansible-kvm-management/
├── 📚 roles/                          # Reusable Ansible roles
│   └── kvm-vm/                       # KVM VM management role
│       ├── tasks/                    # Role tasks
│       ├── templates/                # Jinja2 templates (cloud-init)
│       ├── vars/                     # Internal role variables
│       ├── handlers/                 # Event handlers
│       └── meta/                     # Role metadata
├── 📖 playbooks/                     # Orchestration playbooks
│   ├── site.yml                     # Main entry point
│   ├── vm-create.yml                # VM creation workflow
│   ├── vm-destroy.yml               # VM cleanup workflow
│   └── validate-config.yml          # Configuration validation
├── 🗂️ inventories/                   # Environment management
│   ├── dev/                         # Development environment
│   │   ├── hosts                    # Development inventory
│   │   └── group_vars/              # Dev-specific variables
│   │       ├── all.yml ➜ ../../../group_vars/all.yml  # Shared config (symlink)
│   │       └── dev.yml              # Development overrides
│   ├── staging/                     # Staging environment
│   │   ├── hosts                    # Staging inventory
│   │   └── group_vars/              # Staging-specific variables
│   │       ├── all.yml ➜ ../../../group_vars/all.yml  # Shared config (symlink)
│   │       └── staging.yml          # Staging overrides
│   └── prod/                        # Production environment
│       ├── hosts                    # Production inventory
│       └── group_vars/              # Prod-specific variables
│           ├── all.yml ➜ ../../../group_vars/all.yml  # Shared config (symlink)
│           └── prod.yml             # Production overrides
├── 📋 group_vars/                   # Shared configuration
│   └── all.yml                     # Single source of truth (SSH keys, base VM settings)
├── 🔧 Configuration Files
│   ├── ansible.cfg                  # Ansible configuration
│   ├── requirements.yml             # Dependencies
│   └── .gitignore                   # Git exclusions
├── 📜 scripts/                      # Utility scripts
│   └── setup.sh                    # Environment setup
├── 📊 logs/                         # Ansible execution logs
└── 📖 docs/                         # Additional documentation
```

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Clone and setup
git clone <repository-url>
cd ansible-kvm-management

# Run setup script
./scripts/setup.sh
```

The setup script will:

- Install required Ansible collections
- Generate SSH keys if needed
- Validate configuration
- Display usage examples

### 2. Create Your First VM

```bash
# Development VM (1GB RAM, dev tools)
ansible-playbook -i inventories/dev playbooks/vm-create.yml

# Staging VM (2GB RAM, moderate resources)
ansible-playbook -i inventories/staging playbooks/vm-create.yml

# Production VM (4GB RAM, security tools)
ansible-playbook -i inventories/prod playbooks/vm-create.yml
```

### 3. Connect to Your VM

```bash
# SSH into the VM (key path and IP are environment-specific)
ssh -i ~/.ssh/ansible-vm ubuntu@192.168.122.110  # Dev
ssh -i ~/.ssh/ansible-vm ubuntu@192.168.122.150  # Staging
ssh -i ~/.ssh/ansible-vm ubuntu@192.168.122.200  # Prod
```

### 4. Clean Up When Done

```bash
# Remove VM and all associated files
ansible-playbook -i inventories/dev playbooks/vm-destroy.yml
```

## ⚙️ Configuration Management

### Environment-Specific Settings

Each environment has its own configuration profile:

| Environment     | VM Name      | Memory  | vCPUs | Disk  | IP Address | Packages                       |
| --------------- | ------------ | ------- | ----- | ----- | ---------- | ------------------------------ |
| **Development** | `dev-vm`     | 1024 MB | 1     | 10 GB | .110       | Dev tools (htop, tree, pip)    |
| **Staging**     | `staging-vm` | 2048 MB | 2     | 30 GB | .150       | Testing tools                  |
| **Production**  | `prod-vm`    | 4096 MB | 2     | 50 GB | .200       | Security tools (fail2ban, ufw) |

### Configuration Architecture

This project uses a **consolidated configuration approach** to eliminate duplication and ensure consistency:

#### Configuration Hierarchy (highest to lowest precedence):

1. **Runtime variables**: `-e "var=value"` command line overrides
2. **Environment-specific**: `inventories/{env}/group_vars/{env}.yml`
3. **Shared configuration**: `group_vars/all.yml` (single source of truth)
4. **Playbook-level variables**: Explicitly passed to roles via `vars:` sections

#### File Structure:

- **📁 Master configuration**: `group_vars/all.yml`
  - Contains SSH keys, base VM settings, templates, packages
  - Single source of truth for all shared variables
- **🔗 Symbolic links**: `inventories/*/group_vars/all.yml` ➜ `../../../group_vars/all.yml`
  - Each environment links to the master configuration
  - Eliminates duplicate files while maintaining Ansible's expected structure
- **⚙️ Environment overrides**: `inventories/*/group_vars/{dev,staging,prod}.yml`
  - Environment-specific settings (VM size, IP ranges, packages)
  - Inherits from shared config, overrides specific values
- **🔧 Role variables**: `roles/kvm-vm/vars/main.yml`
  - Contains internal role logic and computed paths
  - Used for role implementation details only

> **✅ Benefits**: No duplicate configurations, consistent SSH key paths, eliminated variable conflicts between role defaults and group variables.

### Customizing Configuration

1. **Edit shared configuration** (affects all environments):

   ```bash
   # Edit shared settings (SSH keys, base VM config, etc.)
   vi group_vars/all.yml
   ```

2. **Override for specific environment**:

   ```bash
   # Edit environment-specific settings
   vi inventories/dev/group_vars/dev.yml
   ```

3. **Runtime overrides**:

   ```bash
   # Override VM name for one-time use
   ansible-playbook -i inventories/dev playbooks/vm-create.yml -e "vm_name=test-vm-123"
   ```

4. **Add new environment**:

   ```bash
   # Copy existing environment structure
   cp -r inventories/dev inventories/test

   # Create symbolic link to shared configuration
   cd inventories/test/group_vars
   ln -sf ../../../group_vars/all.yml all.yml

   # Customize environment-specific settings
   vi inventories/test/group_vars/test.yml
   ```

## 🎯 Advanced Usage

### Playbook Options

#### Main Site Playbook

```bash
# Default: create/ensure VM present
ansible-playbook -i inventories/dev playbooks/site.yml

# Specific lifecycle state
ansible-playbook -i inventories/dev playbooks/site.yml -e "vm_lifecycle_state=absent"

# Information only
ansible-playbook -i inventories/dev playbooks/site.yml --tags info
```

#### Specialized Playbooks

```bash
# VM creation with SSH validation
ansible-playbook -i inventories/dev playbooks/vm-create.yml

# VM destruction with safety prompts
ansible-playbook -i inventories/dev playbooks/vm-destroy.yml

# Configuration validation only
ansible-playbook -i inventories/dev playbooks/validate-config.yml
```

### Role Usage

The `kvm-vm` role can be used in your own playbooks:

```yaml
- name: Manage KVM VM
  hosts: localhost
  roles:
    - role: kvm-vm
      vars:
        kvm_vm_name: "my-custom-vm"
        kvm_vm_state: present # present, absent, running, stopped
        kvm_vm_memory: 2048
        kvm_vm_vcpus: 2
        kvm_force_recreate: false
```

### Debugging and Troubleshooting

#### General Debugging

```bash
# Verbose output
ansible-playbook -i inventories/dev playbooks/site.yml -vvv

# Dry run (check mode)
ansible-playbook -i inventories/dev playbooks/site.yml --check --diff

# List tasks without execution
ansible-playbook -i inventories/dev playbooks/site.yml --list-tasks

# Check Ansible logs
tail -f logs/ansible.log
```

#### SSH Key Troubleshooting

```bash
# Check if SSH key variables are loaded correctly
ansible localhost -i inventories/dev -m debug -a "var=ssh_key_path"
ansible localhost -i inventories/dev -m debug -a "var=kvm_ssh_key_path"

# Verify SSH key files exist and are accessible
ls -la ~/.ssh/ansible-vm*
sudo ls -la /root/.ssh/  # Should NOT contain your keys

# Test SSH key accessibility
cat "$(ansible localhost -i inventories/dev -m debug -a 'var=ssh_key_path' | grep ssh_key_path | cut -d'"' -f4)"

# Run validation specifically
ansible-playbook -i inventories/dev playbooks/validate-config.yml
```

#### Common Issues and Solutions

| Issue                  | Symptom                                                   | Solution                                                           |
| ---------------------- | --------------------------------------------------------- | ------------------------------------------------------------------ |
| **SSH key not found**  | `❌ SSH public key file not found: /root/.ssh/id_rsa.pub` | Update `ssh_key_path` in `group_vars/all.yml` to correct user path |
| **Variable undefined** | `'ssh_key_path' is undefined`                             | Check symbolic links: `ls -la inventories/*/group_vars/all.yml`    |
| **Permission denied**  | SSH key exists but not accessible                         | Fix file permissions: `chmod 600 ~/.ssh/ansible-vm*`               |
| **Wrong key path**     | Using default `/root/.ssh/` paths                         | Remove conflicting variables from role defaults                    |

## 🛡️ Security Best Practices

### SSH Key Management

#### Initial Setup

```bash
# Generate dedicated SSH key for VMs (if not already created)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible-vm -C "ansible-vm-management"

# Update key paths in the shared configuration
vi group_vars/all.yml
```

#### Configuration Variables

```yaml
# SSH Key Paths in group_vars/all.yml
ssh_key_path: /home/yourusername/.ssh/ansible-vm.pub # Public key for cloud-init
ssh_private_key_path: /home/yourusername/.ssh/ansible-vm # Private key for SSH connections

# Role-compatible variables (automatically mapped)
kvm_ssh_key_path: "{{ ssh_key_path }}"
kvm_ssh_private_key_path: "{{ ssh_private_key_path }}"
kvm_cloud_init_user: "{{ cloud_init_user }}"
kvm_cloud_init_password: "{{ cloud_init_password }}"
```

> **⚠️ Important**: Update the SSH key paths in `group_vars/all.yml` to match your actual key locations. All environments will inherit these settings automatically.

### Secrets Management

```bash
# Encrypt sensitive variables
ansible-vault create inventories/prod/group_vars/vault.yml

# Add encrypted passwords
cloud_init_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  66386439653162336464613265396538...

# Run with vault password
ansible-playbook -i inventories/prod playbooks/site.yml --ask-vault-pass
```

### Network Security

- Each environment uses different IP ranges
- Production includes security packages (fail2ban, ufw)
- SSH key-based authentication only
- No password authentication in production

## 🔧 Development and Customization

### Adding New VM Types

1. **Create new role variables**:

   ```yaml
   # roles/kvm-vm/defaults/main.yml
   kvm_vm_types:
     web_server:
       memory: 4096
       vcpus: 2
       packages: [nginx, php-fpm]
     database:
       memory: 8192
       vcpus: 4
       packages: [mysql-server, redis]
   ```

2. **Use in playbooks**:
   ```bash
   ansible-playbook playbooks/site.yml -e "vm_type=web_server"
   ```

### Extending the Role

The `kvm-vm` role is designed for extension:

- **Add new tasks**: `roles/kvm-vm/tasks/`
- **Custom templates**: `roles/kvm-vm/templates/`
- **Additional handlers**: `roles/kvm-vm/handlers/`
- **New variables**: `roles/kvm-vm/vars/`

### Integration with CI/CD

```yaml
# .github/workflows/vm-test.yml
name: VM Testing
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test VM Creation
        run: |
          ansible-playbook -i inventories/dev playbooks/validate-config.yml
          ansible-playbook -i inventories/dev playbooks/vm-create.yml --check
```

## 📋 Requirements

### System Requirements

- **Host OS**: Ubuntu 20.04+, Debian 11+, RHEL 8+
- **Memory**: 8GB+ (for running VMs)
- **Disk**: 50GB+ free space
- **CPU**: Hardware virtualization support (Intel VT-x/AMD-V)

### Software Dependencies

- **Ansible**: 2.9+
- **Python**: 3.8+
- **Collections**:
  - `community.libvirt` (1.0.0+)
  - `ansible.posix` (1.3.0+)
  - `community.general` (5.0.0+)

### KVM/Libvirt Stack

Automatically installed by the role:

- `qemu-kvm`
- `libvirt-daemon-system`
- `libvirt-clients`
- `virtinst`
- `cloud-image-utils`
- `python3-libvirt`

## 🏆 Best Practices Demonstrated

This project showcases professional Ansible development:

### 1. **Separation of Concerns**

- **Roles**: Reusable business logic
- **Playbooks**: Workflow orchestration
- **Inventories**: Environment management
- **Variables**: Configuration separation

### 2. **Scalability Patterns**

- Environment-specific overrides
- Role-based architecture
- Template-driven configuration
- Modular task organization

### 3. **Operational Excellence**

- Comprehensive validation
- Detailed logging and feedback
- Error handling and recovery
- Safety prompts for destructive operations

### 4. **Maintainability**

- Clear documentation
- Consistent naming conventions
- Logical file organization
- Automated setup processes

## 🔍 Validation and Testing

### Configuration Validation

The project includes comprehensive validation to catch issues early:

```bash
# Validate configuration before deployment
ansible-playbook -i inventories/dev playbooks/validate-config.yml

# Check specific environment
ansible-playbook -i inventories/prod playbooks/validate-config.yml

# What gets validated:
# ✅ SSH key accessibility (public and private keys)
# ✅ Required variables defined
# ✅ VM resource constraints within limits
# ✅ IP address availability
# ✅ Image directory permissions
# ✅ Role variable mappings
```

### Validation Output Example

```
✅ Configuration Validation Complete!

📊 Summary:
- All required variables: ✅ Valid
- Resource constraints: ✅ Within limits
- IP address format: ✅ Valid
- SSH key: ✅ Accessible (/home/user/.ssh/ansible-vm.pub)
- Package list: ✅ Configured
- Image directory: ✅ Accessible

🚀 Configuration is ready for deployment!
```

### Testing Workflow

1. **Validate configuration**
2. **Create VM in development**
3. **Test application deployment**
4. **Promote to staging**
5. **Production deployment**

## 🤝 Contributing

This project serves as a learning resource and template for:

- Ansible best practices
- KVM/Libvirt automation
- Infrastructure as Code patterns
- Multi-environment management

## 📚 Additional Resources

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [KVM/Libvirt Documentation](https://libvirt.org/docs.html)
- [Cloud-Init Documentation](https://cloud-init.readthedocs.io/)
- [Ansible Galaxy](https://galaxy.ansible.com/)

---

**This project demonstrates enterprise-grade Ansible practices suitable for production environments and serves as a comprehensive learning resource for infrastructure automation.** 🚀
