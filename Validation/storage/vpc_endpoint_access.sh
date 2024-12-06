#!/bin/bash
source rds_variables.env

# Add these variables to rds_variables.env
VPC_ENDPOINT_ID="vpce-0dd5264e3ed25e062"
EXPECTED_VPC_ID="vpc-0e0ba36fd1cca5339"
EXPECTED_STATE="available"

echo "Validating VPC Endpoint..."
echo "-------------------------"

# Get VPC endpoint details
VPC_ENDPOINT_INFO=$(aws ec2 describe-vpc-endpoints --vpc-endpoint-id $VPC_ENDPOINT_ID --region us-east-1 --output json)

# Check endpoint state
ACTUAL_STATE=$(echo $VPC_ENDPOINT_INFO | jq -r '.VpcEndpoints[0].State')
echo "Endpoint State: $ACTUAL_STATE"
if [ "$ACTUAL_STATE" == "$EXPECTED_STATE" ]; then
    echo "✅ VPC Endpoint is available"
else
    echo "❌ VPC Endpoint is not available (State: $ACTUAL_STATE)"
fi

# Check VPC ID
ACTUAL_VPC=$(echo $VPC_ENDPOINT_INFO | jq -r '.VpcEndpoints[0].VpcId')
if [ "$ACTUAL_VPC" == "$EXPECTED_VPC_ID" ]; then
    echo "✅ VPC ID matches expected"
else
    echo "❌ VPC ID mismatch (Expected: $EXPECTED_VPC_ID, Got: $ACTUAL_VPC)"
fi

# Check DNS entries
DNS_ENTRIES=$(echo $VPC_ENDPOINT_INFO | jq -r '.VpcEndpoints[0].DnsEntries[].DnsName')
if [ -n "$DNS_ENTRIES" ]; then
    echo "✅ DNS entries found:"
    echo "$DNS_ENTRIES"
else
    echo "❌ No DNS entries found"
fi

# Check security groups
ENDPOINT_SGS=$(echo $VPC_ENDPOINT_INFO | jq -r '.VpcEndpoints[0].Groups[].GroupId')
if [[ $ENDPOINT_SGS == *"$EXPECTED_SG_ID"* ]]; then
    echo "✅ Security group attached"
else
    echo "❌ Expected security group not found"
fi

# Check subnet associations
SUBNETS=$(echo $VPC_ENDPOINT_INFO | jq -r '.VpcEndpoints[0].SubnetIds[]')
if [ -n "$SUBNETS" ]; then
    echo "✅ Subnet associations found:"
    echo "$SUBNETS"
else
    echo "❌ No subnet associations found"
fi
