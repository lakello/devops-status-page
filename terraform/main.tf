terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_vpc_network" "main" {
  name = "devops-status-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "devops-status-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_iam_service_account" "k8s" {
  name = "devops-status-k8s-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_kubernetes_cluster" "main" {
  name        = "devops-status-k8s"
  description = "Kubernetes cluster for DevOps pet project"

  network_id = yandex_vpc_network.main.id

  master {
    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.main.id
    }

    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_editor
  ]
}

resource "yandex_kubernetes_node_group" "main" {
  cluster_id = yandex_kubernetes_cluster.main.id
  name       = "devops-status-node-group"

  instance_template {
    platform_id = "standard-v3"

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 30
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.main.id]
      nat        = true
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }
}
