terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.38.2"
    }
  }
  required_version = ">= 1.0.0"
}

provider "hcloud" {
  token = var.hcloud_token
}

# Network setup
resource "hcloud_network" "private_network" {
  name     = "private-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "stateful_subnet" {
  network_id   = hcloud_network.private_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# Jump host with public IP
resource "hcloud_server" "jump_host" {
  name        = "jump-host"
  image       = "ubuntu-22.04"
  server_type = "cx21"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.2"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

# PostgreSQL primary server
resource "hcloud_server" "postgres_primary" {
  name        = "postgres-primary"
  image       = "ubuntu-22.04"
  server_type = "cax21" # ARM64 instance
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.10"
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
}

# PostgreSQL replica server
resource "hcloud_server" "postgres_replica" {
  name        = "postgres-replica"
  image       = "ubuntu-22.04"
  server_type = "cax21" # ARM64 instance
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.11"
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
}

# Redis and RabbitMQ primary server
resource "hcloud_server" "redis_rabbitmq_primary" {
  name        = "redis-rabbitmq-primary"
  image       = "ubuntu-22.04"
  server_type = "cax21" # ARM64 instance
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.20"
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
}

# Redis and RabbitMQ replica server
resource "hcloud_server" "redis_rabbitmq_replica" {
  name        = "redis-rabbitmq-replica"
  image       = "ubuntu-22.04"
  server_type = "cax21" # ARM64 instance
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.21"
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
}

# Volumes for data persistence
resource "hcloud_volume" "postgres_primary_data" {
  name      = "postgres-primary-data"
  size      = 50
  server_id = hcloud_server.postgres_primary.id
  format    = "ext4"
}

resource "hcloud_volume" "postgres_replica_data" {
  name      = "postgres-replica-data"
  size      = 50
  server_id = hcloud_server.postgres_replica.id
  format    = "ext4"
}

resource "hcloud_volume" "redis_rabbitmq_primary_data" {
  name      = "redis-rabbitmq-primary-data"
  size      = 30
  server_id = hcloud_server.redis_rabbitmq_primary.id
  format    = "ext4"
}

resource "hcloud_volume" "redis_rabbitmq_replica_data" {
  name      = "redis-rabbitmq-replica-data"
  size      = 30
  server_id = hcloud_server.redis_rabbitmq_replica.id
  format    = "ext4"
}

# SSH key for server access
resource "hcloud_ssh_key" "default" {
  name       = "default-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Firewall for jump host
resource "hcloud_firewall" "jump_host_fw" {
  name = "jump-host-fw"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Apply firewall to jump host
resource "hcloud_firewall_attachment" "jump_host_fw_attachment" {
  firewall_id = hcloud_firewall.jump_host_fw.id
  server_ids  = [hcloud_server.jump_host.id]
}

# Output the jump host IP for easy access
output "jump_host_ip" {
  value = hcloud_server.jump_host.ipv4_address
}
