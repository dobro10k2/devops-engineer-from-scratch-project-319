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

# ==========================================
# 2. АВТОМАТИЗАЦИЯ ДАШБОРДОВ (Yandex Monitoring)
# ==========================================
resource "yandex_monitoring_dashboard" "app_dashboard" {
  name        = "bulletin-board-dashboard"
  title       = "Bulletin Board Application Metrics"
  description = "Created by Terraform"
  folder_id   = var.folder_id

  # 1. ТРАФИК: Количество запросов в секунду (RPS)
  widgets {
    position {
      x = 0
      y = 0
      w = 12
      h = 4
    }
    chart {
      chart_id = "chart-rps"
      title    = "Traffic (Requests Per Second)"
      queries {
        target {
          query  = "sum(rate(http_server_requests_seconds_count{application=\"bulletin-board\"}[1m]))"
          hidden = false
        }
      }
    }
  }

  # 2. ЗАДЕРЖКА: 95-й перцентиль времени ответа (Latency)
  widgets {
    position {
      x = 12
      y = 0
      w = 12
      h = 4
    }
    chart {
      chart_id = "chart-latency"
      title    = "Request Latency (95th percentile)"
      queries {
        target {
          query  = "histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket{application=\"bulletin-board\"}[5m])) by (le))"
          hidden = false
        }
      }
    }
  }

  # 3. ОШИБКИ: 5xx (Ошибки сервера)
  widgets {
    position {
      x = 0
      y = 4
      w = 12
      h = 4
    }
    chart {
      chart_id = "chart-5xx"
      title    = "HTTP 5xx Server Errors"
      queries {
        target {
          query  = "sum(rate(http_server_requests_seconds_count{status=~\"5..\", application=\"bulletin-board\"}[5m]))"
          hidden = false
        }
      }
    }
  }

  # 4. РЕСУРСЫ: Использование CPU приложением
  widgets {
    position {
      x = 12
      y = 4
      w = 12
      h = 4
    }
    chart {
      chart_id = "chart-cpu"
      title    = "Application CPU Usage"
      queries {
        target {
          query  = "rate(system_cpu_usage{application=\"bulletin-board\"}[5m])"
          hidden = false
        }
      }
    }
  }

  # 5. РЕСУРСЫ: Использование памяти JVM Heap (Куча)
  widgets {
    position {
      x = 0
      y = 8
      w = 24 # На всю ширину экрана для красоты
      h = 4
    }
    chart {
      chart_id = "chart-mem"
      title    = "JVM Heap Memory Used"
      queries {
        target {
          query  = "sum(jvm_memory_used_bytes{area=\"heap\", application=\"bulletin-board\"})"
          hidden = false
        }
      }
    }
  }
}
