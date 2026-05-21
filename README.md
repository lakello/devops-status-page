# devops-status-page
Pet-project for learning DevOps basics.

## Stack

- C# / ASP.NET Core Minimal API
- Docker
- Kubernetes
- Nginx Ingress
- Terraform
- Ansible
- GitHub Actions
- Yandex Cloud

## Architecture

GitHub Actions builds Docker image, pushes it to GHCR and deploys it to Yandex Managed Kubernetes.

Traffic flow:

Internet -> Yandex Load Balancer -> Nginx Ingress -> Kubernetes Service -> Pods

## Local run

```bash
cd app
dotnet run
