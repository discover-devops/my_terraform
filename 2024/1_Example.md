Here is the Terraform code split into two parts: one for creating the Terraform provider block and the other for creating the EC2 instance.

### Part 1: Create Terraform Provider Block

This part sets up the provider configuration.

```hcl
# terraform-provider.tf

# Terraform Settings Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #version = "~> 3.21" # Optional but recommended in production
    }
  }
}

# Provider Block
provider "aws" {
  profile = "default" # AWS Credentials Profile configured on your local desktop terminal  $HOME/.aws/credentials
  region  = "ap-south-1"
}
```

### Part 2: Create EC2 Instance

This part defines the resource configuration for the EC2 instance.

```hcl
# ec2-instance.tf

# Resource Block
resource "aws_instance" "ec2demo" {
  ami           = "ami-06f621d90fa29f6d0" # Amazon Linux in us-east-1, update as per your region
  instance_type = "t2.micro"
}
```

### Directory Structure

To keep your Terraform project organized, you can structure your directory as follows:

```
terraform_project/
├── terraform-provider.tf
└── ec2-instance.tf
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
   Apply the changes to create the EC2 instance:
   ```sh
   terraform apply
   ```

By separating the provider configuration from the resource definition, you maintain a cleaner and more modular codebase, which can be particularly useful in larger projects.
