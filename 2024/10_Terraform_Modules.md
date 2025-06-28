
* A **VPC**
* A **Subnet** inside the VPC
* Launch an **EC2 instance** in that subnet
* Using **Terraform modules**
* With full commands and file structure

---

## Final Folder Structure

```
terraform-vpc-ec2/
├── main.tf
├── provider.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ec2/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## STEP 1: Create Folders and Files

```bash
mkdir -p terraform-vpc-ec2/modules/vpc
mkdir -p terraform-vpc-ec2/modules/ec2
cd terraform-vpc-ec2

# Root level files
touch main.tf provider.tf variables.tf outputs.tf terraform.tfvars

# VPC Module
cd modules/vpc
touch main.tf variables.tf outputs.tf

# EC2 Module
cd ../ec2
touch main.tf variables.tf outputs.tf

cd ../../  # back to root
```

---

## STEP 2: Write Code for Each File

---

### `provider.tf`

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

---

### `variables.tf`

```hcl
variable "vpc_cidr" {}
variable "subnet_cidr" {}
variable "instance_type" {}
variable "ami_id" {}
```

---

### `terraform.tfvars`

```hcl
vpc_cidr      = "10.0.0.0/16"
subnet_cidr   = "10.0.1.0/24"
instance_type = "t2.micro"
ami_id        = "ami-0d03cb826412c6b0f"  # Amazon Linux 2 (Mumbai)
```

---

### `main.tf` (root)

```hcl
module "vpc" {
  source     = "./modules/vpc"
  vpc_cidr   = var.vpc_cidr
  subnet_cidr = var.subnet_cidr
}

module "ec2" {
  source        = "./modules/ec2"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.vpc.subnet_id
}
```

---

### `outputs.tf`

```hcl
output "instance_id" {
  value = module.ec2.instance_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
```

---

## MODULE: VPC

### `modules/vpc/variables.tf`

```hcl
variable "vpc_cidr" {}
variable "subnet_cidr" {}
```

### `modules/vpc/main.tf`

```hcl
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "MyVPC"
  }
}

resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.subnet_cidr
  availability_zone = "ap-south-1a"

  tags = {
    Name = "MySubnet"
  }
}
```

### `modules/vpc/outputs.tf`

```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_id" {
  value = aws_subnet.this.id
}
```

---

## MODULE: EC2

###  `modules/ec2/variables.tf`

```hcl
variable "ami_id" {}
variable "instance_type" {}
variable "subnet_id" {}
```

### `modules/ec2/main.tf`

```hcl
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  tags = {
    Name = "EC2InCustomVPC"
  }
}
```

### `modules/ec2/outputs.tf`

```hcl
output "instance_id" {
  value = aws_instance.this.id
}
```

---

## STEP 3: Run Terraform Commands

### Initialize Terraform

```bash
terraform init
```

### Validate Syntax

```bash
terraform validate
```

### Plan Deployment

```bash
terraform plan -var-file="terraform.tfvars"
```

### Apply Deployment

```bash
terraform apply -var-file="terraform.tfvars"
```

### View Outputs

```bash
terraform output
```

---

## STEP 4: (Optional) Destroy Resources

```bash
terraform destroy -var-file="terraform.tfvars"
```

---

## Summary

| Component          | Purpose                                                            |
| ------------------ | ------------------------------------------------------------------ |
| `vpc module`       | Creates VPC + Subnet                                               |
| `ec2 module`       | Creates EC2 instance inside that subnet                            |
| `root module`      | Connects and orchestrates everything                               |
| `terraform.tfvars` | Stores environment-specific values (like CIDR, instance size, AMI) |

---

