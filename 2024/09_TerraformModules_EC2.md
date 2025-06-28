
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

###  4. Check Output

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
---


---

###  **The Code:**

```hcl
module "web_server" {
  source        = "./modules/ec2_instance"
  ami           = "ami-0d03cb826412c6b0f"  # Amazon Linux 2 (Mumbai)
  instance_type = "t2.micro"
  name          = "TestEC2Instance"
}
```

---

##  **Line-by-Line Explanation**

---

###  `module "web_server" {`

* This declares a **module block** in Terraform.
* `"web_server"` is the **local name** you are giving to this module usage.
* You can refer to this later using `module.web_server`.

---

###  `source = "./modules/ec2_instance"`

* This tells Terraform **where to find the module code**.
* In this case, it's pointing to a **local folder** named `modules/ec2_instance`.
* That folder must contain `main.tf`, `variables.tf`, and (optionally) `outputs.tf`.

---

###  `ami = "ami-0d03cb826412c6b0f"`

* This sets a **value for the variable `ami`** defined inside the module.
* `"ami-0d03cb826412c6b0f"` is an Amazon Machine Image ID for Amazon Linux 2 (in Mumbai region).
* The module will use this AMI to launch the EC2 instance.

---

###  `instance_type = "t2.micro"`

* This sets the **EC2 instance type** (also passed to the module).
* `t2.micro` is eligible for the AWS free tier and is commonly used for basic servers.

---

###  `name = "TestEC2Instance"`

* This value is passed into the module as the `name` variable.
* It's typically used as a **tag** to name the EC2 instance in the AWS console.

---

###  `}`

* Ends the module block.

---

##  **What Happens Behind the Scenes**

* Terraform **looks into the module folder** (`./modules/ec2_instance`).
* It sees the module's code and finds that it expects 3 variables: `ami`, `instance_type`, and `name`.
* You’ve provided values for all 3 here.
* The module then uses these inputs to create an EC2 instance using the **resource block** inside it.

---

##  Summary

| Line                  | What it Does                               |
| --------------------- | ------------------------------------------ |
| `module "web_server"` | Declares a new module instance             |
| `source`              | Points to the folder containing the module |
| `ami`                 | AMI ID to use for EC2                      |
| `instance_type`       | Type of EC2 instance to create             |
| `name`                | Tag name for the instance                  |

---



