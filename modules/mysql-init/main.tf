locals {
  job_name = "mysql-init-${var.name}"
  sql = join(
    "; ",
    concat(
        var.create_database != null ? [
            "CREATE DATABASE IF NOT EXISTS ${var.create_database}"
        ] : [],
        var.create_user != null ? [
            "CREATE USER IF NOT EXISTS '${var.create_user.username}'@'%' IDENTIFIED BY '${var.create_user.password}'"
        ] : [],
        [
            for user, database in var.grant_users :
                "GRANT ALL ON ${database}.* TO '${user}'@'%'"
        ]
    )
  )
}

resource "kubernetes_job" "init_db" {
    metadata {
        name = local.job_name
        namespace = var.namespace
    }

    spec {
        template {
            metadata {
                name = local.job_name
            }

            spec {
                container {
                    name = local.job_name
                    image = "arey/mysql-client:latest"

                    command = ["/bin/sh", "-c"]
                    args    = [<<-EOF
                        mysql -h ${var.db_host} \
                            -u $DB_USER \
                            -p$DB_PASSWORD \
                            -e "${local.sql}" || {
                                RC=$?
                                echo "MySQL command failed with exit code $RC"
                                exit 1
                            }
                        EOF
                    ]

                    env {
                        name = "DB_USER"
                        value = var.db_username
                    }

                    env {
                        name = "DB_PASSWORD"
                        value = var.db_password
                    }
                }

                restart_policy = "Never"
            }
        }

        backoff_limit = 4
    }
}
