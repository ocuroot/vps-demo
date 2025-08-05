terraform {
    required_version = ">= 1.6.3"

    required_providers {
        digitalocean = {
            source = "digitalocean/digitalocean"
            version = "2.36.0"
        }
        google = {
            source = "hashicorp/google"
            version = "6.14.1"
        }
    }

    backend "gcs" {
        bucket  = "ocuroot-terraform-backends"
        project = "hosted-ocuroot"
    }
}

provider "google" {
  project     = "hosted-ocuroot"
  region      = "us-west1"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}
