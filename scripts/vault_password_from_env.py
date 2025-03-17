#!/usr/bin/env python3
import os
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get the vault password from environment variable
vault_password = os.environ.get('ANSIBLE_VAULT_PASSWORD')

if vault_password:
    # Print the password to stdout for Ansible to use
    print(vault_password)
    sys.exit(0)
else:
    # If password not found, exit with error
    sys.stderr.write("ERROR: ANSIBLE_VAULT_PASSWORD environment variable not set\n")
    sys.exit(1)
