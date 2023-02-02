output "default_rwx_storage_class" {
  description = "Default read-write-many storage class"
  value       = var.default_rwx_storage_class
  depends_on  = [null_resource.install_portworx]
}

output "rwx_storage_class" {
  value       = var.default_rwx_storage_class
  depends_on  = [null_resource.enable_portworx_encryption]
}

output "rwo_storage_class" {
  value       = var.default_rwo_storage_class
  depends_on  = [null_resource.enable_portworx_encryption]
}

output "file_storage_class" {
  value       = var.default_file_storage_class
  depends_on  = [null_resource.enable_portworx_encryption]
}

output "block_storage_class" {
  value       = var.default_block_storage_class
  depends_on  = [null_resource.enable_portworx_encryption]
}

output "storage_classes_provided" {
  value      = [
    "portworx-cassandra-sc",
    "portworx-couchdb-sc",
    "portworx-db-gp",
    "portworx-db-gp2-sc",
    "portworx-db-gp3-sc",
    "portworx-db2-fci-sc",
    "portworx-db2-rwo-sc",
    "portworx-db2-rwx-sc",
    "portworx-dv-shared-gp",
    "portworx-dv-shared-gp3",
    "portworx-elastic-sc",
    "portworx-gp3-sc",
    "portworx-kafka-sc",
    "portworx-metastoredb-sc",
    "portworx-nonshared-gp2",
    "portworx-rwx-gp-sc",
    "portworx-rwx-gp2-sc",
    "portworx-rwx-gp3-sc",
    "portworx-shared-gp",
    "portworx-shared-gp-allow",
    "portworx-shared-gp1",
    "portworx-shared-gp3",
    "portworx-solr-sc",
    "portworx-watson-assistant-sc",
    "px-db",
    "px-db-cloud-snapshot",
    "px-db-cloud-snapshot-encrypted",
    "px-db-encrypted",
    "px-db-local-snapshot",
    "px-db-local-snapshot-encrypted",
    "px-replicated",
    "px-replicated-encrypted"
  ]
  depends_on  = [null_resource.enable_portworx_encryption]
}
