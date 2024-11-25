output "dashboard_auth_token" {
    sensitive = true
    value = module.dashboard.dashboard_auth_token
}
