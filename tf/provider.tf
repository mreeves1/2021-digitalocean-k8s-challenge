terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "DIGITALOCEAN_TOKEN" {}

provider "digitalocean" {
  token = "${var.DIGITALOCEAN_TOKEN}" # Loaded from TF_VAR_DIGITALOCEAN_TOKEN user environment variable
}

data "digitalocean_ssh_key" "terraform" {
  name = "runamok@austinmarathon"
}