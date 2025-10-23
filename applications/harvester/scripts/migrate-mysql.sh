#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Configuration
SOURCE_KUBECONFIG="$SCRIPT_DIR/../../k3s/kube.config"
TARGET_KUBECONFIG="$SCRIPT_DIR/../kube.config"

SOURCE_NAMESPACE="datasources"
SOURCE_SERVICE="mariadb"
SOURCE_PORT="3306"

TARGET_NAMESPACE="family"
TARGET_SERVICE="webtrees-mariadb"
TARGET_PORT="3306"

SOURCE_DATABASE="webtrees"
TARGET_DATABASE="webtrees"

# MySQL credentials (can be overridden via environment variables)
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"
SOURCE_MYSQL_USER="root"
TARGET_MYSQL_USER="root"

# Backup directory
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# TLS verification settings
SOURCE_INSECURE="${SOURCE_INSECURE:-false}"
TARGET_INSECURE="${TARGET_INSECURE:-true}"

# Helper functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    log "ERROR: $*" >&2
    exit 1
}

# Build kubectl command with appropriate flags
kubectl_source() {
    local cmd="kubectl --kubeconfig=$SOURCE_KUBECONFIG"
    if [ "$SOURCE_INSECURE" = "true" ]; then
        cmd="$cmd --insecure-skip-tls-verify"
    fi
    $cmd "$@"
}

kubectl_target() {
    local cmd="kubectl --kubeconfig=$TARGET_KUBECONFIG"
    if [ "$TARGET_INSECURE" = "true" ]; then
        cmd="$cmd --insecure-skip-tls-verify"
    fi
    $cmd "$@"
}

# Check dependencies
check_dependencies() {
    local missing=()

    for cmd in kubectl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
    fi
}

# Get pod for service
get_pod_for_service() {
    local namespace=$1
    local service=$2
    local kubectl_cmd=$3

    # Try to get pod via service selector
    local selector=$($kubectl_cmd -n "$namespace" get service "$service" -o jsonpath='{.spec.selector}' 2>/dev/null)

    if [ -z "$selector" ]; then
        error "Service $service not found in namespace $namespace"
    fi

    # Convert selector JSON to label selector format
    local label_selector=$(echo "$selector" | jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")')

    # Get first ready pod matching selector
    local pod=$($kubectl_cmd -n "$namespace" get pods -l "$label_selector" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ -z "$pod" ]; then
        error "No pod found for service $service in namespace $namespace"
    fi

    echo "$pod"
}

# Prompt for password if not set
get_mysql_password() {
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        read -s -p "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
        echo
        if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
            error "MySQL password is required"
        fi
    fi
}

# Check database parameter
check_database_param() {
    if [ -z "$SOURCE_DATABASE" ]; then
        error "SOURCE_DATABASE must be specified (e.g., SOURCE_DATABASE=mydb)"
    fi
    log "Database to migrate: $SOURCE_DATABASE -> $TARGET_DATABASE"
}

# Create backup directory
setup_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    log "Backup directory: $BACKUP_DIR"
}

# Backup source database
backup_source() {
    log "Creating backup of SOURCE database: $SOURCE_DATABASE..."

    local pod=$(get_pod_for_service "$SOURCE_NAMESPACE" "$SOURCE_SERVICE" kubectl_source)
    local backup_file="$BACKUP_DIR/source_${SOURCE_DATABASE}_${TIMESTAMP}.sql.gz"

    log "Source pod: $pod"
    log "Backup file: $backup_file"

    # Verify database exists
    if ! kubectl_source -n "$SOURCE_NAMESPACE" exec "$pod" -- \
        mariadb -u"$SOURCE_MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" \
        -e "USE $SOURCE_DATABASE" 2>/dev/null; then
        error "Database '$SOURCE_DATABASE' does not exist on source"
    fi

    # Create dump and compress
    kubectl_source -n "$SOURCE_NAMESPACE" exec "$pod" -- \
        mariadb-dump -u"$SOURCE_MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --routines \
        --triggers \
        --events \
        "$SOURCE_DATABASE" | gzip > "$backup_file"

    if [ ! -s "$backup_file" ]; then
        error "Source backup failed or is empty"
    fi

    log "Source backup completed: $backup_file ($(du -h "$backup_file" | cut -f1))"
}

# Backup target database
backup_target() {
    log "Creating backup of TARGET database (pre-migration): $TARGET_DATABASE..."

    local pod=$(get_pod_for_service "$TARGET_NAMESPACE" "$TARGET_SERVICE" kubectl_target)
    local backup_file="$BACKUP_DIR/target_pre_${TARGET_DATABASE}_${TIMESTAMP}.sql.gz"

    log "Target pod: $pod"
    log "Backup file: $backup_file"

    # Check if database exists on target
    if kubectl_target -n "$TARGET_NAMESPACE" exec "$pod" -- \
        mariadb -u"$TARGET_MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" \
        -e "USE $TARGET_DATABASE" 2>/dev/null; then

        log "Database '$TARGET_DATABASE' exists on target, creating backup..."

        # Create dump and compress
        kubectl_target -n "$TARGET_NAMESPACE" exec "$pod" -- \
            mariadb-dump -u"$TARGET_MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" \
            --single-transaction \
            --quick \
            --lock-tables=false \
            --routines \
            --triggers \
            --events \
            "$TARGET_DATABASE" | gzip > "$backup_file"

        if [ ! -s "$backup_file" ]; then
            log "WARNING: Target backup failed or is empty"
        else
            log "Target backup completed: $backup_file ($(du -h "$backup_file" | cut -f1))"
        fi
    else
        log "Database '$TARGET_DATABASE' does not exist on target (will be created during migration)"
    fi
}

# Migrate database
migrate_database() {
    log "Starting database migration..."

    local source_pod=$(get_pod_for_service "$SOURCE_NAMESPACE" "$SOURCE_SERVICE" kubectl_source)
    local target_pod=$(get_pod_for_service "$TARGET_NAMESPACE" "$TARGET_SERVICE" kubectl_target)

    log "Source pod: $source_pod"
    log "Target pod: $target_pod"
    log "Creating dump from source and streaming to target..."

    # Stream dump from source directly to target
    kubectl_source -n "$SOURCE_NAMESPACE" exec "$source_pod" -- \
        mariadb-dump -u"$SOURCE_MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --routines \
        --triggers \
        --events \
        "$SOURCE_DATABASE" | \
    kubectl_target -n "$TARGET_NAMESPACE" exec -i "$target_pod" -- \
        mariadb -u"$TARGET_MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" "$TARGET_DATABASE"

    log "Database migration completed successfully!"
}

# Verify migration
verify_migration() {
    log "Verifying migration..."

    local source_pod=$(get_pod_for_service "$SOURCE_NAMESPACE" "$SOURCE_SERVICE" kubectl_source)
    local target_pod=$(get_pod_for_service "$TARGET_NAMESPACE" "$TARGET_SERVICE" kubectl_target)

    # Get table list from source database
    local source_tables=$(kubectl_source -n "$SOURCE_NAMESPACE" exec "$source_pod" -- \
        mariadb -u"$SOURCE_MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" "$SOURCE_DATABASE" -N -e "SHOW TABLES" | sort)

    # Get table list from target database
    local target_tables=$(kubectl_target -n "$TARGET_NAMESPACE" exec "$target_pod" -- \
        mariadb -u"$TARGET_MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" "$TARGET_DATABASE" -N -e "SHOW TABLES" | sort)

    if [ "$source_tables" != "$target_tables" ]; then
        log "WARNING: Table lists don't match!"
        log "Source tables in $SOURCE_DATABASE:"
        echo "$source_tables"
        log "Target tables in $TARGET_DATABASE:"
        echo "$target_tables"
    else
        log "✓ Table lists match in $SOURCE_DATABASE -> $TARGET_DATABASE"
        local table_count=$(echo "$source_tables" | wc -l)
        log "  Tables migrated: $table_count"
        echo "$source_tables" | head -n 10 | while read -r table; do
            log "    - $table"
        done
        if [ "$table_count" -gt 10 ]; then
            log "    ... and $((table_count - 10)) more"
        fi
    fi
}

# Main execution
main() {
    log "=== MySQL/MariaDB Migration Script ==="
    log "Source: $SOURCE_NAMESPACE/$SOURCE_SERVICE"
    log "Target: $TARGET_NAMESPACE/$TARGET_SERVICE"
    echo

    # Check dependencies
    check_dependencies

    # Check database parameter
    check_database_param

    # Get MySQL password
    get_mysql_password

    # Setup backup directory
    setup_backup_dir

    # Create backups
    backup_source
    backup_target

    echo
    log "Backups completed. Ready to migrate."
    log "WARNING: Target database '$TARGET_DATABASE' will be DROPPED and recreated!"
    read -p "Continue with migration? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log "Migration cancelled by user"
        exit 0
    fi

    # Perform migration
    migrate_database

    # Verify
    verify_migration

    echo
    log "=== Migration Complete ==="
    log "Backups are stored in: $BACKUP_DIR"
    log ""
    log "Next steps:"
    log "  1. Verify your applications work with the target database"
    log "  2. Update application configs to point to target"
    log "  3. Keep source database available as backup until verified"
}

# Run main function
main "$@"
