terraform {
    required_providers {
        minio = {
            source = "aminueza/minio"
        }
    }
}

provider "minio" {
    minio_password = var.minio_auth.password
    minio_server = var.minio_auth.server
    minio_user = var.minio_auth.username
}

// Resources

resource "minio_s3_bucket" "bucket" {
    bucket = var.bucket
    acl = "private"
}
