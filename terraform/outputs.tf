output "master_public_ip" {
  description = "Public IP of the master node"
  value       = yandex_compute_instance.master.network_interface[0].nat_ip_address
}

# Изменено: теперь выводит список IP-адресов всех воркеров
output "worker_private_ips" {
  description = "Worker private ips"
  value       = yandex_compute_instance.worker[*].network_interface[0].ip_address
}

output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = yandex_storage_bucket.app_bucket.bucket
}

output "s3_access_key" {
  description = "S3 access key"
  value       = yandex_iam_service_account_static_access_key.storage_key.access_key
  sensitive   = true
}

output "s3_secret_key" {
  description = "S3 secret key"
  value       = yandex_iam_service_account_static_access_key.storage_key.secret_key
  sensitive   = true
}

output "lockbox_secret_id" {
  description = "Lockbox secret ID"
  value       = yandex_lockbox_secret.app.id
}

output "log_group_id" {
  description = "Log group ID"
  value       = yandex_logging_group.k8s_logs.id
}

output "observability_api_key" {
  description = "Observality API key"
  value       = yandex_iam_service_account_api_key.observability_key.secret_key
  sensitive   = true
}

# Managed Prometheus endpoints
output "prometheus_remote_write_url" {
  value       = "https://monitoring.api.cloud.yandex.net/prometheus/workspaces/${var.prometheus_workspace_id}/api/v1/write"
  description = "Remote Write URL для Prometheus Agent"
}

output "prometheus_remote_read_url" {
  value       = "https://monitoring.api.cloud.yandex.net/prometheus/workspaces/${var.prometheus_workspace_id}/api/v1/read"
  description = "Remote Read URL для Prometheus"
}

output "prometheus_query_url" {
  value       = "https://monitoring.api.cloud.yandex.net/prometheus/workspaces/${var.prometheus_workspace_id}/api/v1/query"
  description = "Query URL для Grafana datasource"
}

output "prometheus_console_url" {
  value       = "https://console.cloud.yandex.ru/folders/${var.folder_id}/monitoring/prometheus"
  description = "Yandex Managed Prometheus Console"
}

output "eso_sa_key_json" {
  description = "ESO SA key JSON"
  value = jsonencode({
    id                 = yandex_iam_service_account_key.eso_auth_key.id
    service_account_id = yandex_iam_service_account_key.eso_auth_key.service_account_id
    created_at         = yandex_iam_service_account_key.eso_auth_key.created_at
    key_algorithm      = yandex_iam_service_account_key.eso_auth_key.key_algorithm
    public_key         = yandex_iam_service_account_key.eso_auth_key.public_key
    private_key        = yandex_iam_service_account_key.eso_auth_key.private_key
  })
  sensitive = true
}
