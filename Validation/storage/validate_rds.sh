#!/bin/bash

# Source the variables
source rds_variables.env

# Extract RDS details
RDS_INFO=$(aws rds describe-db-instances --db-instance-identifier $EXPECTED_DB_INSTANCE --region us-east-1 --output json)

# Extract actual values
ACTUAL_STATUS=$(echo $RDS_INFO | jq -r '.DBInstances[0].DBInstanceStatus')
ACTUAL_PORT=$(echo $RDS_INFO | jq -r '.DBInstances[0].Endpoint.Port')
ACTUAL_VPCID=$(echo $RDS_INFO | jq -r '.DBInstances[0].DBSubnetGroup.VpcId')
ACTUAL_SG=$(echo $RDS_INFO | jq -r '.DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId')

# Validation function
validate_value() {
    local actual=$1
    local expected=$2
    local description=$3
    
    if [ "$actual" == "$expected" ]; then
        echo "✅ $description matches ($expected)"
        return 0
    else
        echo "❌ $description mismatch: Expected $expected, got $actual"
        return 1
    fi
}

echo "Validating RDS Configuration..."
echo "------------------------------"

# Status check
validate_value "$ACTUAL_STATUS" "available" "Instance Status"

# Port check
validate_value "$ACTUAL_PORT" "$EXPECTED_PORT" "Port"

# VPC check
validate_value "$ACTUAL_VPCID" "$EXPECTED_VPC_ID" "VPC"

# Security Group check
validate_value "$ACTUAL_SG" "$EXPECTED_SG_ID" "Security Group"

# Count failures
FAILURES=$?

if [ $FAILURES -eq 0 ]; then
    echo -e "\n✅ All validations passed!"
else
    echo -e "\n❌ Some validations failed. Please check the details above."
fi
