
```markdown
# Terraform Introduction

## What is Infrastructure as Code (IaC)?

Infrastructure as Code (IaC) is a methodology that involves managing and provisioning computing infrastructure through machine-readable script files. This allows for efficient and consistent infrastructure deployment and management.

## Introduction to Terraform

Terraform is an open-source Infrastructure as Code tool created by HashiCorp. It enables users to define and provision infrastructure using a declarative configuration language.

## Terraform vs Others

Terraform is often compared to other IaC tools like Ansible, Puppet, and Chef. Each tool has its strengths and use cases, but Terraform is widely adopted for its simplicity, scalability, and support for multiple cloud providers.

# Terraform Installation

## Install Terraform

### MacOS

```bash
brew install terraform
```

### Windows

Download the latest binary from the [official Terraform website](https://www.terraform.io/downloads.html) and add it to your PATH.

### Linux

```bash
sudo apt-get update && sudo apt-get install terraform
```

## Setting up Terraform on AWS

To use Terraform with AWS, you need to set up AWS credentials. This involves creating an AWS account and an AWS user with the necessary permissions.

# Terraform Architecture

## How Terraform Works

Terraform follows a client-server architecture. The client sends requests to the server, which interacts with the APIs of the target infrastructure providers.

## Terraform Phases

Terraform has three main phases: Initialization, Planning, and Applying. These phases help in setting up the environment, checking changes, and applying the defined configurations.

## Introduction to Provisioners

Provisioners in Terraform are used to execute scripts on a local or remote machine as part of resource creation.

# Terraform Core Components and Terraform Language

## Dive Deep into Terraform Coding

Terraform configurations are written using HashiCorp Configuration Language (HCL). This section provides an in-depth understanding of creating and managing resources in Terraform.

## Dive Deep into Terraform Language: HCL

HashiCorp Configuration Language (HCL) is a simple, human-readable language used for defining Terraform configurations.

# Demo Project Resources

## Install Terraform and Local Setup

## Create an AWS Account and an AWS User as a Pre-Requisite for the Demo

## Providers in Terraform - Connect to AWS Provider

## Understand the AWS Resources Created with Terraform (VPC, Subnet & more)

## Resources & Data Sources

## Change and Destroy Resources

## More Terraform Commands

## Terraform State

## Terraform Variables

# Labs

## Create AWS VPC and Subnet

## Create Route Table and Internet Gateway

## Associate Subnet with Route Table

## Use AWS Default Components: Default Route Table

## Create Security Group for Firewall Configuration

## Fetch Amazon Machine Image (AMI) for EC2 Instance

## Create EC2 Instance

## Create SSH Key Pair

## Configure EC2 Server to Run Entry Script and Run a Docker Container

## Best Practice: Configure Infrastructure, Not Servers

# Introduction to Modules

## Create and Use a Local Module - Encapsulating the Networking Configurations
```

Copy and paste this content into your GitHub page or markdown file, and it should render appropriately.
