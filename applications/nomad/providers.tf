provider "nomad" {
    address = "http://${var.nomad_master.ip}:4646"
}
