# S3 File Organizer

Automatically organizes vendor-uploaded files into date-structured folders in S3.

## Features
- 📅 Automatic date-based file organization (YYYY/MM/DD)
- ⚡ Event-driven processing via S3 triggers
- 🏗️ Infrastructure-as-code with Terraform
- 🐍 Python-powered Lambda function
- 🔍 Easy daily file retrieval
- 📊 Built-in monitoring with CloudWatch and X-Ray

Prerequisites
AWS account with CLI access
Terraform 1.6.6 or higher
Python 3.9 or higher
AWS CLI configured
Quick Start
Initialize Terraform:


terraform init
Apply Terraform Configuration:


terraform apply
Test the Solution:


./pre-setup-script.sh
Project Structure

Copy
├── lambda_functions/
│   └── main.py          # File processing logic
├── infrastructure/
│   ├── lambda.tf        # Lambda resources
│   └── versions.tf      # Terraform configuration
├── scripts/
│   └── pre-setup.sh     # Test file generator
└── README.md            # This file
Clean Up
To remove all resources, run:


terraform destroy