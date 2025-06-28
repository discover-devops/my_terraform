
**Environment management** (Dev, QA, Staging, Production) using **reusable infrastructure code**.

Let me explain **how you should organize Terraform code for multiple environments like Dev and Prod**, along with best practices 

---

##  Goal:

> Use the **same infrastructure code** (e.g., EC2, VPC, RDS) for both **Dev** and **Prod**, but with **different configurations** (e.g., instance size, number of instances, etc.).

---

##  Option 1: Directory-Based Environment Structure (Best Practice)

###  Folder Structure:

```
terraform-project/
├── modules/
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── terraform.tfvars
│       └── backend.tf
```

---

##  Each Environment Reuses the Module

###  `envs/dev/main.tf`

```hcl
module "ec2" {
  source        = "../../modules/ec2"
  ami           = var.ami
  instance_type = var.instance_type
  name          = var.name
}
```

###  `envs/dev/terraform.tfvars`

```hcl
ami           = "ami-0d03cb826412c6b0f"
instance_type = "t2.micro"
name          = "DevEC2"
```

###  `envs/prod/terraform.tfvars`

```hcl
ami           = "ami-0d03cb826412c6b0f"
instance_type = "t3.medium"
name          = "ProdEC2"
```

Then run:

```bash
cd envs/dev
terraform init
terraform apply -var-file="terraform.tfvars"
```

and for prod:

```bash
cd envs/prod
terraform init
terraform apply -var-file="terraform.tfvars"
```

 Same module is used, but with different input values for each environment.

---

##  Option 2: Workspaces (Less Preferred for Large Teams)

Terraform also supports **workspaces**, but this is ideal for **small setups**.

```bash
terraform workspace new dev
terraform workspace new prod
```

Then use logic like:

```hcl
resource "aws_instance" "example" {
  instance_type = terraform.workspace == "prod" ? "t3.medium" : "t2.micro"
}
```

 Downside: All environments **share the same code folder**, which can be risky and messy in production teams.

---

##  Best Practice: Use Modules + Separate Folders per Env

| Feature             | Why It's Better                                        |
| ------------------- | ------------------------------------------------------ |
| **Modules**         | Reusable code, easier maintenance                      |
| **Folders per Env** | Separate state files, easier debugging, safer for Prod |
| **Remote Backends** | Store tfstate safely in S3 (per environment)           |

---

##  Bonus: Separate Remote State per Environment

In `envs/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-states"
    key    = "dev/terraform.tfstate"
    region = "ap-south-1"
  }
}
```

In `envs/prod/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-states"
    key    = "prod/terraform.tfstate"
    region = "ap-south-1"
  }
}
```

This keeps `dev` and `prod` **state files isolated**, which is crucial for production safety.

---

##  Summary: How to Manage Terraform Environments

| Strategy                       | Recommended? | Notes                                  |
| ------------------------------ | ------------ | -------------------------------------- |
| **Modules + Separate Folders** |  Yes        | Best for teams and real-world projects |
| **Workspaces**                 |  Maybe     | Simpler, but less safe and flexible    |
| **Copy-paste code per env**    |  No         | Difficult to maintain                  |

---

