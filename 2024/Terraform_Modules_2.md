Sure, let's break down how the Terraform modules are connected and how they work together to create the infrastructure:

### Project Structure
Your project structure helps organize your Terraform code into reusable modules. Here’s a recap of the structure:

```plaintext
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

### Provider Configuration
The `provider.tf` file sets up the AWS provider:

```hcl
provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}
```
This tells Terraform to use AWS as the cloud provider and specifies the region and profile for authentication.

### VPC Module
The VPC module is defined in `modules/vpc/`. It creates a VPC resource:

**main.tf**:
```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}
```

**variables.tf**:
```hcl
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

**outputs.tf**:
```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}
```
The `vpc` module creates a VPC with the specified CIDR block and name, and outputs the VPC ID for use in other modules.

### Subnet Module
The subnet module is defined in `modules/subnet/`. It creates public and private subnets, an internet gateway, and a route table:

**main.tf**:
```hcl
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

**variables.tf**:
```hcl
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

**outputs.tf**:
```hcl
output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private.id
}
```
The `subnet` module creates subnets, an internet gateway, and a route table, associating the public subnet with the route table. It takes the VPC ID as an input and outputs the subnet IDs.

### EC2 Module
The EC2 module is defined in `modules/ec2/`. It creates an EC2 instance:

**main.tf**:
```hcl
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

**variables.tf**:
```hcl
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

**outputs.tf**:
```hcl
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
The `ec2` module creates an EC2 instance, taking the subnet ID and security group ID as inputs, and outputs the instance ID, public IP, and public DNS.

### Main Configuration File
The `main.tf` file uses the modules:

**main.tf**:
```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"
  vpc_name = "main-vpc"
}

module "subnet" {
  source = "./modules/subnet"

  vpc_id                 = module.vpc.vpc_id
 

```hcl
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

### Explanation of Module Connections

1. **VPC Module**:
   - The `vpc` module is responsible for creating a VPC. It takes inputs for the VPC CIDR block and name, and outputs the VPC ID.
   - The `main.tf` file initializes this module and provides the required inputs.

2. **Subnet Module**:
   - The `subnet` module creates public and private subnets, an internet gateway, and a route table associated with the public subnet.
   - It requires the VPC ID from the `vpc` module. In the `main.tf` file, the `vpc_id` is provided by referencing the output from the `vpc` module: `module.vpc.vpc_id`.
   - The module outputs the IDs of the public and private subnets.

3. **Security Group Resource**:
   - The `aws_security_group` resource is defined directly in the `main.tf` file. It requires the VPC ID to be associated with the correct VPC.
   - The `vpc_id` is provided by referencing the output from the `vpc` module: `module.vpc.vpc_id`.

4. **EC2 Module**:
   - The `ec2` module is responsible for creating an EC2 instance.
   - It requires the subnet ID and security group ID. The subnet ID is provided by referencing the output from the `subnet` module: `module.subnet.public_subnet_id`.
   - The security group ID is provided by referencing the `aws_security_group.web_sg.id`.

### Execution Flow

1. **Initialization (`terraform init`)**:
   - Terraform initializes the project by downloading necessary providers and modules.

2. **Planning (`terraform plan`)**:
   - Terraform creates an execution plan, showing what actions it will take to create the resources.

3. **Applying (`terraform apply`)**:
   - Terraform applies the plan, creating the resources in the specified order:
     - First, it creates the VPC using the `vpc` module.
     - Next, it creates the subnets, internet gateway, and route table using the `subnet` module, which relies on the VPC ID output from the `vpc` module.
     - Then, it creates the security group associated with the VPC.
     - Finally, it creates the EC2 instance using the `ec2` module, which relies on the subnet ID from the `subnet` module and the security group ID.

By organizing your Terraform code into modules, you can keep your configurations clean, reusable, and maintainable. Each module encapsulates a specific part of your infrastructure, making it easier to manage and update.
