output "default_rwx_storage_class" {
  description = "Default read-write-many storage class"
  value       = "portworx-db2-rwx-sc"
  depends_on  = [null_resource.install_portworx]
}