# S3 File Organizer

Automatically organizes vendor-uploaded files into structured date-based folders (YYYY/MM/DD) in Amazon S3 using AWS Lambda.

## ✨ Features
- 📅 **Automatic Organization** - Files sorted into date-based folders
- ⚡ **Event-Driven Processing** - Instant triggering via S3 uploads
- 🏗️ **Infrastructure as Code** - Fully managed by Terraform
- 🐍 **Python Runtime** - Clean, maintainable processing logic
- 🔍 **Simplified Retrieval** - Easy daily file access
- 📊 **Built-in Monitoring** - CloudWatch logs & X-Ray tracing

## 🛠 Prerequisites
- AWS account with admin privileges
- Terraform 1.6.6+
- Python 3.9+
- AWS CLI v2

## 🔐 AWS Setup

### 1. Configure AWS CLI
```bash
# Install AWS CLI (Linux/macOS)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
# Follow prompts to enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)
2. Create IAM Policy

# Create policy file (policy.json)
cat > policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "lambda:*",
                "iam:*",
                "logs:*",
                "xray:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Create policy in AWS
aws iam create-policy --policy-name S3FileOrganizerAdmin --policy-document file://policy.json
3. Create IAM User

aws iam create-user --user-name S3FileOrganizerUser

# Attach policy
aws iam attach-user-policy \
    --user-name S3FileOrganizerUser \
    --policy-arn arn:aws:iam::<YOUR_ACCOUNT_ID>:policy/S3FileOrganizerAdmin

# Create access keys
aws iam create-access-key --user-name S3FileOrganizerUser
Note: Save the SecretAccessKey immediately - it's only shown once!

🚀 Deployment

# Initialize Terraform
terraform init

# Review infrastructure plan
terraform plan

# Deploy resources
terraform apply -auto-approve

# Generate test files
chmod +x scripts/pre-setup.sh
./scripts/pre-setup.sh

� Cleanup
bash
Copy
# Destroy all resources
terraform destroy -auto-approve

# Delete IAM user (optional)
aws iam delete-user --user-name S3FileOrganizerUser
