output "master_public_ip" {
  value = yandex_compute_instance.master.network_interface[0].nat_ip_address
}

output "worker_public_ip" {
  value = yandex_compute_instance.worker.network_interface[0].nat_ip_address
}

output "bucket_name" {
  value = yandex_storage_bucket.app_bucket.bucket
}

output "s3_access_key" {
  value     = yandex_iam_service_account_static_access_key.storage_key.access_key
  sensitive = true
}

output "s3_secret_key" {
  value     = yandex_iam_service_account_static_access_key.storage_key.secret_key
  sensitive = true
}

output "lockbox_secret_id" {
  value = yandex_lockbox_secret.app.id
}
