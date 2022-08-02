resource "helm_release" "ingress_nginx_chart" {
  name       = "ingress-nginx-chart"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.2.0"
  # namespace       = "kube-system"
  cleanup_on_fail = true
  atomic          = true

  values = [
    "${file("./charts/values-nginx.yaml")}"
  ]
}

# resource "helm_release" "jenkins_chart" {
#   name       = "jenkins_ingress_chart"
#   repository = "https://charts.jenkins.io"
#   chart      = "jenkins/jenkins"
#   version    = "4.1.13"
#   # namespace       = "kube-system"
#   cleanup_on_fail = true
#   atomic          = true

#   values = [
#     "${file("./charts/values-jenkins.yaml")}"
#   ]
# }

output "Ingress_Nginx_Controller_Namespace" {
  value = helm_release.ingress_nginx_chart.namespace
}
# output "Jenkins_Namespace" {
#   value = helm_release.jenkins_chart.namespace
# }
