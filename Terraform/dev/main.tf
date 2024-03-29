# Define the "network" module, which sets up the network resources.
module "network" {
  source       = "../modules/network"
  namespace    = var.namespace
  project_name = var.project_name
}

# Define the "instance" module, which sets up the instance resources.
module "instance" {
  source       = "../modules/instance"
  namespace    = var.namespace
  project_name = var.project_name
  ssh_key      = var.ssh_key
  alb          = module.network.alb
  subnet       = module.network.subnet
  vpc          = module.network.vpc
  db_config    = module.database.db_config
  app_url      = var.app_url
}

# Define the "database" module, which sets up the database resources.
module "database" {
  source             = "../modules/database"
  namespace          = var.namespace
  project_name       = var.project_name
  vpc                = module.network.vpc
  app_security_group = module.instance.security_group
  subnet             = module.network.subnet
}