#!/usr/bin/env python3
import os
import subprocess
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Variables to encrypt
vault_vars = {
    'vault_postgres_password': os.environ.get('POSTGRES_PASSWORD', 'securepassword'),
    'vault_postgres_replication_password': os.environ.get('POSTGRES_REPLICATION_PASSWORD', 'replicatorpassword'),
    'vault_redis_password': os.environ.get('REDIS_PASSWORD', 'redispassword'),
    'vault_rabbitmq_password': os.environ.get('RABBITMQ_PASSWORD', 'rabbitmqpassword'),
    'vault_rabbitmq_erlang_cookie': os.environ.get('RABBITMQ_ERLANG_COOKIE', 'erlangcookievalue'),
    'vault_rabbitmq_password_hash': os.environ.get('RABBITMQ_PASSWORD_HASH', 'passwordhashvalue'),
    'vault_s3_access_key': os.environ.get('S3_ACCESS_KEY', 's3accesskey'),
    'vault_s3_secret_key': os.environ.get('S3_SECRET_KEY', 's3secretkey'),
}

# Create vault file content
vault_content = "---\n"
for key, value in vault_vars.items():
    vault_content += f"{key}: {value}\n"

# Write to temporary file
with open('temp_vault.yml', 'w') as f:
    f.write(vault_content)

# Encrypt the file using ansible-vault
try:
    subprocess.run(
        ['ansible-vault', 'encrypt', 'temp_vault.yml', '--output', 'ansible/group_vars/all/vault.yml'],
        check=True
    )
    # Remove temporary file
    os.remove('temp_vault.yml')
    print("Successfully created encrypted vault.yml from environment variables")
except subprocess.CalledProcessError as e:
    print(f"Error encrypting vault file: {e}", file=sys.stderr)
    sys.exit(1)
