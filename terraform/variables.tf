variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "yc_token" {
  type      = string
  sensitive = true
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "ssh_public_key" {
  type = string
}

variable "bucket_name" {
  type    = string
  default = "bulletin-board-storage"
}

variable "prometheus_workspace_id" {
  type = string
}
