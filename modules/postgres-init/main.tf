locals {
  job_name = "postgres-init-${var.name}"
  sql = join(
    "; ",
    concat(
      [
        "DO \\$\\$ BEGIN IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '${var.create_user.username}') THEN CREATE USER ${var.create_user.username} WITH PASSWORD '${var.create_user.password}'; ELSE ALTER USER ${var.create_user.username} WITH PASSWORD '${var.create_user.password}'; END IF; END \\$\\$",
        "GRANT ALL ON SCHEMA public TO ${var.create_user.username}",
        "GRANT ALL PRIVILEGES ON DATABASE ${var.create_database} TO ${var.create_user.username}"
      ],
      var.extra_sql_lines
    )
  )
}

resource "kubernetes_job" "init_db" {
  metadata {
    name      = local.job_name
    namespace = var.namespace
  }

  spec {
    template {
      metadata {
        name = local.job_name
      }

      spec {
        container {
          name  = local.job_name
          image = "postgres:latest"

          command = ["/bin/sh", "-c"]
          args = [<<-EOF
                        export PGPASSWORD=$DB_PASSWORD
                        DB_RES=$(psql -h ${var.db_host} -U $DB_USER -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${var.create_database}'")
                        echo $DB_RES | grep -q 1 || psql -h ${var.db_host} -U $DB_USER -d postgres -c "CREATE DATABASE ${var.create_database}"
                        psql \
                            -h ${var.db_host} \
                            -U $DB_USER \
                            -d postgres \
                            -c "${local.sql}" || {
                                RC=$?
                                echo "PostgreSQL command  failed with exit code $RC"
                                exit 1
                            }
                        EOF
          ]

          env {
            name  = "DB_USER"
            value = var.db_username
          }

          env {
            name  = "DB_PASSWORD"
            value = var.db_password
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 4
  }
}
