resource "aws_cloudfront_distribution" "static-www" {
    //代替ドメイン
    //aliases = ["watanabe.dbgso.com"]
    web_acl_id = aws_wafv2_web_acl.default.arn
    origin {
        domain_name = aws_lb.awsLb.dns_name
        origin_id = aws_lb.awsLb.dns_name
        custom_header {
          name  = "x-pre-shared-key"
          value = "${var.forwardKey}"
        }
      custom_origin_config {
        http_port              = "80"
        https_port             = "443"
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }

    enabled =  true

    default_cache_behavior {
        allowed_methods = [ "GET", "HEAD" ]
        cached_methods = [ "GET", "HEAD" ]
        target_origin_id = aws_lb.awsLb.dns_name
        
        forwarded_values {
            query_string = false
            headers = ["Host"]

            cookies {
              forward = "none"
            }
        }

        viewer_protocol_policy = "redirect-to-https"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    restrictions {
      geo_restriction {
          restriction_type = "whitelist"
          locations = [ "JP" ]
      }
    }
    viewer_certificate {
        cloudfront_default_certificate = true
        //証明書の設定
/*         acm_certificate_arn = var.acmArm
        ssl_support_method = "sni-only"
        minimum_protocol_version = "TLSv1"
 */    }
}

resource "aws_cloudfront_origin_access_identity" "static-www" {}