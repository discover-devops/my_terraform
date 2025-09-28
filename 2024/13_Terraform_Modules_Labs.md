**hands-on lab** that uses **modules** to create a **VPC + public subnet** and an **EC2 instance in that subnet**


---

# Lab: Use Modules to Build VPC + Public Subnet + EC2

## 0) Prereqs

* Terraform installed
* AWS CLI configured: `aws configure --profile default`
* IAM permissions for VPC/EC2/IGW/RouteTable/SG

---

## 1) Create the project structure

```bash
mkdir -p tf-modules-lab/modules/network tf-modules-lab/modules/webserver
cd tf-modules-lab
```

Final layout (you’ll create these files next):

```
tf-modules-lab/
├── provider.tf
├── main.tf
├── outputs.tf
└── modules/
    ├── network/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── webserver/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 2) Root files

### `provider.tf`

```hcl
# Root provider config (same as previous example)
provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}
```

### `main.tf`

```hcl
# Call the Network module (VPC + public subnet + IGW + route)
module "network" {
  source             = "./modules/network"
  name_prefix        = "demo"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  availability_zone  = "ap-south-1a"
}

# Call the Webserver module (SG + EC2 in that public subnet)
module "webserver" {
  source            = "./modules/webserver"
  name_prefix       = "demo"
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_id
  instance_type     = "t2.micro"
  ami               = "ami-06f621d90fa29f6d0"   # same AMI you used earlier (ap-south-1)
  ssh_ingress_cidr  = "0.0.0.0/0"               # for demo; tighten to your IP in real use
  http_ingress_cidr = "0.0.0.0/0"
}
```

### `outputs.tf`

```hcl
output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = module.network.public_subnet_id
  description = "Public subnet ID"
}

output "ec2_public_ip" {
  value       = module.webserver.public_ip
  description = "EC2 public IP"
}

output "ec2_public_dns" {
  value       = module.webserver.public_dns
  description = "EC2 public DNS"
}
```

---

## 3) Child module: **network**

### `modules/network/variables.tf`

```hcl
variable "name_prefix"        { type = string }
variable "vpc_cidr"           { type = string }
variable "public_subnet_cidr" { type = string }
variable "availability_zone"  { type = string }
```

### `modules/network/main.tf`

```hcl
# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name_prefix}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = { Name = "${var.name_prefix}-public-subnet" }
}

# Route table + 0.0.0.0/0 → IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.name_prefix}-public-rt" }
}

# Associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

### `modules/network/outputs.tf`

```hcl
output "vpc_id"           { value = aws_vpc.this.id }
output "public_subnet_id" { value = aws_subnet.public.id }
```

---

## 4) Child module: **webserver**

### `modules/webserver/variables.tf`

```hcl
variable "name_prefix"       { type = string }
variable "vpc_id"            { type = string }
variable "subnet_id"         { type = string }
variable "instance_type"     { type = string }
variable "ami"               { type = string }
variable "ssh_ingress_cidr"  { type = string }
variable "http_ingress_cidr" { type = string }
```

### `modules/webserver/main.tf`

```hcl
# Security Group (SSH + HTTP)
resource "aws_security_group" "web_sg" {
  name        = "${var.name_prefix}-web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = var.vpc_id

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

  tags = { Name = "${var.name_prefix}-web-sg" }
}

# EC2 Instance in the public subnet
resource "aws_instance" "web" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Ensure Internet path is ready before boot (good habit when using user_data)
  depends_on = [aws_security_group.web_sg]

  tags = { Name = "${var.name_prefix}-ec2" }
}
```

### `modules/webserver/outputs.tf`

```hcl
output "instance_id" { value = aws_instance.web.id }
output "public_ip"   { value = aws_instance.web.public_ip }
output "public_dns"  { value = aws_instance.web.public_dns }
```

---

## 5) Run it

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

**Outputs you’ll see:** `vpc_id`, `public_subnet_id`, `ec2_public_ip`, `ec2_public_dns`

Verify (optional):

```bash
# Replace with the output public IP/DNS
ping -c 3 <PUBLIC_IP>         # basic reachability
# If you later add Apache via user_data, you can: curl http://<PUBLIC_IP>
```

---

## 6) Clean up

```bash
terraform destroy
```

---

### Notes

* This lab keeps the **same provider** and **AMI** you used earlier (`ap-south-1`, `default`, `ami-06f621d90fa29f6d0`). If that AMI ever changes, swap it or use a data source to fetch the latest AL2.
* The public subnet has `map_public_ip_on_launch = true` and a default route to the IGW, so instances launched there receive a **public IP** and have Internet access (subject to SG rules).
* Modules keep responsibilities separate: **network** builds the VPC path; **webserver** handles SG + EC2. This is exactly why modules are handy.


# create folders
mkdir -p tf-modules-lab/modules/{network,webserver}

# create empty files
touch tf-modules-lab/{provider.tf,main.tf,outputs.tf} \
      tf-modules-lab/modules/network/{main.tf,variables.tf,outputs.tf} \
      tf-modules-lab/modules/webserver/{main.tf,variables.tf,outputs.tf}

# (optional) check the structure
find tf-modules-lab -type d -or -type f | sort
# or, if you have 'tree' installed:
# tree tf-modules-lab


**tfplan** = a saved Terraform **execution plan** file.

### What it is

* The **binary file** produced by `terraform plan -out=tfplan`.
* Contains the **exact set of actions** Terraform will take (create/modify/destroy), based on:

  * current state, your config, input vars, and provider versions.

### Why it matters

* **Apply exactly what you reviewed**: `terraform apply tfplan` executes that same plan (no surprises).
* **CI/CD friendly**: generate plan → review/approve → apply the same artifact.
* **Safety**: if state/config changed after the plan was created, applying it will **fail** instead of doing something new.

### Common commands

```bash
# create and save a plan
terraform plan -out=tfplan

# view a saved plan in human-readable form
terraform show tfplan

# apply the reviewed plan exactly
terraform apply tfplan
```

### Notes & gotchas

* The plan file is **machine-readable**, not meant for Git—treat as a build artifact.
* It can include **sensitive values**; don’t share broadly.
* It’s **only valid** for the same workspace/state/config it was created from (and typically same provider versions). If anything important changes, Terraform will refuse to apply it.

