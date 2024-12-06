#!/bin/bash
source rds_variables.env

echo "Checking Security Group Rules..."
echo "-------------------------------"

# Get security group rules
SG_RULES=$(aws ec2 describe-security-groups --group-id $EXPECTED_SG_ID --region us-east-1 --output json)

# Check for port 3306 rule
PORT_RULE=$(echo $SG_RULES | jq -r '.SecurityGroups[0].IpPermissions[] | select(.FromPort == 3306)')

if [ -z "$PORT_RULE" ]; then
    echo "❌ No rule found for port 3306"
else
    echo "✅ Port 3306 rule exists"
    
    # Check protocol
    PROTOCOL=$(echo $PORT_RULE | jq -r '.IpProtocol')
    if [ "$PROTOCOL" == "tcp" ]; then
        echo "✅ Protocol is TCP"
    else
        echo "❌ Wrong protocol: $PROTOCOL (should be tcp)"
    fi

    # Check source security groups
    SOURCE_GROUPS=$(echo $PORT_RULE | jq -r '.UserIdGroupPairs[].GroupId')
    if [ -n "$SOURCE_GROUPS" ]; then
        echo "Security group sources:"
        echo "$SOURCE_GROUPS" | while read -r group; do
            echo "- $group"
        done
    else
        echo "⚠️ No source security groups defined"
    fi

    # Check CIDR ranges
    CIDRS=$(echo $PORT_RULE | jq -r '.IpRanges[].CidrIp')
    if [ -n "$CIDRS" ]; then
        echo "CIDR sources:"
        echo "$CIDRS" | while read -r cidr; do
            if [ "$cidr" == "0.0.0.0/0" ]; then
                echo "⚠️ WARNING: Open to all IPs ($cidr)"
            else
                echo "- $cidr"
            fi
        done
    fi
fi

# Check outbound rules (egress)
EGRESS_RULES=$(echo $SG_RULES | jq -r '.SecurityGroups[0].IpPermissionsEgress[]')
echo -e "\nOutbound rules:"
echo "$EGRESS_RULES" | jq -r '.IpProtocol + " " + (.FromPort|tostring) + "-" + (.ToPort|tostring) + " -> " + (.IpRanges[].CidrIp)'
