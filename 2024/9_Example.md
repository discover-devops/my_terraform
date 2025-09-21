
# Step‑by‑Step: Launch an EC2 + Apache in a Public Subnet (with Variables)

## 0) Prerequisites (one‑time)

* **Terraform** ≥ 1.5 installed (`terraform -version`)
* **AWS CLI** installed & configured:

  ```bash
  aws configure --profile default
  ```

  The profile you use must have permissions for VPC/EC2/SG/IGW/RouteTable.
* **Key pair (optional, only if you plan to SSH)**: create one in EC2 → Key pairs, or via CLI.

---

## 1) Create the project folder

```bash
mkdir -p terraform_project && cd terraform_project
```

---

## 2) Create files (copy–paste each exactly)

### `provider.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
  description = "AMI ID to launch (must exist in region)"
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
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = merge(var.common_tags, { Name = "${local.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "${local.name_prefix}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags                    = merge(var.common_tags, { Name = "${local.name_prefix}-public-subnet" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.common_tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
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
}
```

### `ec2-instance.tf`

```hcl
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Optional: to SSH in, uncomment and set an existing key name
  # key_name = "your-ec2-keypair-name"

  user_data = <<-EOF
              #!/bin/bash
              set -e
              yum update -y
              yum install -y httpd
              systemctl enable --now httpd
              echo "<html><h1>Hello from Terraform</h1></html>" > /var/www/html/index.html
              EOF

  tags = merge(var.common_tags, { Name = "${local.name_prefix}-ec2" })
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

Use this to override defaults per environment without touching code.

```hcl
aws_region         = "ap-south-1"
aws_profile        = "default"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
availability_zone  = "ap-south-1a"
instance_type      = "t3.micro"
project_name       = "myapp"
ssh_ingress_cidr   = "0.0.0.0/0"  # tighten to your IP for security
http_ingress_cidr  = "0.0.0.0/0"
common_tags = {
  ManagedBy   = "Terraform"
  Environment = "dev"
  Owner       = "Rahul"
}
```

---

## 3) Initialize

```bash
terraform init
```

---

## 4) (Nice to have) Auto‑format

```bash
terraform fmt -recursive
```

---

## 5) Validate

```bash
terraform validate
```

---

## 6) Plan

With tfvars:

```bash
terraform plan -var-file="terraform.tfvars" -out=tfplan
```

Or using defaults:

```bash
terraform plan -out=tfplan
```

---

## 7) Apply

```bash
terraform apply tfplan
```

Confirm and wait until complete. You’ll see outputs like `public_ip` and `public_dns`.

---

## 8) Verify the webpage

* Browser: visit `http://<public_ip>` or `http://<public_dns>`
* CLI:

  ```bash
  curl http://<public_ip>
  # Should print: <html><h1>Hello from Terraform</h1></html>
  ```

---

## 9) (Optional) SSH into the instance

Only if you set `key_name` and opened SSH to your IP:

```bash
ssh -i /path/to/your.pem ec2-user@<public_ip>
```

---

## 10) Clean up (avoid charges)

```bash
terraform destroy
```

---

## Troubleshooting quick hits

* **`InvalidAMIID.NotFound`**: The AMI ID isn’t valid in your region—update `var.ami_id` or switch to a data source later.
* **Auth/permissions**: Ensure your `aws_profile` has rights to create VPC/IGW/Routes/EC2/SG.
* **VPC CIDR conflict**: Pick a non‑overlapping CIDR for your account.
* **SSH timeout**: If you’ll SSH, associate a key pair and restrict `ssh_ingress_cidr` to your IP.

---

## Pro tips (optional later)

* Use **`terraform.workspace`** + separate `*.tfvars` for `dev/stage/prod`.
* Replace fixed AMI with a **data source** to auto‑pick latest Amazon Linux:

  ```hcl
  data "aws_ami" "al2023" {
    most_recent = true
    owners      = ["137112412989"] # Amazon
    filter {
      name   = "name"
      values = ["al2023-ami-*-kernel-*-x86_64"]
    }
  }
  # then: ami = data.aws_ami.al2023.id
  ```

