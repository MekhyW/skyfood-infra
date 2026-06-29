# SkyFood Infrastructure

This repository contains the Terraform configuration required to deploy and maintain the AWS infrastructure used by the SkyFood ecosystem. Its goal is to provide a reproducible, version-controlled, and automated way to provision cloud resources.

Application source code is intentionally maintained in separate repositories. This repository is responsible only for infrastructure provisioning and configuration.

The `modules` directory contains a collection of reusable Terraform modules based on the community-maintained `terraform-aws-modules` project. These modules serve as building blocks for the SkyFood infrastructure.

* VPC
* Application Load Balancer
* ECS Fargate cluster
* ECS services from a reusable `container_services` map

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

The shared ALB DNS name is available from the `alb_dns_name` output. To add more services later, add entries to `container_services` in the same environment tfvars file.

## Related Repositories

| Repository                     | Purpose                                          |
| ------------------------------ | ------------------------------------------------ |
| `platform-core`                | Core marketplace and delivery platform           |
| `platform-mobile-app`          | Ionic mobile application and Progressive Web App |
| `platform-elevator-integrator` | .NET service for elevator system integration     |
| `platform-media-panel`         | Advertising management platform                  |
| `platform-prototype-ecommerce` | Mock demo e-commerce app and admin panel         |
