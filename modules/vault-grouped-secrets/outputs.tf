# Output the filtered secrets
output "secrets" {
  description = "Map of secret keys to their values from the grouped secret"
  value       = local.filtered_secrets
  sensitive   = true
}
