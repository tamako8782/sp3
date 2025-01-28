output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "route_table_web_id" {
  value = module.network.route_table_web_id
}

output "route_table_alb_id" {
  value = module.network.route_table_alb_id
}