#!/bin/bash

# Check if correct number of arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    exit 1
fi

ENVIRONMENT=$1

# Set AWS region
AWS_REGION="us-west-2"  # Change this to your preferred region

# Set stack names
IAM_STACK_NAME="initial-iam-stack-${ENVIRONMENT}"
MAIN_STACK_NAME="main-infrastructure-stack-${ENVIRONMENT}"

# Function to wait for stack deletion to complete
wait_for_stack_deletion() {
    echo "Waiting for stack $1 to be deleted..."
    aws cloudformation wait stack-delete-complete --stack-name $1 --region $AWS_REGION
}

# Delete main infrastructure stack
echo "Deleting main infrastructure stack..."
aws cloudformation delete-stack --stack-name $MAIN_STACK_NAME --region $AWS_REGION
wait_for_stack_deletion $MAIN_STACK_NAME

# Delete IAM stack
echo "Deleting IAM stack..."
aws cloudformation delete-stack --stack-name $IAM_STACK_NAME --region $AWS_REGION
wait_for_stack_deletion $IAM_STACK_NAME

echo "Cleanup completed successfully!"
