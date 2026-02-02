output "vpc_ids" {
  description = "Map of VPC IDs for hub and spoke clusters"
  value = {
    for k, v in module.vpc : k => v.vpc_id
  }
}

output "private_subnets" {
  description = "Map of private subnet IDs for hub and spoke clusters"
  value = {
    for k, v in module.vpc : k => v.private_subnets
  }
}


output "vpc_names" {
  description = "Map of VPC names"
  value = {
    for k, v in local.vpcs : k => v.name
  }
}
