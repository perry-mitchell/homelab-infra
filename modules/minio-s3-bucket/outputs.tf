output "bucket_url" {
    value = minio_s3_bucket.bucket.bucket_domain_name
}
