resource "digitalocean_droplet" "vps" {
  image   = "ubuntu-22-04-x64"
  name    = "vps-${var.environment}"
  region  = "nyc2"
  size    = "s-1vcpu-1gb"

  ssh_keys = [
    digitalocean_ssh_key.default.id
  ]
}

resource "digitalocean_ssh_key" "default" {
  name       = "VPS demo ${var.environment}"
  public_key = tls_private_key.vps.public_key_openssh
}

resource "tls_private_key" "vps" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "private_key" {
  value     = tls_private_key.vps.private_key_pem
  sensitive = true
}

output "public_key" {
  value = tls_private_key.vps.public_key_openssh
}