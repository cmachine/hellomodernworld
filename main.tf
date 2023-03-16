terraform {
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "./infra/vpc"
  name               = var.name
  environment        = var.environment
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  availability_zones = var.availability_zones
}

module "eks" {
  source          = "./infra/eks"
  name            = var.name
  environment     = var.environment
  region          = var.region
  k8s_version     = var.k8s_version
  vpc_id          = module.vpc.id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  kubeconfig_path = var.kubeconfig_path
}

module "ingress" {
  source      = "./infra/ingress"
  name        = var.name
  environment = var.environment
  region      = var.region
  vpc_id      = module.vpc.id
  cluster_id  = module.eks.cluster_id
}
