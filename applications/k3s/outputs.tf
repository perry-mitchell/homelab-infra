output "backup_b2_details_appdata" {
  sensitive = true
  value = {
    bucket_name = b2_bucket.backup_appdata.bucket_name
    key_id      = var.backblaze_auth.application_key_id
    key         = var.backblaze_auth.application_key
  }
}
