variable "tailscale" {
    type = object({
        hostname = string
        host_ip = string
        tailnet = string
    })
}
