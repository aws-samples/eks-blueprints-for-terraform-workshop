#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ASK_DELETE=false
ACCEPT_DELETE=false

VPC_NAMES=("eks-blueprints-workshop")

cd ~/environment/vpc/

aws_debug() {
    set -x
    aws "$@"
    set +x
}

check_aws_auth() {
    echo "Checking AWS authentication..."
    aws_debug sts get-caller-identity > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: You are not authenticated with AWS. Please configure your AWS credentials and try again."
        exit 1
    fi
    echo "AWS authentication successful."
}

confirm_deletion() {
    local resource_type=$1
    if [ "$ASK_DELETE" = true ]; then
        if [ "$ACCEPT_DELETE" = true ]; then
            echo "Automatically accepting deletion of $resource_type."
            return 0
        else
            read -p "Do you want to delete the $resource_type? (y/n) " choice
            case "$choice" in
                y|Y ) return 0;;
                n|N ) return 1;;
                * ) echo "Invalid choice. Skipping deletion."; return 1;;
            esac
        fi
    else
        echo "Skipping deletion of $resource_type. Use --ask-delete to enable deletion."
        return 1
    fi
}


delete_vpc_endpoints() {
    echo "Checking if VPC endpoints exist..."
    
    # Use AWS_REGION if set, otherwise default to the region from AWS CLI configuration
    REGION=${AWS_REGION:-$(aws configure get region)}
    
    vpc_endpoint_names=(
        "com.amazonaws.$REGION.guardduty-data"
        "com.amazonaws.$REGION.ssm"
        "com.amazonaws.$REGION.ec2messages"
        "com.amazonaws.$REGION.ssmmessages"
        "com.amazonaws.$REGION.s3"
    )

    for vpc_name in "${VPC_NAMES[@]}"; do
        vpc_id=$(aws_debug ec2 describe-vpcs --filters "Name=tag:Name,Values=$vpc_name" --query "Vpcs[*].VpcId" --output text)
        vpc_endpoint_ids=()
        for endpoint_name in "${vpc_endpoint_names[@]}"; do
            endpoint_exists=$(aws_debug ec2 describe-vpc-endpoints --filters "Name=service-name,Values=$endpoint_name" "Name=vpc-id,Values=$vpc_id" --query "VpcEndpoints[*].VpcEndpointId" --output text 2>/dev/null)
            if [ -z "$endpoint_exists" ]; then
                echo -e "${RED}VPC endpoint '$endpoint_name' does not exist in VPC '$vpc_name'.${NC}"
            else
                echo -e "${GREEN}VPC endpoint '$endpoint_name' exists in VPC '$vpc_name'.${NC}"
                vpc_endpoint_ids+=("$endpoint_exists")
            fi
        done

        if [ ${#vpc_endpoint_ids[@]} -gt 0 ]; then
            if confirm_deletion "VPC endpoints in VPC '$vpc_name'"; then
                echo "Deleting VPC endpoints: ${vpc_endpoint_ids[*]}"
                aws_debug ec2 delete-vpc-endpoints --vpc-endpoint-ids "${vpc_endpoint_ids[@]}"
                if [ $? -eq 0 ]; then
                    echo "Successfully deleted VPC endpoints in VPC '$vpc_name'."
                else
                    echo -e "${RED}Failed to delete some or all VPC endpoints in VPC '$vpc_name'.${NC}"
                fi
            fi
        else
            echo "No VPC endpoints found to delete in VPC '$vpc_name'."
        fi
    done
}


delete_vpcs() {
    echo ""
    echo "Checking for VPCs..."

    # Check if any VPCs exist
    vpcs_to_delete=()
    for vpc_name in "${VPC_NAMES[@]}"; do
        vpc_id=$(aws_debug ec2 describe-vpcs --filters "Name=tag:Name,Values=$vpc_name" --query 'Vpcs[*].VpcId' --output text)

        if [ -z "$vpc_id" ]; then
            echo -e "${RED}VPC with name '$vpc_name' does not exist in the $AWS_REGION region.${NC}"
        else
            echo -e "${GREEN}VPC with name '$vpc_name' exists in the $AWS_REGION region (VPC ID: $vpc_id).${NC}"
            vpcs_to_delete+=("$vpc_id")
        fi
    done

    if [ ${#vpcs_to_delete[@]} -gt 0 ]; then
        if confirm_deletion "VPCs"; then
            for vpc_id in "${vpcs_to_delete[@]}"; do
                echo "Deleting VPC $vpc_id..."
                aws-delete-vpc -vpc-id=$vpc_id
            done
            echo "VPCs have been deleted."
        else
            echo "VPCs will not be deleted."
        fi
    else
        echo "No VPCs found to delete."
    fi
}

cleanup_vpc_resources() {

    VPCID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-blueprints-workshop" --query "Vpcs[*].VpcId" --output text)
    echo $VPCID
    for endpoint in $(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPCID" --query "VpcEndpoints[*].VpcEndpointId" --output text); do
        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $endpoint
    done

    #Dissassociate from VPC lattice
    assoc=$(aws vpc-lattice list-service-network-vpc-associations --vpc-identifier $VPCID | jq ".items[0].arn" -r)
    echo $assoc
    aws vpc-lattice delete-service-network-vpc-association --service-network-vpc-association-identifier $assoc
    sleep 20

    # Get the list of security group IDs associated with the VPC
    security_group_ids=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPCID" --query "SecurityGroups[*].GroupId" --output json)

    # Check if any security groups were found
    if [ -z "$security_group_ids" ]; then
        echo "No security groups found in VPC $VPCID"
    else
        echo "security_group_ids=$security_group_ids"

        # Loop through the security group IDs and delete each security group
        for group_id in $(echo "$security_group_ids" | jq -r '.[]'); do
            echo "Deleting security group $group_id"
            aws ec2 delete-security-group --group-id "$group_id"
        done
    fi
}



#cleanup_vpc_resources
delete_vpc_endpoints

# # clean everything else
terraform destroy -auto-approve || true

#Do it 2 tims to be sure to delete everything
#cleanup_vpc_resources
delete_vpcs

terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo "Success: VPC $VPCID deleted successfully."
else
    echo "Error: Failed to delete VPC $VPCID, you may need to do some manuals cleanups"
fi

