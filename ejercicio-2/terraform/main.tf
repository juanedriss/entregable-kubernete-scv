terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-matomo"
}

# 1) Espacio de nombres para aislar los recursos de la plataforma
resource "kubernetes_namespace" "tracking_ns" {
  metadata {
    name = "tracking-space"
  }
}

# 2) Secreto con las credenciales necesarias para MariaDB
resource "kubernetes_secret" "db_auth_secret" {
  metadata {
    name      = "db-auth"
    namespace = kubernetes_namespace.tracking_ns.metadata[0].name
  }

  type = "Opaque"

  data = {
    MYSQL_ROOT_PASSWORD = var.analytics_root_pass
    MYSQL_DATABASE      = var.analytics_db_name
    MYSQL_USER          = var.analytics_db_user
    MYSQL_PASSWORD      = var.analytics_db_pass
  }

  depends_on = [kubernetes_namespace.tracking_ns]
}

# ConfigMap con un script SQL que se ejecutará al iniciar MariaDB
resource "kubernetes_config_map" "mariadb_bootstrap" {
  metadata {
    name      = "mariadb-bootstrap"
    namespace = kubernetes_namespace.tracking_ns.metadata[0].name
  }

  data = {
    "init.sql" = "SET SESSION sql_mode='';"
  }

  depends_on = [kubernetes_namespace.tracking_ns]
}

# 3) Volumen persistente para MariaDB (hostPath) -> los datos permanecen en el host
resource "kubernetes_persistent_volume" "mariadb_storage" {
  metadata {
    name = "mariadb-storage"
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    capacity = {
      storage = "1Gi"
    }

    access_modes = ["ReadWriteOnce"]

    storage_class_name                 = "standard"
    persistent_volume_reclaim_policy   = "Retain"

    persistent_volume_source {
      host_path {
        path = "C:\\data\\mariadb"
      }
    }
  }

  depends_on = [kubernetes_namespace.tracking_ns]
}

resource "kubernetes_persistent_volume_claim" "mariadb_claim" {
  metadata {
    name      = "mariadb-claim"
    namespace = kubernetes_namespace.tracking_ns.metadata[0].name
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    # Se desactiva el uso de StorageClass por defecto
    storage_class_name = ""

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    # Se vincula explícitamente con el PV creado manualmente
    volume_name = kubernetes_persistent_volume.mariadb_storage.metadata[0].name
  }

  wait_until_bound = true
}

# Volumen persistente para Matomo (hostPath)
resource "kubernetes_persistent_volume" "matomo_storage" {
  metadata {
    name = "matomo-storage"
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    capacity = {
      storage = "1Gi"
    }

    access_modes = ["ReadWriteOnce"]

    storage_class_name               = "standard"
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "C:\\data\\matomo"
      }
    }
  }

  depends_on = [kubernetes_namespace.tracking_ns]
}

resource "kubernetes_persistent_volume_claim" "matomo_claim" {
  metadata {
    name      = "matomo-claim"
    namespace = kubernetes_namespace.tracking_ns.metadata[0].name
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    # También sin StorageClass para usar el PV definido
    storage_class_name = ""

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    volume_name = kubernetes_persistent_volume.matomo_storage.metadata[0].name
  }

  wait_until_bound = true
}

# 4) Deployment de MariaDB
resource "kubernetes_deployment" "mariadb_core" {
  metadata {
    name      = "mariadb-core"
    namespace = kubernetes_namespace.tracking_ns.metadata[0].name
    labels = {
      app = "mariadb-db"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mariadb-db"
      }
    }

    template {
      metadata {
        labels = {
          app = "mariadb-db"
        }
      }

      spec {
        container {
          name  = "mariadb"
          image = "mariadb:latest"

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_auth_secret.metadata[0].name
                key  = "MYSQL_ROOT_PASSWORD"
              }
            }
          }

          env {
            name = "MYSQL_DATABASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_auth_secret.metadata[0].name
                key  = "MYSQL_DATABASE"
              }
            }
          }

          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_auth_secret.metadata[0].name
                key  = "MYSQL_USER"
              }
            }
          }

          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_auth_secret.metadata[0].name
                key  = "MYSQL_PASSWORD"
              }
            }
          }

          port {
            container_port = 3306
          }

          volume_mount {
            name       = "mariadb-data"
            mount_path = "/var/lib/mysql"
          }

          volume_mount {
            name       = "bootstrap-scripts"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }

        volume {
          name = "mariadb-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mariadb_claim.metadata[0].name
          }
        }

        volume {
          name = "bootstrap-scripts"
          config_map {
            name = kubernetes_config_map.mariadb_bootstrap.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_config_map.mariadb_bootstrap]
}

resource "kubernetes_service" "mariadb_svc" {
  metadata {
    name      = "mariadb-svc"
    namespace = kubernetes_namespace.tracking_ns.metadata[0].name
  }

  spec {
    selector = {
      app = "mariadb-db"
    }

    port {
      port        = 3306
      target_port = 3306
    }
  }
}

# 5) Deployment de Matomo (usa la imagen personalizada en Docker Hub)
resource "kubernetes_deployment" "tracker_app" {
  metadata {
    name      = "tracker-app"
    namespace = kubernetes_namespace.tracking_ns.metadata[0].name
    labels = {
      app = "tracker"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "tracker"
      }
    }

    template {
      metadata {
        labels = {
          app = "tracker"
        }
      }

      spec {
        container {
          name  = "matomo"
          image = "${var.registry_owner}/matomo-custom:latest"

          env {
            name  = "MATOMO_DATABASE_HOST"
            value = kubernetes_service.mariadb_svc.metadata[0].name
          }

          env {
            name  = "MATOMO_DATABASE_ADAPTER"
            value = "mysql"
          }

          env {
            name  = "MATOMO_DATABASE_TABLES_PREFIX"
            value = "matomo_"
          }

          env {
            name = "MATOMO_DATABASE_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_auth_secret.metadata[0].name
                key  = "MYSQL_USER"
              }
            }
          }

          env {
            name = "MATOMO_DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_auth_secret.metadata[0].name
                key  = "MYSQL_PASSWORD"
              }
            }
          }

          env {
            name = "MATOMO_DATABASE_DBNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_auth_secret.metadata[0].name
                key  = "MYSQL_DATABASE"
              }
            }
          }

          env {
            name  = "PHP_MEMORY_LIMIT"
            value = var.php_mem_limit
          }

          env {
            name  = "PHP_UPLOAD_MAX_FILESIZE"
            value = var.php_max_upload
          }

          env {
            name  = "PHP_POST_MAX_SIZE"
            value = var.php_max_post
          }

          port {
            container_port = 80
          }

          volume_mount {
            name       = "matomo-data"
            mount_path = "/var/www/html"
          }
        }

        volume {
          name = "matomo-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.matomo_claim.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.db_auth_secret]
}

# 6) Servicio de Matomo (NodePort 30081 -> expuesto en 8081 en el host vía kind-config.yaml)
resource "kubernetes_service" "tracker_svc" {
  metadata {
    name      = "tracker-svc"
    namespace = kubernetes_namespace.tracking_ns.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      app = "tracker"
    }

    port {
      port        = 80
      target_port = 80
      node_port   = 30081
    }
  }
}
