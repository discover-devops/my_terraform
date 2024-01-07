In Terraform, variables allow you to parameterize your configurations, making them more dynamic and reusable. Variables are placeholders for values that can be defined in your Terraform files or provided externally. They make it easy to customize your infrastructure without modifying the underlying Terraform code.

Here's a brief explanation along with examples that you can run in AWS.

## Terraform Variables:

### 1. **Variable Definition:**

In your Terraform configuration file (e.g., `variables.tf`), you define variables:

```hcl
variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami" {
  description = "The Amazon Machine Image (AMI) ID"
  type        = string
}
```

In this example:

- `instance_type`: A variable representing the type of EC2 instance. It has a default value of "t2.micro".
- `ami`: A variable representing the AMI ID for the EC2 instance. It doesn't have a default value, meaning it must be provided when using the Terraform configuration.

### 2. **Using Variables in Resource Block:**

Now, you can use these variables in your resource blocks:

```hcl
resource "aws_instance" "example_instance" {
  ami           = var.ami
  instance_type = var.instance_type

  // other configuration settings...
}
```

Here, `var.ami` and `var.instance_type` reference the values assigned to the `ami` and `instance_type` variables.

### 3. **Variable Values:**

You can provide values for variables in multiple ways:

- **In a variable file (`terraform.tfvars`):**

  ```hcl
  instance_type = "t3.micro"
  ami           = "ami-12345678"
  ```

  Then, you can run Terraform commands like `terraform apply` without specifying these variables, and Terraform will automatically use the values from the `terraform.tfvars` file.

- **Command-Line Flags:**

  ```bash
  terraform apply -var="instance_type=t3.micro" -var="ami=ami-12345678"
  ```

  This allows you to provide variable values directly in the command line.

- **Environment Variables:**

  Set environment variables with the `TF_VAR_` prefix:

  ```bash
  export TF_VAR_instance_type=t3.micro
  export TF_VAR_ami=ami-12345678
  ```

  Terraform automatically picks up these environment variables.

### 4. **AWS Example:**

Here's a simple example using AWS resources:

```hcl
provider "aws" {
  region = "us-west-2"
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami" {
  description = "The Amazon Machine Image (AMI) ID"
  type        = string
}

resource "aws_instance" "example_instance" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name = "ExampleInstance"
  }
}
```

This Terraform configuration deploys an EC2 instance in the specified AWS region with the instance type and AMI ID as variables. You can customize the instance type and AMI by providing values through variable files, command-line flags, or environment variables.
