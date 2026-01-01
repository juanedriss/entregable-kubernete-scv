variable "cluster_name" {
  default = "matomo-kind"
}

variable "db_name" {
  description = "Nombre de la base de datos"
}

variable "db_user" {
  description = "Usuario MariaDB"
}

variable "db_password" {
  description = "Password MariaDB"
}

variable "matomo_image" {
  description = "Imagen personalizada de Matomo"
}
