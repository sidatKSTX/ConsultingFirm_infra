import subprocess
import json

def runAWScli(command):
    """Runs an AWS CLI Command and returns the parsed JSON output."""
    result = subprocess.run(command, stdout=subprocess.PIPE, shell=True)
    return json.loads(result.stdout)

def getPolicy(grpName):
    """Gets the list of Policies attached to the group"""
    command = f'aws iam list-attched-group-policies --group-name {grpName} --query "AttachedPolicies[].PolicyArn" --output json'
    return runAWScli(command)

def getRoles(policyARN):
    """Get the list of assigned Roles to the ARN policies"""
    command = f'aws iam list-entities-for-policy --policy-arn {policyARN} --query "PolicyRoles[].RoleName" --output json'
    return runAWScli(command)

def main():
    # IAM group name
    grpName = 'KSIE'
    # get the policy ARN attached to the group
    policyARN = getPolicy(grpName)
    #Iterate over each policy ARN and find attached roles
    for policyARN in policyARN:
        print(f"roles attached to the policy: {policyARN}")
        roles = getRoles(policyARN)
        if roles:
            for role in roles:
                print(f" -{role}")
        else:
            print(" no roles attached to this policy")
        print("---------------------------------------")

if  __name__ == "__main__":
     main()










