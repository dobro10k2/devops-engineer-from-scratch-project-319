# ==========================================
# 1. ЛОГИРОВАНИЕ
# ==========================================
resource "yandex_logging_group" "k8s_logs" {
  name             = "bulletin-k8s-logs"
  folder_id        = var.folder_id
  retention_period = "72h"
}

# ==========================================
# 2. ПРАВА ДОСТУПА (SERVICE ACCOUNT)
# ==========================================
resource "yandex_iam_service_account" "observability_sa" {
  name        = "observability-sa"
  description = "SA for logging and monitoring"
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

# ==========================================
# 3. ДАШБОРД (МЕТРИКИ ПРИЛОЖЕНИЯ - PROMQL)
# ==========================================
resource "yandex_monitoring_dashboard" "infrastructure_dashboard" {
  name        = "bulletin-board-infrastructure"
  title       = "Bulletin Board - Infrastructure Metrics"
  description = "VM metrics: CPU, Memory, Disk, Network"
  folder_id   = var.folder_id

  widgets {
    position {
      x = 0
      y = 0
      w = 12
      h = 8
    }
    chart {
      chart_id = "cpu-utilization"
      title    = "CPU Utilization (%)"
      queries {
        target {
          query = "{folderId=\"${var.folder_id}\",service=\"compute\",name=\"cpu_utilization\"}"
        }
      }
    }
  }

  widgets {
    position {
      x = 12
      y = 0
      w = 12
      h = 8
    }
    chart {
      chart_id = "disk.read_errors"
      title    = "Disk Read Errors (op/sec)"
      queries {
        target {
          query = "{folderId=\"${var.folder_id}\",service=\"compute\",name=\"disk.read_errors\"}"
        }
      }
    }
  }

  widgets {
    position {
      x = 0
      y = 8
      w = 12
      h = 8
    }
    chart {
      chart_id = "network-received"
      title    = "Network Received (bytes/sec)"
      queries {
        target {
          query = "{folderId=\"${var.folder_id}\",service=\"compute\",name=\"network_received_bytes\"}"
        }
      }
    }
  }

  widgets {
    position {
      x = 12
      y = 8
      w = 12
      h = 8
    }
    chart {
      chart_id = "network-sent"
      title    = "Network Sent (bytes/sec)"
      queries {
        target {
          query = "{folderId=\"${var.folder_id}\",service=\"compute\",name=\"network_sent_bytes\"}"
        }
      }
    }
  }

  widgets {
    position {
      x = 0
      y = 16
      w = 12
      h = 8
    }
    chart {
      chart_id = "disk-read"
      title    = "Disk Read (bytes/sec)"
      queries {
        target {
          query = "{folderId=\"${var.folder_id}\",service=\"compute\",name=\"disk.read_bytes\"}"
        }
      }
    }
  }

  widgets {
    position {
      x = 12
      y = 16
      w = 12
      h = 8
    }
    chart {
      chart_id = "disk-write"
      title    = "Disk Write (bytes/sec)"
      queries {
        target {
          query = "{folderId=\"${var.folder_id}\",service=\"compute\",name=\"disk.write_bytes\"}"
        }
      }
    }
  }
}

