output "cluster_id" {
  value = yandex_kubernetes_cluster.main.id
}

output "network_id" {
  value = yandex_vpc_network.main.id
}

output "subnet_id" {
  value = yandex_vpc_subnet.main.id
}
