To launch an EC2 instance over the public subnet and ensure it is running Apache with a sample webpage, you'll need to use a combination of Terraform resource definitions and a user data script. The user data script will install and configure Apache on the instance when it is launched.

### Directory Structure

```
terraform_project/
├── provider.tf
├── vpc.tf
├── ec2-instance.tf
├── security-group.tf
├── outputs.tf
```

### File: provider.tf

This file contains the AWS provider configuration.

```hcl
# provider.tf

provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}
```

### File: vpc.tf

This file defines the VPC, public subnet, and related resources.

```hcl
# vpc.tf

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet"
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

### File: security-group.tf

This file defines the security group that allows HTTP and SSH access to the instance.

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

### File: ec2-instance.tf

This file defines the EC2 instance and includes a user data script to install Apache and set up a sample webpage.

```hcl
# ec2-instance.tf

resource "aws_instance" "web" {
  ami           = "ami-06f621d90fa29f6d0" # Update this as per your region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id  # Use the public subnet ID here
  vpc_security_group_ids = [aws_security_group.web_sg.id]  # Use the security group ID here

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

### File: outputs.tf

This file defines the outputs for the created EC2 instance.

```hcl
# outputs.tf

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

After running `terraform apply`, Terraform will output the instance ID, public IP, and public DNS of the created EC2 instance. You can access the sample webpage by navigating to the public IP or DNS in a web browser.
