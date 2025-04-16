# S3 File Organizer

Automatically organizes vendor-uploaded files into date-structured folders in S3.

## Features
- 📅 Automatic date-based file organization (YYYY/MM/DD)
- ⚡ Event-driven processing via S3 triggers
- 🏗️ Infrastructure-as-code with Terraform
- 🐍 Python-powered Lambda function
- 🔍 Easy daily file retrieval
- 📊 Built-in monitoring (CloudWatch/X-Ray)

## Architecture
```mermaid
graph LR
    A[S3 Upload] --> B[S3 Event]
    B --> C[Lambda Trigger]
    C --> D[File Processing]
    D --> E[Date-Based Organization]
Prerequisites
AWS account with CLI access

Terraform 1.6.6+

Python 3.9+

AWS CLI configured

Quick Start


terraform init
terraform apply
./pre-setup-script.sh  # Test the solution
Project Structure

├── lambda_functions/
│   └── main.py          # File processing logic
├── infrastructure/
│   ├── lambda.tf        # Lambda resources
│   └── versions.tf      # Terraform config
├── scripts/
│   └── pre-setup.sh     # Test file generator
└── README.md
Clean Up

terraform destroy