# Hetzner Cloud Stateful Cluster

This project sets up a stateful cluster on Hetzner Cloud with PostgreSQL, Redis, and RabbitMQ using Terraform and Ansible.

## Architecture

- Network: 10.0.0.0/16 subnet
- Jump host with public IP for access and NAT
- PostgreSQL with one primary and one replica
- Redis and RabbitMQ sharing servers (one primary, one replica)
- All data stored on Hetzner volumes
- PostgreSQL backups to Hetzner Object Storage (S3)
- ARM64 instances where possible

## Prerequisites

- Hetzner Cloud API token
- SSH key pair
- Ansible 2.9+
- Terraform 1.0+

## Setup Instructions

### 1. Terraform Setup

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and add your Hetzner Cloud API token
2. Initialize Terraform:
   ```
   cd terraform
   terraform init
   ```
3. Apply the Terraform configuration:
   ```
   terraform apply
   ```
4. Note the jump host IP address from the output

### 2. Ansible Setup

1. Create a vault password file:
   ```
   echo "your-vault-password" > ansible/.vault_pass.txt
   chmod 600 ansible/.vault_pass.txt
   ```
2. Edit the vault variables in `ansible/group_vars/all/vault.yml` and encrypt it:
   ```
   cd ansible
   ansible-vault encrypt group_vars/all/vault.yml
   ```
3. Update the jump host IP in the inventory file:
   ```
   sed -i 's/{{ jump_host_ip }}/actual-ip-address/g' inventory.yml
   ```
4. Run the Ansible playbook:
   ```
   ansible-playbook playbooks/setup_all.yml
   ```

## Accessing Services

- PostgreSQL: Connect through the jump host to 10.0.1.10:5432 (primary) or 10.0.1.11:5432 (replica)
- Redis: Connect through the jump host to 10.0.1.20:6379 (primary) or 10.0.1.21:6379 (replica)
- RabbitMQ: Connect through the jump host to 10.0.1.20:5672/15672 (primary) or 10.0.1.21:5672/15672 (replica)

## Future Expansion

A K3s cluster can be added in another subnet for stateless applications.
