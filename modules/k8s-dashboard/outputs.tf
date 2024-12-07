output "dashboard_auth_token" {
    sensitive = true
    value = nonsensitive(kubernetes_secret.admin_user.data.token)
}
