variable "region" {
  type = string
}
variable "plan" {
  type    = string
  default = "vc2-1c-1gb"
}
variable "ssh_key_name" {
  type = string
}
variable "os_id" {
  type    = number
  default = 1743
}
variable "domain" {
  type = string
}
variable "subdomain" {
  type = string
}
variable "linux_user_hashed_password" {
  type        = string
  sensitive   = true
  description = "openssl passwd -1"
}
variable "linux_user" {
  type        = string
  default     = "registry"
  description = "Linux user running registry"
}
variable "registry_auth" {
  type        = string
  sensitive   = true
  description = "htpasswd -Bn name password"
}
