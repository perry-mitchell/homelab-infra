locals {
  deployments_enabled = {
    datasource = true
    network = true
    service = true
  }
}

# To Shutdown:
#
#  1. Change `service` above to `false`, run tofu
#  2. Change `datasource` above to `false, run tofu
#  3. Run the ./scripts/shutdown.sh script
