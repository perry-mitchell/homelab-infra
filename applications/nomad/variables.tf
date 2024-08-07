variable "consul_master" {
    type = object({
        ip = string
        password = string
        user = string
        work_dir = string
    })
}
