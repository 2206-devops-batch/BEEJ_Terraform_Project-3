# helm ingress controller
module "nginx-controller" {
  source                      = "terraform-iaac/nginx-controller/helm"
  metrics_enabled             = true
  disable_heavyweight_metrics = true

  additional_set = [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
      value = "true"
      type  = "string"
    }
  ]
}

output "Ingress_Controller_Namespace" {
  value = module.nginx-controller.namespace
}
