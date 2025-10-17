resource "b2_bucket" "backup_appdata" {
  bucket_name = "${var.backblaze_bucket_prefix}appdata"
  bucket_type = "allPrivate"
}
