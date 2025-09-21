**step‑by‑step runbook** that adds **real, useful `depends_on` examples** to your EC2 + VPC + SG setup, so the instance only boots **after** the internet route 
is ready (important because your `user_data` uses `yum`).

# Goal

* Stand up a VPC with a public subnet + IGW + public route.
* Security Group allowing HTTP/SSH.
* EC2 instance that **waits for** the route table association (so it has internet during bootstrap).
* A tiny local check that hits the webpage once the instance is up.

---

## 0) Prereqs

* Terraform ≥ 1.5 (`terraform -version`)
* AWS CLI configured (`aws configure --profile default`)
* Permissions to create VPC/EC2/SG/IGW/Routes

---

## 1) Create the project

```bash
mkdir -p terraform_project && cd terraform_project
```

---

## 2) Create files (copy‑paste exactly)

### `provider.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
```

### `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "default"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "AZ for the public subnet"
  type        = string
  default     = "ap-south-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID to launch (valid in chosen region)"
  type        = string
  default     = "ami-06f621d90fa29f6d0" # update if needed
}

variable "project_name" {
  description = "Base name for resources"
  type        = string
  default     = "web-server"
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH (tighten in real use!)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "http_ingress_cidr" {
  description = "CIDR allowed to HTTP"
  type        = string
  default     = "0.0.0.0/0"
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

locals {
  name_prefix = "${var.project_name}-${var.aws_region}"
}
```

### `vpc.tf`

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = merge(var.common_tags, { Name = "${local.name_prefix}-vpc" })
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "${local.name_prefix}-igw" })
  # (Implicitly depends on VPC via vpc_id)
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags                    = merge(var.common_tags, { Name = "${local.name_prefix}-public-subnet" })
}

# Public Route Table with 0.0.0.0/0 via IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.common_tags, { Name = "${local.name_prefix}-public-rt" })
  # (Implicitly depends on IGW via route.gateway_id)
}

# Associate the RT with the Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id

  # EXPLICIT DEPENDENCY (illustrative but also practical):
  # Terraform already has implicit deps (IDs above), but we make it crystal clear.
  depends_on = [
    aws_internet_gateway.gw,
    aws_route_table.public
  ]
}
```

### `security-group.tf`

```hcl
resource "aws_security_group" "web_sg" {
  name        = "${local.name_prefix}-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_ingress_cidr]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${local.name_prefix}-sg" })
  # (Implicitly depends on VPC via vpc_id)
}
```

### `ec2-instance.tf`

```hcl
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # IMPORTANT: Explicitly depend on the route table association
  # so the instance has working internet when user_data runs yum/dnf.
  depends_on = [
    aws_route_table_association.public
  ]

  # key_name = "your-keypair" # uncomment if you want SSH

  user_data = <<-EOF
              #!/bin/bash
              set -e
              yum -y update
              yum -y install httpd
              systemctl enable --now httpd
              echo "<html><h1>Hello from Terraform</h1></html>" > /var/www/html/index.html
              EOF

  tags = merge(var.common_tags, { Name = "${local.name_prefix}-ec2" })
}

# OPTIONAL: quick local validation that the web page is reachable
resource "null_resource" "validate_http" {
  # Re-run this check if the instance changes
  triggers = {
    instance_id = aws_instance.web.id
    public_ip   = aws_instance.web.public_ip
  }

  depends_on = [aws_instance.web]

  provisioner "local-exec" {
    # Try for ~75s (15x5s) to allow httpd to come up
    command = "bash -lc 'for i in {1..15}; do curl -fsS http://${aws_instance.web.public_ip} && exit 0; sleep 5; done; echo FAILED && exit 1'"
  }
}
```

### `outputs.tf`

```hcl
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "EC2 public DNS"
  value       = aws_instance.web.public_dns
}
```

### (Optional) `terraform.tfvars`

```hcl
aws_region         = "ap-south-1"
aws_profile        = "default"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
availability_zone  = "ap-south-1a"
instance_type      = "t3.micro"
project_name       = "myapp"
ssh_ingress_cidr   = "0.0.0.0/0" # tighten to your IP in real setups
http_ingress_cidr  = "0.0.0.0/0"
common_tags = {
  ManagedBy   = "Terraform"
  Environment = "dev"
  Owner       = "Rahul"
}
```

---

## 3) Init

```bash
terraform init
```

## 4) Format (nice to have)

```bash
terraform fmt -recursive
```

## 5) Validate

```bash
terraform validate
```

## 6) Plan

Using `tfvars`:

```bash
terraform plan -var-file="terraform.tfvars" -out=tfplan
```

(or just `terraform plan -out=tfplan` to use defaults)

## 7) Apply

```bash
terraform apply tfplan
```

* Wait for completion; you’ll see `public_ip` and `public_dns` in outputs.
* The `null_resource.validate_http` will try to curl the web page locally—helpful verification.

## 8) Manual verify (optional)

```bash
curl http://<public_ip>
# <html><h1>Hello from Terraform</h1></html>
```

## 9) Destroy (clean up)

```bash
terraform destroy
```

---

## Why these `depends_on` help (and when to use them)

* `aws_instance.web` → **depends\_on** `aws_route_table_association.public`
  Ensures default route via IGW is in place **before** the instance boots—critical for `user_data` that updates packages or fetches artifacts from the internet.
* `aws_route_table_association.public` → **depends\_on** IGW/RT (illustrative)
  The IDs already create implicit deps, but adding it here makes intent crystal clear for readers/reviewers.

> Tip: Don’t overuse `depends_on`. Prefer **implicit deps** via attribute references. Use explicit deps only when there’s a **runtime dependency** that Terraform can’t infer (like ensuring internet is ready before cloud-init/user\_data runs).

