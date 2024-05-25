Below is the Terraform code to launch a MySQL RDS instance in a private subnet. This example assumes you already have a VPC with both public and private subnets set up. If not, you'll need to create those first. Here's the full configuration for completeness:

### Directory Structure

```
terraform_project/
├── provider.tf
├── vpc.tf
├── security-group.tf
├── rds-instance.tf
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

This file defines the VPC, public subnet, and private subnet.

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

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
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

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

### File: security-group.tf

This file defines the security group for the RDS instance.

```hcl
# security-group.tf

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  description = "Allow MySQL traffic"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}
```

### File: rds-instance.tf

This file defines the MySQL RDS instance.

```hcl
# rds-instance.tf

resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = [aws_subnet.private.id]

  tags = {
    Name = "main-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password123"
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true

  tags = {
    Name = "mydb-instance"
  }
}
```

### File: outputs.tf

This file defines the outputs for the created RDS instance.

```hcl
# outputs.tf

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.mysql.id
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
   Apply the changes to create the VPC, subnets, security group, and RDS instance:
   ```sh
   terraform apply
   ```

After running `terraform apply`, Terraform will output the endpoint and instance ID of the created RDS instance. The RDS instance will be launched in the private subnet, ensuring it is not directly accessible from the internet.
