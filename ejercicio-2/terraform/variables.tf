variable "cluster_name" {
  type    = string
  default = "matomo-kind"
}

variable "matomo_port_host" {
  type    = number
  default = 8081
}

variable "mariadb_root_password" {
  type    = string
  default = "mariadb_root_pass"
}

variable "mariadb_database" {
  type    = string
  default = "matomo"
}

variable "mariadb_user" {
  type    = string
  default = "matomo"
}

variable "mariadb_password" {
  type    = string
  default = "matomo_pass"
}
