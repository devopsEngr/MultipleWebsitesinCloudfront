resource "aws_acm_certificate" "this" {
  provider = aws.global   # required for cloudfront
  domain_name       = "www.${var.domain}"
  subject_alternative_names = ["www.${var.domain}", "${var.domain}"]
  validation_method = "DNS"
   lifecycle {
    create_before_destroy = true
  }
  
}

resource "aws_route53_record" "cert_validation" {
 
  allow_overwrite = true
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = var.zoneid
    }
  }

  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id

}
resource "aws_acm_certificate_validation" "this" {
  provider = aws.global
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

