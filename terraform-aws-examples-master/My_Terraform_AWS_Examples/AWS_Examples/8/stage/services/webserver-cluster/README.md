# Terraform Web Server Cluster

This Terraform file deploys a cluster of web servers in Amazon Web Services (AWS) using EC2 and Auto Scaling, and a load balancer using ELB.

The cluster of web servers returns "Hello, World" for the URL `/`. The load balancer listens on port 80.

## Using the code

* Configure your AWS access keys.

* Initialize working directory.

  The first command that should be run after writing a new Terraform configuration is the `terraform init` command in order to initialize a working directory containing Terraform configuration files. It is safe to run this command multiple times.

  ```bash
  terraform init
  ```

* Configure Terraform backend.

  Modify the S3 bucket name, which is defined in the `bucket` attribute in `backend.tf` file.

  ```bash
  bucket = "<YOUR_BUCKET_NAME>"
  ```

* Configure the bucket used for the database's remote state storage.

  Modify the S3 bucket name which is defined in the `bucket` attribute in `vars.tf` file. Important! You must deploy the templates in [data-stores/mysql](../../data-stores/mysql) first:

  ```hcl
  variable "db_remote_state_bucket" {
    description = "The name of the S3 bucket used for the database's remote state storage"
    default     =  "<YOUR_BUCKET_NAME>"
  }
  ```

* Validate the changes.

  Run command:

  ```bash
  terraform plan
  ```

* Deploy the changes.

  Run command:

  ```bash
  terraform apply
  ```

* Test the cluster of web servers.

  Test the cluster of web servers. When the `apply` command completes, it will output the DNS name of the load balancer.

  ```bash
  curl http://<elb_dns_name>/
  ```

* Clean up the resources created.

  When you have finished, run command:

  ```bash
  terraform destroy
  ```