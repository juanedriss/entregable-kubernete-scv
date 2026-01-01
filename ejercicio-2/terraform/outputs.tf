output "tracker_url" {
  value       = "http://localhost:8081"
  description = "Dirección local para acceder a la plataforma de analítica"
}

output "active_namespace" {
  value       = kubernetes_namespace.tracking_ns.metadata[0].name
  description = "Espacio de nombres donde se desplegaron todos los componentes"
}

output "database_service" {
  value       = kubernetes_service.mariadb_svc.metadata[0].name
  description = "Identificador del servicio asociado a MariaDB"
}

output "analytics_service" {
  value       = kubernetes_service.tracker_svc.metadata[0].name
  description = "Nombre del servicio que expone la aplicación de analítica"
}

output "database_pvc" {
  value       = kubernetes_persistent_volume_claim.mariadb_claim.metadata[0].name
  description = "Reclamación de volumen persistente utilizada por MariaDB"
}

output "analytics_pvc" {
  value       = kubernetes_persistent_volume_claim.matomo_claim.metadata[0].name
  description = "Reclamación de volumen persistente empleada por Matomo"
}

output "credentials_secret" {
  value       = kubernetes_secret.db_auth_secret.metadata[0].name
  description = "Secreto que almacena las credenciales de acceso a la base de datos"
  sensitive   = true
}
