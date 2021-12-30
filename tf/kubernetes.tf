resource "digitalocean_kubernetes_cluster" "dev-01" {
  name   = "dev-01"
  region = "sfo3" # Get from doctl kubernetes options regions
  # 2 different ways to control the k8s version. This will allow patches to apply because auto_upgrade is true
  version = data.digitalocean_kubernetes_versions.k8s_version.latest_version
  # version = "1.20.11-do.0" # Get from doctl kubernetes options versions
  vpc_uuid = data.digitalocean_vpc.sfo3-vpc-01.id
  auto_upgrade = true
  surge_upgrade = true

  node_pool {
    name       = "default"
    # Get size from doctl kubernetes options sizes
    size       = "s-2vcpu-2gb" # $15/month per https://slugs.do-api.dev/
    node_count = 2
    auto_scale = false
    # Prevents DBs?
    taint {
      key    = "workloadKind"
      value  = "database"
      effect = "NoSchedule"
    }
  }

  maintenance_policy {
    day = "sunday"
    start_time = "08:00" # UTC
  }
}

data "digitalocean_vpc" "sfo3-vpc-01" {
  name = "sfo3-vpc-01"
}

data "digitalocean_kubernetes_versions" "k8s_version" {
  version_prefix = "1.20."
}