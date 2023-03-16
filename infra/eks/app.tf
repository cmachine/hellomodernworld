/*
 For demo purposes we deploy a small app using the kubernetes_ingress ressource
 and a fargate profile
*/


resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "${var.name}-eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_eks_fargate_profile" "main" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "fp-default"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.private_subnets.*.id

  selector {
    namespace = "default"
  }

  selector {
    namespace = "hellomodernworld-app"
  }

  timeouts {
    create = "30m"
    delete = "60m"
  }
}

resource "kubernetes_namespace" "example" {
  metadata {
    labels = {
      app = "hellomodernworld"
    }

    name = "hellomodernworld-app"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "hellomodernworld"
    namespace = "hellomodernworld-app"
    labels = {
      app = "hellomodernworld"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "hellomodernworld"
      }
    }

    template {
      metadata {
        labels = {
          app = "hellomodernworld"
        }
      }

      spec {
        container {
          image = "csocha/hellomodernworld"
          name  = "hellomodernworld"

          port {
            container_port = 8080
          }
        }
      }
    }
  }

  depends_on = [aws_eks_fargate_profile.main]
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "hellomodernworld"
    namespace = "hellomodernworld-app"
  }
  spec {
    selector = {
      app = "hellomodernworld"
    }

    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.app]
}

resource "kubernetes_ingress" "app" {
  metadata {
    name      = "hellomodernworld-ingress"
    namespace = "hellomodernworld-app"
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
    labels = {
      "app" = "hellomodernworld-ingress"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = "service-hellomodernworld"
            service_port = 8080
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.app]
}
