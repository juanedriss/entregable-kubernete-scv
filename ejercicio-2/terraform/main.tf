terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "this" {
  name           = var.cluster_name
  config_path    = "${path.module}/kind-config.yaml"
  wait_for_ready = true
}

provider "kubernetes" {
  config_path = kind_cluster.this.kubeconfig_path
}

resource "kubernetes_persistent_volume" "mariadb" {
  metadata { name = "pv-mariadb" }

  spec {
    capacity = { storage = "2Gi" }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"

    host_path { path = "/kind/data/mariadb" }
  }
}

resource "kubernetes_persistent_volume_claim" "mariadb" {
  metadata { name = "pvc-mariadb" }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = { storage = "2Gi" }
    }
    volume_name = kubernetes_persistent_volume.mariadb.metadata[0].name
  }
}

resource "kubernetes_deployment" "mariadb" {
  metadata { name = "mariadb" }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "mariadb" }
    }

    template {
      metadata { labels = { app = "mariadb" } }

      spec {
        container {
          name  = "mariadb"
          image = "mariadb:10.6"

          env {
            name  = "MYSQL_DATABASE"
            value = var.db_name
          }
          env {
            name  = "MYSQL_USER"
            value = var.db_user
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = var.db_password
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "rootpass"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/mysql"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mariadb.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "matomo" {
  metadata { name = "matomo" }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "matomo" }
    }

    template {
      metadata { labels = { app = "matomo" } }

      spec {
        container {
          name  = "matomo"
          image = var.matomo_image

          env {
            name  = "MATOMO_DATABASE_HOST"
            value = "mariadb"
          }
          env {
            name  = "MATOMO_DATABASE_USERNAME"
            value = var.db_user
          }
          env {
            name  = "MATOMO_DATABASE_PASSWORD"
            value = var.db_password
          }
          env {
            name  = "MATOMO_DATABASE_DBNAME"
            value = var.db_name
          }

          port { container_port = 80 }

          volume_mount {
            name       = "data"
            mount_path = "/var/www/html"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.matomo.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "matomo" {
  metadata { name = "matomo" }

  spec {
    type = "NodePort"

    selector = { app = "matomo" }

    port {
      port        = 80
      target_port = 80
      node_port   = 30081
    }
  }
}
