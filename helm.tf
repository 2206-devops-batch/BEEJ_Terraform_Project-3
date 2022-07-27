provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "nginx-ingress-controller" {
    name = "nginx-ingress-controller"
    repository = "https://charts.bitnami.com/bitnami"
    chart = "ingress-ngiinx"
    version = "4.1.3"
    namespace = "ingress"
    create_namespace = "true"


    set {
      name = "controller.service.type"
      value = "LoadBalancer"
    }
    set {
      name = "controller.autoscaling.enabled"
      valur = "true"
    }
    set {
      name = "controller.autoscaling.minReplicas"
      value = "1"
    }
    set {
      name = "controller.autoscaling.maxReplicas"
      value = "2"
    }
}