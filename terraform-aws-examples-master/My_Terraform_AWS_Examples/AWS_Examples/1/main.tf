# Configure the AWS provider
provider "aws" {
  region = "ap-south-1"
}

# Create an EC2 instance
resource "aws_instance" "mywebserver" {
  ami           = "ami-xxx"
  instance_type = "t2.micro"
}
