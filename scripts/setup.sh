#!/bin/bash

# Setup script for the Hetzner Cloud stateful cluster

# Check for required tools
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting."; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "Ansible is required but not installed. Aborting."; exit 1; }

# Setup Terraform
echo "Setting up Terraform..."
cd terraform

if [ ! -f "terraform.tfvars" ]; then
  echo "Please create terraform.tfvars file first. You can use terraform.tfvars.example as a template."
  exit 1
fi

terraform init
terraform apply -auto-approve

# Get jump host IP
JUMP_HOST_IP=$(terraform output -raw jump_host_ip)
echo "Jump host IP: $JUMP_HOST_IP"

# Setup Ansible
echo "Setting up Ansible..."
cd ../ansible

# Create vault password file if it doesn't exist
if [ ! -f ".vault_pass.txt" ]; then
  echo "Please enter your Ansible vault password:"
  read -s VAULT_PASSWORD
  echo "$VAULT_PASSWORD" > .vault_pass.txt
  chmod 600 .vault_pass.txt
fi

# Update inventory with jump host IP
sed -i "s/{{ jump_host_ip }}/$JUMP_HOST_IP/g" inventory.yml

# Wait for SSH to be available on jump host
echo "Waiting for SSH to be available on jump host..."
while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$JUMP_HOST_IP echo OK 2>/dev/null
do
  echo "Still waiting for SSH..."
  sleep 5
done

# Run Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook playbooks/setup_all.yml

echo "Setup complete!"
echo "Jump host IP: $JUMP_HOST_IP"
