#!/bin/bash

# Define the S3 bucket name
S3_BUCKET="inbound-bucket-custome03"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found. Please install it first."
    exit 1
fi

# Check if bucket exists
if ! aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
    echo "Bucket $S3_BUCKET does not exist or you don't have permissions."
    exit 1
fi

# Create test files
mkdir -p test_files
for i in {1..10}; do
    RANDOM_NUMBER=$((1 + RANDOM % 1000))
    FILENAME="test_files/filename-$RANDOM_NUMBER-$(date +%Y-%m-%d).txt"
    echo "This is test file number $i created at $(date)" > "$FILENAME"
    aws s3 cp "$FILENAME" "s3://$S3_BUCKET/incoming/"
    echo "Uploaded $FILENAME"
done

echo "Test files uploaded successfully to s3://$S3_BUCKET/incoming/"