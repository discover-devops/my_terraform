You can split the code into multiple files to organize your configuration better. Here, I'll show you how to create the necessary files to set up the backend for storing the Terraform state file in S3 and to define the provider and the EC2 instance.

### Directory Structure

```
terraform_project/
├── backend.tf
├── provider.tf
└── ec2-instance.tf
```

### File: backend.tf

This file configures the Terraform backend to use S3 for remote state storage.

```hcl
# backend.tf

terraform {
  required_version = ">= 1.4" 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "kumarnewbucket"
    key    = "test/terraform.tfstate"
    region = "ap-south-1"
  }
}
```

### File: provider.tf

This file configures the AWS provider.

```hcl
# provider.tf

# Provider Block
provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}
```

### File: ec2-instance.tf

This file defines the EC2 instance resource.

```hcl
# ec2-instance.tf

# Resource Block
resource "aws_instance" "ec2demo" {
  ami           = "ami-06f621d90fa29f6d0" # Amazon Linux in us-east-1, update as per your region
  instance_type = "t2.micro"
}
```

### How to Use

1. **Initialize the Configuration:**
   Navigate to the directory containing your `.tf` files and run:
   ```sh
   terraform init
   ```

   The `terraform init` command initializes the backend configuration and downloads the required providers.

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

By splitting your configuration into multiple files, you enhance readability and maintainability. The `backend.tf` file sets up remote state storage, the `provider.tf` file configures the AWS provider, and the `ec2-instance.tf` file defines the EC2 instance resource.
