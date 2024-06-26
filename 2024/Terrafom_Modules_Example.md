Step-by-step document to teach about Terraform modules, their use cases, and how to use them in a project to create a VPC, subnets, and an EC2 instance.

### Step-by-Step Document

#### Step 1: Introduction to Terraform Modules

##### What are Terraform Modules?

Terraform modules are reusable, self-contained packages of Terraform configurations that encapsulate resources, variables, and outputs. They enable you to organize and reuse your infrastructure code efficiently.

##### Use Case for Terraform Modules

- **Reusability:** Modules allow you to reuse the same infrastructure code across different projects and environments.
- **Maintainability:** By using modules, you can manage complex infrastructure in smaller, manageable pieces.
- **Consistency:** Modules ensure consistent infrastructure configurations across different environments.

#### Step 2: Project Structure

Your project structure will look like this:

```
terraform_project/
├── main.tf
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── subnet/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── provider.tf
```

#### Step 3: Create the Provider Configuration

Create a `provider.tf` file to define the AWS provider.

```hcl
# provider.tf

provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}
```

#### Step 4: Create the VPC Module

Create the VPC module in `modules/vpc/`.

**File: modules/vpc/main.tf**

```hcl
# modules/vpc/main.tf

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}
```

**File: modules/vpc/variables.tf**

```hcl
# modules/vpc/variables.tf

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "main-vpc"
}
```

**File: modules/vpc/outputs.tf**

```hcl
# modules/vpc/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}
```

#### Step 5: Create the Subnet Module

Create the subnet module in `modules/subnet/`.

**File: modules/subnet/main.tf**

```hcl
# modules/subnet/main.tf

resource "aws_subnet" "public" {
  vpc_id            = var.vpc_id
  cidr_block        = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = var.availability_zone
  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_subnet" "private" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = var.private_subnet_name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = var.vpc_id
  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.public_route_table_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

**File: modules/subnet/variables.tf**

```hcl
# modules/subnet/variables.tf

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "The availability zone for the subnets"
  type        = string
  default     = "ap-south-1a"
}

variable "public_subnet_name" {
  description = "The name of the public subnet"
  type        = string
  default     = "public-subnet"
}

variable "private_subnet_name" {
  description = "The name of the private subnet"
  type        = string
  default     = "private-subnet"
}

variable "internet_gateway_name" {
  description = "The name of the internet gateway"
  type        = string
  default     = "main-gateway"
}

variable "public_route_table_name" {
  description = "The name of the public route table"
  type        = string
  default     = "public-route-table"
}
```

**File: modules/subnet/outputs.tf**

```hcl
# modules/subnet/outputs.tf

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private.id
}
```

#### Step 6: Create the EC2 Instance Module

Create the EC2 instance module in `modules/ec2/`.

**File: modules/ec2/main.tf**

```hcl
# modules/ec2/main.tf

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><h1>Hello from Terraform</h1></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server"
  }
}
```

**File: modules/ec2/variables.tf**

```hcl
# modules/ec2/variables.tf

variable "ami_id" {
  description = "The AMI ID to use for the instance"
  type        = string
  default     = "ami-06f621d90fa29f6d0"  # Update this as per your region
}

variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in"
  type        = string
}

variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
  default     = "my-key-pair"  # Ensure this key pair exists in your AWS account
}

variable "security_group_id" {
  description = "The ID of the security group to associate with the instance"
  type        = string
}
```

**File: modules/ec2/outputs.tf**

```hcl
# modules/ec2/outputs.tf

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "The public DNS of the EC2 instance"
  value       = aws_instance.web.public_dns
}
```

#### Step 7: Main Configuration File

Create the main configuration file `main.tf` to use the modules.

**File: main.tf**

```hcl
# main.tf

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"
  vpc_name = "main-vpc"
}

module "subnet" {
  source = "./modules/subnet"

  vpc_id                 = module.vpc.vpc_id
  public_subnet_cidr     = "10.0.1.0/24"
  private_subnet_cidr    = "10.0.2.0/24"
  availability_zone      = "ap-south-1a"
  public_subnet_name     = "public-subnet"
  private_subnet_name    = "private-subnet"
  internet_gateway_name  = "main-gateway"
  public_route_table_name = "public-route-table"
}

resource "aws_security_group" "web_sg" {
  vpc_id      = module.vpc.vpc_id
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
    Name = "web-sg"
  }
}

module "ec2" {
  source = "./modules/ec2"

  ami_id            = "ami-06f621d90fa29f6d0"  # Update this as per your region
  instance_type     = "t2.micro"
  subnet_id         = module.subnet.public_subnet_id
  key_name          = "my-key-pair"  # Ensure this key pair exists in your AWS account
  security_group_id = aws_security_group.web_sg.id
}

```

#### Step 8: Initialize and Apply the Configuration

1. **Initialize the Configuration:**
   Navigate to the directory containing your `.tf` files and run:
   ```sh
   terraform init
   ```

2. **Plan the Configuration:**
   Preview the changes Terraform will make:
   ```sh
   terraform plan
   ```

3. **Apply the Configuration:**
   Apply the changes to create the VPC, subnets, security group, and EC2 instance:
   ```sh
   terraform apply
   ```

After running `terraform apply`, Terraform will output the IDs and IP addresses of the created resources. You can access the sample webpage by navigating to the public IP or DNS of the EC2 instance in a web browser.

### Summary

In this document, you learned about Terraform modules, their use cases, and how to create and use them in a project to set up a VPC, subnets, a security group, and an EC2 instance. This modular approach helps organize and manage your infrastructure code efficiently, making it reusable, maintainable, and consistent across different environments.
