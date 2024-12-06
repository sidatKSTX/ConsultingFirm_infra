#!/bin/bash

# Check if correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <stack-type> <environment>"
    echo "Example: $0 iam dev"
    exit 1
fi

STACK_TYPE=$1
ENVIRONMENT=$2

# Set AWS region
AWS_REGION="us-west-2"  # Change this to your preferred region

# Set stack names
IAM_STACK_NAME="initial-iam-stack-${ENVIRONMENT}"
MAIN_STACK_NAME="main-infrastructure-stack-${ENVIRONMENT}"

# Function to wait for stack creation/update to complete
wait_for_stack() {
    echo "Waiting for stack $1 to complete..."
    aws cloudformation wait stack-${2}-complete --stack-name $1 --region $AWS_REGION
}

# Deploy IAM stack
deploy_iam() {
    echo "Deploying IAM stack..."
    aws cloudformation create-stack \
        --stack-name $IAM_STACK_NAME \
        --template-body file://iam/initial-iam-template.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
        --region $AWS_REGION

    wait_for_stack $IAM_STACK_NAME "create"
}

# Deploy main infrastructure stack
deploy_main() {
    echo "Deploying main infrastructure stack..."
    DEPLOYMENT_ROLE_ARN=$(aws cloudformation describe-stacks --stack-name $IAM_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='DeploymentRoleArn'].OutputValue" --output text --region $AWS_REGION)
    
    aws cloudformation create-stack \
        --stack-name $MAIN_STACK_NAME \
        --template-body file://infrastructure/main.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --role-arn $DEPLOYMENT_ROLE_ARN \
        --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
        --region $AWS_REGION

    wait_for_stack $MAIN_STACK_NAME "create"
}

# Main deployment logic
if [ "$STACK_TYPE" = "iam" ]; then
    deploy_iam
elif [ "$STACK_TYPE" = "infrastructure" ]; then
    deploy_main
else
    echo "Invalid stack type. Use 'iam' or 'infrastructure'."
    exit 1
fi

echo "Deployment completed successfully!"
