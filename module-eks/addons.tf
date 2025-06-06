provider "helm" {
    kubernetes {
        host                   = aws_eks_cluster.eks.endpoint
        cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.eks.token
    }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

data "aws_eks_cluster_auth" "eks" {
    name = aws_eks_cluster.eks.name
}
resource "helm_release" "nginx_ingress" {
    name       = "nginx-ingress"
    repository = "https://kubernetes.github.io/ingress-nginx"
    chart      = "ingress-nginx"
    version    = "4.12.0"
    namespace  = "ingress-nginx"
    create_namespace = true

    values = [file("${path.module}/nginx-ingress-values.yaml")]
    depends_on = [ aws_eks_node_group.eks_node_group ]
}

data "aws_lb" "nginx_ingress" {
  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/nginx-ingress-ingress-nginx-controller"
  }

  depends_on = [helm_release.nginx_ingress]
}

resource "helm_release" "cert_manager" {
    name       = "cert-manager"
    repository = "https://charts.jetstack.io"
    chart      = "cert-manager"
    version    = "1.14.5"
    namespace  = "cert-manager"
    create_namespace = true
    set {
        name  = "installCRDs"
        value = "true"
    }
    depends_on = [ helm_release.nginx_ingress ]
}

resource "kubernetes_manifest" "cluster_issuer" {
    manifest = {
        apiVersion = "cert-manager.io/v1"
        kind       = "ClusterIssuer"
        metadata = {
            name = "http-01-production"
        }
        spec = {
            acme = {
                server = "https://acme-v02.api.letsencrypt.org/directory"
                email  = "support@digitalwitchng.online"
                privateKeySecretRef = {
                    name = "letsencrypt-prod-cluster-issuer"
                }
                solvers = [
                    {
                        http01 = {
                            ingress = {
                                ingressClassName = "external-nginx"
                            }
                        }
                    }
                ]
            }
        }
    }

    depends_on = [helm_release.cert_manager]
}


resource "helm_release" "argocd" {
    name             = "argocd"
    repository       = "https://argoproj.github.io/argo-helm"
    chart            = "argo-cd"
    version          = "5.51.6"
    namespace        = "argocd"
    create_namespace = true
    values = [file("${path.module}/argocd-values.yaml")]
    depends_on = [ helm_release.nginx_ingress, helm_release.cert_manager,kubernetes_manifest.cluster_issuer]
}

resource "kubernetes_ingress_v1" "argocd_ingress" {
    metadata {
        name      = "argocd-ingress"
        namespace = "argocd"
        annotations = {
            "kubernetes.io/ingress.class"                    = "external-nginx"
            "cert-manager.io/cluster-issuer"                 = "http-01-production"
            "nginx.ingress.kubernetes.io/rewrite-target"     = "/"
            "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
        }
    }
    spec {
        ingress_class_name = "external-nginx"

        tls {
            hosts       = ["argocd.${var.domain-name}"]
            secret_name = "argocd-cloudwitches-online"
        }

        rule {
            host = "argocd.${var.domain-name}" 
            http {
                path {
                    path     = "/"
                    path_type = "Prefix"
                    backend {
                        service {
                            name = "argocd-server"
                            port {
                                number = 80
                            }
                        }
                    }
                }
            }
        }
    }

    depends_on = [helm_release.argocd]
}
