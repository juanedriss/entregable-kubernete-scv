variable "analytics_db_name" {
  type        = string
  default     = "matomodb"
  description = "Identificador asignado a la base de datos utilizada por la plataforma analítica"
}

variable "analytics_db_user" {
  type        = string
  default     = "matomo"
  description = "Cuenta de acceso destinada a gestionar la base de datos"
}

variable "analytics_db_pass" {
  type        = string
  default     = "matomo_pass"
  description = "Clave asociada al usuario de la base de datos"
}

variable "analytics_root_pass" {
  type        = string
  default     = "root_pass"
  description = "Contraseña del usuario administrador de MariaDB"
}

variable "registry_owner" {
  type        = string
  description = "Nombre del propietario del repositorio en Docker Hub donde se alojará la imagen personalizada"
}

variable "php_mem_limit" {
  type        = string
  default     = "512M"
  description = "Cantidad máxima de memoria permitida para la ejecución de PHP"
}

variable "php_max_upload" {
  type        = string
  default     = "512M"
  description = "Tamaño límite permitido para archivos subidos mediante PHP"
}

variable "php_max_post" {
  type        = string
  default     = "512M"
  description = "Capacidad máxima de datos enviados en peticiones POST"
}
