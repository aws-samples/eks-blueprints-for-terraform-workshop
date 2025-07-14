output "configure_kubectl" {
  description = "Configure kubectl: make sure we're logged in with the correct AWS profile and run the following command to update our kubeconfig"
  value       = <<-EOT
    aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}
  EOT
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.eks.cluster_name
}
output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = module.eks.cluster_endpoint
}
output "cluster_certificate_authority_data" {
  description = "Cluster certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
}
output "cluster_region" {
  description = "Cluster region"
  value       = local.region
}

output "cluster_primary_security_group_id" {
  description = "Cluster primary security group"
  value       = module.eks.cluster_primary_security_group_id
}
