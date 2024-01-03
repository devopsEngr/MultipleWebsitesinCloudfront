data "aws_route53_zone" "public" {
  name = var.domain # base domain route53
}

locals {
  subdomainsList = {

    for pv in var.project_version : pv.project => {
      subdomain_name = "${pv.project}.${var.domain}" 
      #target_distribution    = aws_cloudfront_distribution.engagement_hub_subdomains[pv.project]
    }
  }
}

module "acm_certificate_domain" {
  source = "../../modules/acm_certificate" # for base domain tst.gryphon.com
  domain = var.domain
  env    = var.env
  region = var.region
  dns_name = var.dns_name
  zoneid = data.aws_route53_zone.public.id
  providers = {
    aws        = aws
    aws.global = aws.global
  }
}

module "acm_certificate_subdomain" {
  env    = var.env
  region = var.region
  dns_name = var.dns_name
  zoneid = data.aws_route53_zone.public.id
  for_each = local.subdomainsList
  source   = "../../modules/acm_certificate" # for sub domains pheonix.tst.gryphon.com
  domain   = each.value.subdomain_name
  providers = {
    aws        = aws
    aws.global = aws.global
  }
  # zone_id = data.aws_route53_zone.public.id
  depends_on = [module.acm_certificate_domain]
}
# resource "aws_acm_certificate" "subdomain_certs" {
#   provider = aws.global 
#   for_each = { for cert in local.subdomains1 : cert.name => cert }
#   domain_name              = "www.${each.value.name}"
#   subject_alternative_names = ["www.${each.value.name}", each.value.name]
#   validation_method        = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }
# resource "aws_acm_certificate" "this" {
#   provider = aws.global   # required for cloudfront
#   domain_name       = "www.${var.domain}"
#   subject_alternative_names = ["www.${var.domain}", "${var.domain}"]
#   validation_method = "DNS"
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "cert_validation" {
#   allow_overwrite = true
#   # name            = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_name
#   # records         = [ tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_value ]
#   # type            = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_type
#   # zone_id  = data.aws_route53_zone.public.id
#   # ttl      = 60

#   for_each = {
#     for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
#       name    = dvo.resource_record_name
#       record  = dvo.resource_record_value
#       type    = dvo.resource_record_type
#       zone_id = data.aws_route53_zone.public.id
#     }
#   }

#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = each.value.zone_id

#   # lifecycle {
#   #   ignore_changes = all
#   # }
# }

# resource "aws_acm_certificate_validation" "this" {
#   provider = aws.global
#   certificate_arn         = aws_acm_certificate.this.arn
# #  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
#   # lifecycle {
#   #   ignore_changes = all
#   # }
# }

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "www.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.engagement_hub.domain_name
    zone_id                = aws_cloudfront_distribution.engagement_hub.hosted_zone_id
    evaluate_target_health = false
  }
  #  lifecycle {
  #    ignore_changes = all
  #  }
}



resource "aws_route53_record" "non-www" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.engagement_hub.domain_name
    zone_id                = aws_cloudfront_distribution.engagement_hub.hosted_zone_id
    evaluate_target_health = false
  }
  #  lifecycle {
  #    ignore_changes = all
  #  }
}

# output "acm_certificate_keys" {
#   value = keys(aws_acm_certificate.subdomain_certs)
# }

# locals {
#   subdomains1 = {

#     for pv in var.project_version : pv.project => {
#       name                   = "${pv.project}.${var.domain}"
#       #target_distribution    = aws_cloudfront_distribution.engagement_hub_subdomains[pv.project]
#     }
#   }
# }
# resource "aws_acm_certificate" "subdomain_certs" {
#   provider = aws.global 
#   for_each = { for cert in local.subdomains1 : cert.name => cert }
#   domain_name              = "www.${each.value.name}"
#   subject_alternative_names = ["www.${each.value.name}", each.value.name]
#   validation_method        = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }
# resource "aws_route53_record" "cert_validation_subdomains" {
#   for_each = {
#     for cert in aws_acm_certificate.subdomain_certs : cert.domain_name => {
#       name    = tolist(cert.domain_validation_options)[0].resource_record_name
#       record  = tolist(cert.domain_validation_options)[0].resource_record_value
#       type    = tolist(cert.domain_validation_options)[0].resource_record_type
#       zone_id = data.aws_route53_zone.public.id
#     }
#   }

#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.public.id
# }

# resource "aws_route53_record" "cert_validation_subdomains" {
#   for_each = aws_acm_certificate.subdomain_certs

#   dynamic "record" {
#     for_each = toset([for option in each.value.domain_validation_options : {
#       name    = option.resource_record_name
#       record  = option.resource_record_value
#       type    = option.resource_record_type
#       zone_id = data.aws_route53_zone.public.id
#     }])

#     content {
#       name    = record.value.name
#       records = [record.value.record]
#       ttl     = 60
#       type    = record.value.type
#       zone_id = record.value.zone_id
#     }
#   }
# }



# resource "aws_acm_certificate_validation" "subdomain_certs_validation"{
#   provider = aws.global
#   for_each = aws_acm_certificate.subdomain_certs

#   certificate_arn         = each.value.arn
#   depends_on = [aws_acm_certificate.subdomain_certs, aws_route53_record.cert_validation_subdomains]
#   validation_record_fqdns = [for option in each.value.domain_validation_options : option.resource_record_name]

# }

locals {
  subdomains = {

    for pv in var.project_version : pv.project => {
      name                = "${pv.project}.${var.domain}"
      target_distribution = aws_cloudfront_distribution.engagement_hub_subdomains[pv.project]
    }
  }
}
resource "aws_route53_record" "subdomains" {
  for_each = local.subdomains

  zone_id = data.aws_route53_zone.public.zone_id
  name    = "www.${each.value.name}"
  type    = "A"

  alias {
    name                   = each.value.target_distribution.domain_name
    zone_id                = each.value.target_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "non-www_subdomains" {
  for_each = local.subdomains

  zone_id = data.aws_route53_zone.public.zone_id
  name    = each.value.name
  type    = "A"

  alias {
    name                   = each.value.target_distribution.domain_name
    zone_id                = each.value.target_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
