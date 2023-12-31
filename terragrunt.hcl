terraform {
  source = "git@github.com:yegorovev/tf_aws_network.git?ref=v1.0.2"
}

locals {
  parameters_file = get_env("TG_PARAMS_FILE", "common_default_net.hcl")

  env_vars             = read_terragrunt_config(find_in_parent_folders(local.parameters_file)).inputs
  profile              = local.env_vars.profile
  region               = local.env_vars.region
  bucket_name          = local.env_vars.bucket_name
  lock_table           = local.env_vars.lock_table
  key                  = local.env_vars.key
  tags                 = jsonencode(local.env_vars.tags)
  vpc_cidr             = local.env_vars.vpc_cidr
  vpc_name             = local.env_vars.vpc_name
  subnets_list         = local.env_vars.subnets_list
  igw_name             = local.env_vars.igw_name
  application_sg       = local.env_vars.application_sg
  enable_dns_hostnames = local.env_vars.enable_dns_hostnames
  rt                   = local.env_vars.rt
  rt_associations      = local.env_vars.rt_associations
  routes               = local.env_vars.routes
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.bucket_name
    key            = local.key
    region         = local.region
    encrypt        = true
    dynamodb_table = local.lock_table
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  profile = "${local.profile}"
  region  = "${local.region}"
  default_tags {
    tags = jsondecode(<<INNEREOF
${local.tags}
INNEREOF
)
  }
}
EOF
}

inputs = {
  vpc_cidr             = local.vpc_cidr
  vpc_name             = local.vpc_name
  subnets_list         = local.subnets_list
  igw_name             = local.igw_name
  application_sg       = local.application_sg
  enable_dns_hostnames = local.enable_dns_hostnames
  rt                   = local.rt
  rt_associations      = local.rt_associations
  routes               = local.routes
}