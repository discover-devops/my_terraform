
---

##  STEP-BY-STEP: Simple EC2 Module with Terraform

---

###  Step 1: Create Project Directory

```bash
mkdir terraform-modules-example
cd terraform-modules-example
```

---

###  Step 2: Create Root-Level Files

```bash
touch main.tf provider.tf outputs.tf
```

---

###  Step 3: Create Modules Folder and EC2 Module

```bash
mkdir -p modules/ec2_instance
cd modules/ec2_instance
touch main.tf variables.tf outputs.tf
cd ../../
```

 **Your folder structure is now:**

```
terraform-modules-example/
├── main.tf
├── provider.tf
├── outputs.tf
└── modules/
    └── ec2_instance/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

###  Step 4: Write Code into Each File

####  `provider.tf`

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

---

####  `main.tf` (root-level)

```hcl
module "web_server" {
  source        = "./modules/ec2_instance"
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 (Mumbai)
  instance_type = "t2.micro"
  name          = "TestEC2Instance"
}
```

---

####  `outputs.tf` (root-level)

```hcl
output "instance_id" {
  value = module.web_server.instance_id
}
```

---

####  `modules/ec2_instance/main.tf`

```hcl
resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name = var.name
  }
}
```

---

####  `modules/ec2_instance/variables.tf`

```hcl
variable "ami" {}
variable "instance_type" {}
variable "name" {}
```

---

####  `modules/ec2_instance/outputs.tf`

```hcl
output "instance_id" {
  value = aws_instance.this.id
}
```

---

##  Step 5: Initialize and Deploy with Terraform

###  1. Initialize Terraform

```bash
terraform init
```

 This installs the AWS provider and prepares the module.

---

###  2. Preview Changes

```bash
terraform plan
```

 Shows what Terraform is about to do — create 1 EC2 instance.

---

###  3. Apply Configuration

```bash
terraform apply
```

* Type `yes` when prompted.
* Wait for the EC2 instance to be provisioned.

---

### 🔍 4. Check Output

```bash
terraform output
```

You’ll see:

```bash
instance_id = "i-xxxxxxxxxxxxxxxxx"
```

 EC2 instance is now live!

---

###  Cleanup (Optional)

To delete the created resources:

```bash
terraform destroy
```

---

##  Summary

| Step              | Description                          |
| ----------------- | ------------------------------------ |
| Create folder     | `mkdir terraform-modules-example`    |
| Create files      | `touch main.tf` etc.                 |
| Write module code | Inside `modules/ec2_instance`        |
| Initialize        | `terraform init`                     |
| Plan + Apply      | `terraform plan` → `terraform apply` |
| Get output        | `terraform output`                   |

---


