variable "region" {
  type = string
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
variable "user_hashed_password" {
  type        = string
  sensitive   = true
  description = "openssl passwd -1"
}
variable "registry_auth" {
  type        = string
  sensitive   = true
  description = "htpasswd -Bn name password"
}
