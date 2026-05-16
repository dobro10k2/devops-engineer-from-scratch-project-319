resource "random_password" "db_password" {
  length  = 20
  special = false
}

resource "random_password" "app_secret" {
  length  = 32
  special = false
}

resource "yandex_lockbox_secret" "app" {
  name = "bulletin-board-secret"
}

resource "yandex_lockbox_secret_version" "app_version" {
  secret_id = yandex_lockbox_secret.app.id

  entries {
    key        = "DB_USER"
    text_value = "postgres"
  }

  entries {
    key        = "DB_PASSWORD"
    text_value = random_password.db_password.result
  }

  entries {
    key        = "S3_ACCESS_KEY"
    text_value = yandex_iam_service_account_static_access_key.storage_key.access_key
  }

  entries {
    key        = "S3_SECRET_KEY"
    text_value = yandex_iam_service_account_static_access_key.storage_key.secret_key
  }

  entries {
    key        = "APP_SECRET"
    text_value = random_password.app_secret.result
  }
}
