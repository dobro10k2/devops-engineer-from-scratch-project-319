variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "yc_token" {
  description = "Yandex Cloud Token"
  type        = string
  sensitive   = true
}

variable "zone" {
  description = "Yandex Cloud Network Zone"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key" {
  description = "Yandex Cloud VM Public Key"
  type        = string
}

variable "bucket_name" {
  description = "Yandex Cloud Bucket Name"
  type        = string
  default     = "bulletin-board-storage"
}

variable "prometheus_workspace_id" {
  description = "Yandex Cloud Prometheus Workspace ID"
  type        = string
}
