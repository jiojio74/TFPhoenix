output "public_subnet" {
  value = module.network.subnet
}

output "database" {
  value     = module.database.db_config
  sensitive = true
}

output "documentDB" {
  value     = module.database.docdb_config
}

output "alb" {
  value = module.network.alb.lb.dns_name
}

output "security_group" {
  value = module.instance.security_group
}