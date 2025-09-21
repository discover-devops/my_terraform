To **make your Terraform code more professional and portable**, you should use **variables** for all values that might change across environments or 
use cases—like region, instance type, AMI ID, CIDR blocks, and tags.

---

##  Why Use Variables in Terraform?

**Benefits of using variables:**

* **Portability**: Easily reuse the same code in different regions, environments, or accounts.
* **Maintainability**: Centralize changes in one place.
* **Flexibility**: Pass different values for dev, staging, and production.
* **Collaboration**: Make your code easier to understand and customize for teammates.

---

##  Types of Variables in Terraform

1. **Input Variables** – Let users/customers set values during `terraform apply`.
2. **Local Variables** – Used for computation inside the code (like concatenation, reuse).
3. **Output Variables** – Help retrieve values after deployment (already used in your `outputs.tf`).

---

### Use Cases in Your Project

### What you can convert into variables:

| Resource            | Parameter             | Variable Example                                   |
| ------------------- | --------------------- | -------------------------------------------------- |
| `provider.tf`       | region, profile       | `var.aws_region`, `var.aws_profile`                |
| `vpc.tf`            | VPC/subnet CIDRs, AZ  | `var.vpc_cidr`, `var.public_subnet_cidr`, `var.az` |
| `security-group.tf` | ingress/egress ports  | `var.allowed_ports`                                |
| `ec2-instance.tf`   | AMI ID, instance type | `var.ami_id`, `var.instance_type`                  |
| `tags` everywhere   | name values           | `var.project_name`                                 |

---

##  Step-by-Step Refactor

---

### 1. **Create a `variables.tf` File**

```hcl
# variables.tf

variable "aws_region" {
  default     = "ap-south-1"
  description = "The AWS region to deploy resources in"
}

variable "aws_profile" {
  default     = "default"
  description = "AWS CLI profile name"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  default     = "10.0.1.0/24"
  description = "CIDR block for the public subnet"
}

variable "availability_zone" {
  default     = "ap-south-1a"
  description = "AZ for the public subnet"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "ami_id" {
  default     = "ami-06f621d90fa29f6d0"
  description = "AMI ID to launch"
}

variable "project_name" {
  default     = "web-server"
  description = "Name tag for all resources"
}
```

---

### 2. **Update Your Files to Use Variables**

####  `provider.tf`

```hcl
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
```

####  `vpc.tf`

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet"
  }
}
```

####  `security-group.tf`

```hcl
resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}
```

####  `ec2-instance.tf`

```hcl
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><h1>Hello from Terraform</h1></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = var.project_name
  }
}
```

---

##  Optional: Use `terraform.tfvars`

Create a file `terraform.tfvars` to override default values:

```hcl
aws_region         = "ap-south-1"
aws_profile        = "rahul-dev"
vpc_cidr           = "10.10.0.0/16"
public_subnet_cidr = "10.10.1.0/24"
availability_zone  = "ap-south-1a"
instance_type      = "t3.micro"
ami_id             = "ami-0abcdef1234567890"
project_name       = "myapp"
```

Then run:

```sh
terraform apply -var-file="terraform.tfvars"
```

---

##  Bonus: Use `locals` for Derived Values

```hcl
locals {
  name_prefix = "${var.project_name}-${var.aws_region}"
}
```

And use it like this:

```hcl
tags = {
  Name = local.name_prefix
}
```

---

##  Final Directory Structure (Refactored)

```
terraform_project/
├── provider.tf
├── vpc.tf
├── ec2-instance.tf
├── security-group.tf
├── outputs.tf
├── variables.tf
└── terraform.tfvars    # optional
```

---

##  Summary

| Change              | Benefit                                |
| ------------------- | -------------------------------------- |
| `variables.tf`      | Makes all config customizable          |
| Use of `${var.xyz}` | Enables easy reuse across environments |
| `terraform.tfvars`  | Load values dynamically per workspace  |
| `locals` (optional) | Helps with clean, derived logic        |


