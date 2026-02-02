
#!/usr/bin/env bash

# Function to check if a cluster context exists
cluster_context_exists() {
    local cluster_name=$1
    kubectl config get-contexts -o name | grep -q "^${cluster_name}$"
}

# Function to update kubeconfig if context doesn't exist
update_kubeconfig_if_needed() {
    local cluster_name=$1
    local alias_name=$2

    if ! cluster_context_exists "$alias_name"; then
        echo "Updating kubeconfig for $cluster_name"
        aws eks --region $AWS_REGION update-kubeconfig --name "$cluster_name" --alias "$alias_name"
    fi
}

update_kubeconfig_if_needed_with_role() {
    local cluster_name=$1
    local alias_name=$2
    local user_alias=$3
    local role_arn=$4

    if ! cluster_context_exists "$alias_name"; then
        echo "Updating kubeconfig for $alias_name"
        aws eks --region $AWS_REGION update-kubeconfig --name "$cluster_name" --alias "$alias_name" --user-alias "$user_alias" --role-arn "$role_arn"
    fi
}

# update_kubeconfig_if_needed "hub-cluster" "hub-cluster"
# update_kubeconfig_if_needed "spoke-staging" "spoke-staging"