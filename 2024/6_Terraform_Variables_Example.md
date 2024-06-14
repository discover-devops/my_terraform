Step-by-step document:
Terraform variables, 
use cases, and
And a example.

### Step-by-Step Document

#### Step 1: Introduction to Terraform Variables

##### What are Terraform Variables?

Terraform variables allow you to parameterize your configurations. They provide a way to define values that can be reused across your Terraform configuration files, making your configurations more flexible and easier to manage.

##### Use Case for Terraform Variables

- **Reusability:** By defining variables, you can reuse the same configuration for different environments (e.g., development, staging, production) with different values.
- **Manageability:** Variables help manage and update configuration values in a centralized way.
- **Flexibility:** They allow for the easy configuration of resources without changing the actual code, just by changing variable values.

#### Step 2: Project Structure

Your project structure should look like this:

```
terraform_project/
├── provider.tf
├── variables.tf
├── vpc.tf
├── subnet.tf
├── security-group.tf
├── ec2-instance.tf
├── outputs.tf
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

#### Step 4: Define Variables in `variables.tf`

Create a `variables.tf` file to define the variables you will use in your configuration.

```hcl
# variables.tf

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
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

variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "The AMI ID to use for the instance"
  type        = string
  default     = "ami-06f621d90fa29f6d0"  # Update this as per your region
}

variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
  default     = "my-key-pair"  # Ensure this key pair exists in your AWS account
}
```

#### Step 5: Create the VPC

Create a `vpc.tf` file to define the VPC using the variables.

```hcl
# vpc.tf

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}
```

#### Step 6: Create the Subnets

Create a `subnet.tf` file to define the public and private subnets.

```hcl
# subnet.tf

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

#### Step 7: Create the Security Group

Create a `security-group.tf` file to define the security group.

```hcl
# security-group.tf

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
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
```

#### Step 8: Create the EC2 Instance

Create an `ec2-instance.tf` file to define the EC2 instance in the public subnet.

```hcl
# ec2-instance.tf

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = var.key_name
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
    Name = "web-server"
  }
}
```

#### Step 9: Define Outputs

Create an `outputs.tf` file to define the outputs for the created resources.

```hcl
# outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private.id
}

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

### How to Use

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
