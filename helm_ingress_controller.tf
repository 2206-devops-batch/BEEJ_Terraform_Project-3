# helm ingress controller
# module "nginx-controller" {
#   source                      = "terraform-iaac/nginx-controller/helm"
#   metrics_enabled             = true
#   disable_heavyweight_metrics = true

#   additional_set = [
#     {
#       name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
#       value = "nlb"
#       type  = "string"
#     },
#     {
#       name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
#       value = "true"
#       type  = "string"
#     }
#   ]
# }

resource "helm_release" "ingress_nginx" {
  name            = "ingress-nginx-controller"
  repository      = "https://kubernetes.github.io/ingress-nginx"
  chart           = "ingress-nginx"
  version         = "4.2.0"
  namespace       = "kube-system"
  cleanup_on_fail = true
  atomic          = true

  # values = [
  #   "${file("./ingress-nginx-controller-aws.yaml")}"
  # ]

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
    type  = "string"
  }
  set {
    name  = "ccontroller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
    type  = "string"
  }
  set {
    name  = "ccontroller.metrics.enabled"
    value = "true"
    type  = "string"
  }
}

output "Ingress_Nginx_Controller_Namespace" {
  value = helm_release.ingress_nginx.namespace
}
