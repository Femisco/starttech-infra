################################
# Networking
################################

output "vpc_id" {
  value = module.networking.vpc_id
}

################################
# Compute
################################

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

################################
# Storage
################################

output "frontend_bucket_name" {
  value = module.storage.frontend_bucket_name
}

output "cloudfront_domain" {
  value = module.storage.cloudfront_domain
}

output "redis_endpoint" {
  value = module.storage.redis_endpoint
}
output "ecr_repository_url" {
  value = module.compute.ecr_repository_url
}
