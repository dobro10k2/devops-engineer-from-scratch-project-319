# ==========================================
# 1. ЛОГИРОВАНИЕ И ПРАВА ДОСТУПА
# ==========================================
resource "yandex_logging_group" "k8s_logs" {
  name             = "bulletin-k8s-logs"
  folder_id        = var.folder_id
  retention_period = "72h" # Храним логи 3 дня
}

resource "yandex_iam_service_account" "observability_sa" {
  name        = "observability-sa"
  description = "SA for Fluent Bit and Prometheus Agent"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_logging_writer" {
  folder_id = var.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.observability_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_metrics_writer" {
  folder_id = var.folder_id
  role      = "monitoring.editor"
  member    = "serviceAccount:${yandex_iam_service_account.observability_sa.id}"
}

resource "yandex_iam_service_account_api_key" "observability_key" {
  service_account_id = yandex_iam_service_account.observability_sa.id
}
