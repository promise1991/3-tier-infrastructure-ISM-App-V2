# Private Hosted Zone To Access Backend Services --------------------------------------
resource "aws_route53_zone" "private" {
  name = "internal.myapp.com"

  vpc {
    vpc_id = aws_vpc.three_tier.id
  }
}

# DNS record pointing to internal ALB -------------------------------------------------------------------
resource "aws_route53_record" "app_alb" { // This creates a DNS record app.internal.myapp.com that points to our internal ALB, so we can access it using a friendly name instead of the ALB's default DNS name.
  zone_id = aws_route53_zone.private.zone_id
  name    = "app.internal.myapp.com"
  type    = "A"

  alias {                                            // Alias record that points to the internal ALB instead of an IP address, so it automatically updates if the ALB's IPs change.
    name                   = aws_lb.app_alb.dns_name // The DNS name of the internal ALB
    zone_id                = aws_lb.app_alb.zone_id  // The hosted zone ID of the internal ALB
    evaluate_target_health = true                    // Route53 will check the health of the ALB and only route traffic to it if it's healthy, improving reliability.
  }
}


# ----------------------------------------------------------------
# PUBLIC HOSTED ZONE FOR FRONTEND WEBSITE
# ----------------------------------------------------------------
resource "aws_route53_zone" "public" { // This is where we manage our public domain and subdomains like www.promiseopah.name.ng
  name = "promiseopah.name.ng"
}

# ----------------------------------------------------------------
# ACM SSL CERTIFICATE - encrypted secure traffic, security lock 🔒 for your website.
# ----------------------------------------------------------------
resource "aws_acm_certificate" "main" {
  domain_name       = "promiseopah.name.ng"
  validation_method = "DNS" // AWS verifies domain ownership using DNS records.

  subject_alternative_names = [ // both root domain and www subdomain are covered by this cert
    "www.promiseopah.name.ng"
  ]

  lifecycle { // Wait for DNS validation to complete before applying other resources that depend on this cert
    create_before_destroy = true
  }
}

# DNS validation records
resource "aws_route53_record" "cert_validation" { // For each domain validation option provided by ACM, create a corresponding Route53 record to prove ownership of the domain. This is required for ACM to issue the SSL certificate.
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => { // Loop through each domain validation option (for root and www) and create a Route53 record for it
      name   = dvo.resource_record_name                                                  // The name of the DNS record ACM gives us to create for validation, e.g. _abc123.promiseopah.name.ng
      record = dvo.resource_record_value                                                 // The value of the DNS record ACM gives us to create for validation, e.g. _abc123.acm-validations.aws
      type   = dvo.resource_record_type                                                  // The type of DNS record ACM gives us to create for validation, e.g. CNAME
    }
  }

  zone_id = aws_route53_zone.public.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "main" {       // This resource tells Terraform to wait until the ACM certificate is validated (i.e. the DNS records we created are verified) before proceeding with any resources that depend on the certificate, such as the ALB listener.
  certificate_arn         = aws_acm_certificate.main.arn // The ARN of the ACM certificate we want to validate
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ----------------------------------------------------------------
# UPDATE WEB ALB LISTENER — HTTPS
# ----------------------------------------------------------------
resource "aws_lb_listener" "https" { // This updates the existing web ALB listener to use HTTPS on port 443, with the SSL certificate we validated. It also forwards traffic to the same target group as the HTTP listener.
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" // This is a modern security policy that supports TLS 1.2 and 1.3, ensuring strong encryption for your website visitors.
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  default_action { // This is the same target group as the HTTP listener, so both HTTP and HTTPS traffic will be routed to the same backend servers. The HTTP listener will redirect to HTTPS, so all traffic will ultimately be encrypted.
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn // The ARN of the target group that the ALB will forward traffic to, which is where our web servers are registered.
  }
}

# Redirect HTTP → HTTPS on web ALB
resource "aws_lb_listener_rule" "http_redirect" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# ----------------------------------------------------------------
# CLOUDFRONT DISTRIBUTION
# ----------------------------------------------------------------
resource "aws_cloudfront_distribution" "main" { // This creates a CloudFront distribution that serves our website globally with low latency. It uses the web ALB as the origin, and the ACM certificate for HTTPS. It also sets up caching and forwarding of headers and cookies.
  enabled             = true
  aliases             = ["promiseopah.name.ng", "www.promiseopah.name.ng"]
  default_root_object = "index.html"

  origin {
    domain_name = aws_lb.web_alb.dns_name
    origin_id   = "web-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "web-alb"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "main-cloudfront"
  }
}

# ----------------------------------------------------------------
# ROUTE 53 RECORDS → CLOUDFRONT
# ----------------------------------------------------------------
resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "promiseopah.name.ng"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "www.promiseopah.name.ng"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}