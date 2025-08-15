# ============================================================================
# Ansible Project Automation - CI/CD Ready
# ============================================================================
# Usage:
#   make lint          - Run all syntax and lint checks
#   make syntax        - Run syntax checks only
#   make test          - Run validation tests
#   make install-deps  - Install development dependencies
#   make clean         - Clean temporary files
# ============================================================================

# Project configuration
ANSIBLE_INVENTORY ?= inventories/dev
PLAYBOOK_DIR = playbooks
ROLE_DIR = roles
ANSIBLE_CONFIG = ansible.cfg

# Color output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)Ansible Project Automation$(NC)"
	@echo "=========================="
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-18s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Installation targets
.PHONY: install-deps
install-deps: ## Install development dependencies
	@echo "$(GREEN)Installing development dependencies...$(NC)"
	pip3 install --user ansible-lint yamllint pre-commit
	npm install -g prettier
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

.PHONY: check-deps
check-deps: ## Check if required tools are available
	@echo "$(GREEN)Checking dependencies...$(NC)"
	@command -v ansible-playbook >/dev/null 2>&1 || { echo "$(RED)❌ ansible-playbook not found$(NC)"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "$(RED)❌ python3 not found$(NC)"; exit 1; }
	@echo "$(GREEN)✅ Core dependencies available$(NC)"
	@command -v ansible-lint >/dev/null 2>&1 && echo "$(GREEN)✅ ansible-lint available$(NC)" || echo "$(YELLOW)⚠️  ansible-lint not found (run 'make install-deps')$(NC)"
	@command -v yamllint >/dev/null 2>&1 && echo "$(GREEN)✅ yamllint available$(NC)" || echo "$(YELLOW)⚠️  yamllint not found (run 'make install-deps')$(NC)"
	@command -v prettier >/dev/null 2>&1 && echo "$(GREEN)✅ prettier available$(NC)" || echo "$(YELLOW)⚠️  prettier not found (run 'make install-deps')$(NC)"
	@command -v pre-commit >/dev/null 2>&1 && echo "$(GREEN)✅ pre-commit available$(NC)" || echo "$(YELLOW)⚠️  pre-commit not found (run 'make install-deps')$(NC)"

# Formatting targets using mature tools
.PHONY: format
format: check-deps ## Auto-format all files using prettier and pre-commit
	@echo "$(GREEN)Auto-formatting files with prettier...$(NC)"
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --write "**/*.{yml,yaml,json,md}" --ignore-path .gitignore; \
		echo "$(GREEN)✅ Prettier formatting completed$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  prettier not found, using pre-commit...$(NC)"; \
		pre-commit run prettier --all-files || true; \
	fi

.PHONY: format-check
format-check: check-deps ## Check what files need formatting (dry-run)
	@echo "$(GREEN)Checking formatting with prettier...$(NC)"
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --check "**/*.{yml,yaml,json,md}" --ignore-path .gitignore || { \
			echo "$(YELLOW)Some files need formatting. Run 'make format' to fix.$(NC)"; \
			exit 1; \
		}; \
		echo "$(GREEN)✅ All files are properly formatted$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  prettier not found (run 'make install-deps')$(NC)"; \
		exit 1; \
	fi

.PHONY: format-yaml
format-yaml: check-deps ## Format only YAML files
	@echo "$(GREEN)Formatting YAML files with prettier...$(NC)"
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --write "**/*.{yml,yaml}" --ignore-path .gitignore; \
	else \
		echo "$(YELLOW)⚠️  prettier not found (run 'make install-deps')$(NC)"; \
	fi

.PHONY: format-precommit
format-precommit: ## Run all pre-commit formatters
	@echo "$(GREEN)Running pre-commit formatters...$(NC)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "$(YELLOW)⚠️  pre-commit not found (run 'make install-deps')$(NC)"; \
	fi

# Syntax checking targets
.PHONY: syntax
syntax: check-deps ## Run Ansible syntax checks on all playbooks
	@echo "$(GREEN)Running Ansible syntax checks...$(NC)"
	@for playbook in $(PLAYBOOK_DIR)/*.yml; do \
		echo "$(YELLOW)Checking $$playbook...$(NC)"; \
		ansible-playbook --syntax-check -i $(ANSIBLE_INVENTORY) "$$playbook" || exit 1; \
	done
	@echo "$(GREEN)✅ All playbooks passed syntax check$(NC)"

.PHONY: yaml-lint
yaml-lint: ## Run YAML linting
	@echo "$(GREEN)Running YAML lint checks...$(NC)"
	@if command -v yamllint >/dev/null 2>&1; then \
		yamllint $(PLAYBOOK_DIR)/ $(ROLE_DIR)/ group_vars/ inventories/ || exit 1; \
		echo "$(GREEN)✅ YAML lint passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  yamllint not available, using Python YAML parser...$(NC)"; \
		python3 -c "import yaml; import glob; [yaml.safe_load(open(f)) for f in glob.glob('$(PLAYBOOK_DIR)/*.yml') + glob.glob('$(ROLE_DIR)/**/tasks/*.yml', recursive=True) + glob.glob('group_vars/*.yml') + glob.glob('inventories/**/group_vars/*.yml', recursive=True)]; print('✅ All YAML files are valid')" || exit 1; \
	fi

.PHONY: ansible-lint
ansible-lint: ## Run ansible-lint if available
	@echo "$(GREEN)Running Ansible lint checks...$(NC)"
	@if command -v ansible-lint >/dev/null 2>&1; then \
		ansible-lint $(PLAYBOOK_DIR)/ $(ROLE_DIR)/ || exit 1; \
		echo "$(GREEN)✅ Ansible lint passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  ansible-lint not available (run 'make install-deps')$(NC)"; \
	fi

# Style fixing targets
.PHONY: fix-style
fix-style: check-deps ## Auto-fix style suggestions with ansible-lint
	@echo "$(GREEN)Auto-fixing style suggestions...$(NC)"
	@if command -v ansible-lint >/dev/null 2>&1; then \
		ansible-lint --fix=fqcn playbooks/ roles/ 2>/dev/null || true; \
		ansible-lint --fix=formatting playbooks/ roles/ 2>/dev/null || true; \
		echo "$(GREEN)✅ Style fixes applied$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  ansible-lint not found (run 'make install-deps')$(NC)"; \
	fi

.PHONY: fix-fqcn
fix-fqcn: check-deps ## Fix FQCN (Fully Qualified Collection Names) issues
	@echo "$(GREEN)Fixing FQCN issues...$(NC)"
	@if command -v ansible-lint >/dev/null 2>&1; then \
		ansible-lint --fix=fqcn playbooks/ roles/ 2>/dev/null || true; \
		echo "$(GREEN)✅ FQCN fixes applied$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  ansible-lint not found (run 'make install-deps')$(NC)"; \
	fi

.PHONY: fix-yaml
fix-yaml: check-deps ## Fix YAML formatting issues
	@echo "$(GREEN)Fixing YAML formatting...$(NC)"
	@if command -v ansible-lint >/dev/null 2>&1; then \
		ansible-lint --fix=yaml playbooks/ roles/ || true; \
		echo "$(GREEN)✅ YAML fixes applied$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  ansible-lint not found (run 'make install-deps')$(NC)"; \
	fi

# Comprehensive lint target
.PHONY: lint
lint: format-check syntax yaml-lint ansible-lint ## Run all syntax and lint checks
	@echo "$(GREEN)🎉 All lint checks completed successfully!$(NC)"

# Lint and auto-fix target
.PHONY: lint-fix
lint-fix: format syntax yaml-lint fix-style ## Auto-format then run all checks and fix styles
	@echo "$(GREEN)🎉 Files formatted and all lint checks completed!$(NC)"

# Complete auto-fix pipeline
.PHONY: fix-all
fix-all: format fix-style syntax yaml-lint ## Fix all formatting and style issues
	@echo "$(GREEN)🎉 All fixes applied! Running final check...$(NC)"
	@make lint || echo "$(YELLOW)Some suggestions may remain - check output above$(NC)"

# Testing targets
.PHONY: test-validate
test-validate: ## Run validation playbook
	@echo "$(GREEN)Running validation tests...$(NC)"
	ansible-playbook -i $(ANSIBLE_INVENTORY) $(PLAYBOOK_DIR)/validate-config.yml
	@echo "$(GREEN)✅ Validation tests passed$(NC)"

.PHONY: test-dry-run
test-dry-run: ## Run all playbooks in check mode
	@echo "$(GREEN)Running dry-run tests...$(NC)"
	@for playbook in $(PLAYBOOK_DIR)/validate-config.yml $(PLAYBOOK_DIR)/vm-destroy.yml; do \
		echo "$(YELLOW)Testing $$playbook in check mode...$(NC)"; \
		ansible-playbook --check -i $(ANSIBLE_INVENTORY) "$$playbook" || exit 1; \
	done
	@echo "$(GREEN)✅ Dry-run tests completed$(NC)"

.PHONY: test
test: lint test-validate ## Run all tests (lint + validation)
	@echo "$(GREEN)🎉 All tests completed successfully!$(NC)"

# Security checks
.PHONY: security-check
security-check: ## Check for security issues
	@if [ -f scripts/security-scan.sh ]; then \
		bash scripts/security-scan.sh; \
	else \
		echo "$(GREEN)Running security checks...$(NC)"; \
		echo "$(YELLOW)Checking for hardcoded secrets...$(NC)"; \
		password_matches=$$(grep -r -n "password.*:" $(PLAYBOOK_DIR)/ $(ROLE_DIR)/ --include="*.yml" --include="*.yaml" 2>/dev/null | grep -v "{{.*}}" | grep -v "#" || true); \
		if [ -n "$$password_matches" ]; then \
			echo "$$password_matches"; \
			echo "$(RED)❌ Potential hardcoded passwords found$(NC)"; \
			exit 1; \
		fi; \
		echo "$(GREEN)✅ Security check completed$(NC)"; \
	fi

# Inventory validation
.PHONY: inventory-check
inventory-check: ## Validate inventory files
	@echo "$(GREEN)Validating inventory...$(NC)"
	@for env in dev prod staging; do \
		echo "$(YELLOW)Checking $$env inventory...$(NC)"; \
		ansible-inventory -i inventories/$$env --list > /dev/null || exit 1; \
	done
	@echo "$(GREEN)✅ All inventories are valid$(NC)"

# CI target (combines everything)
.PHONY: ci
ci: check-deps inventory-check lint-fix test security-check ## Run full CI pipeline
	@echo "$(GREEN)🚀 Full CI pipeline completed successfully!$(NC)"

# Cleanup targets
.PHONY: clean
clean: ## Clean temporary files
	@echo "$(GREEN)Cleaning temporary files...$(NC)"
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name ".ansible" -type d -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache/
	@echo "$(GREEN)✅ Cleanup completed$(NC)"

# Development helpers
.PHONY: list-playbooks
list-playbooks: ## List all playbooks
	@echo "$(GREEN)Available playbooks:$(NC)"
	@ls -1 $(PLAYBOOK_DIR)/*.yml | sed 's|$(PLAYBOOK_DIR)/||' | sed 's|^|  - |'

.PHONY: list-roles
list-roles: ## List all roles
	@echo "$(GREEN)Available roles:$(NC)"
	@ls -1 $(ROLE_DIR)/ | sed 's|^|  - |'