#!/bin/bash

# Setup script for configuring S3 backups on the PostgreSQL primary server

# Check for required tools
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting."; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "Ansible is required but not installed. Aborting."; exit 1; }

# Get jump host IP from Terraform
cd terraform
JUMP_HOST_IP=$(terraform output -raw jump_host_ip)
echo "Jump host IP: $JUMP_HOST_IP"

# Install s3cmd on PostgreSQL primary
echo "Installing s3cmd on PostgreSQL primary..."
ssh -o StrictHostKeyChecking=no -J root@$JUMP_HOST_IP root@10.0.1.10 "apt-get update && apt-get install -y s3cmd"

# Configure s3cmd
echo "Configuring s3cmd..."
cd ../ansible
S3_ACCESS_KEY=$(ansible-vault view group_vars/all/vault.yml | grep vault_s3_access_key | awk '{print $2}')
S3_SECRET_KEY=$(ansible-vault view group_vars/all/vault.yml | grep vault_s3_secret_key | awk '{print $2}')
S3_BUCKET_NAME=$(grep s3_bucket_name group_vars/all.yml | awk '{print $2}' | tr -d '"')

ssh -o StrictHostKeyChecking=no -J root@$JUMP_HOST_IP root@10.0.1.10 "cat > ~/.s3cfg << EOF
[default]
access_key = $S3_ACCESS_KEY
secret_key = $S3_SECRET_KEY
host_base = s3.eu-central-1.amazonaws.com
host_bucket = %(bucket)s.s3.eu-central-1.amazonaws.com
bucket_location = eu-central-1
use_https = True
EOF"

# Test S3 connection
echo "Testing S3 connection..."
ssh -o StrictHostKeyChecking=no -J root@$JUMP_HOST_IP root@10.0.1.10 "s3cmd ls s3://$S3_BUCKET_NAME"

echo "Backup setup complete!"
