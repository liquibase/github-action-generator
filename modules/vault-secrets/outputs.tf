# Output the filtered secrets
output "secrets" {
  description = "Map of secret keys to their values from the specified vault"
  value       = local.filtered_secrets
  sensitive   = true
}

# Output individual secret values for convenience (when specific keys are requested)
output "secret_values" {
  description = "Individual secret values (only populated when specific secret_keys are requested)"
  value = length(var.secret_keys) > 0 ? {
    for key in var.secret_keys : key => lookup(local.filtered_secrets, key, null)
  } : {}
  sensitive = true
}

# Output all available secret keys (for discovery)
output "available_keys" {
  description = "List of all available secret keys in the vault"
  value       = keys(local.all_secrets)
}

# Output vault metadata
output "vault_info" {
  description = "Information about the vault being accessed"
  value = {
    vault_type = var.vault_type
    vault_name = local.vault_names[var.vault_type]
    vault_path = local.vault_paths[var.vault_type]
    secret_arn = data.aws_secretsmanager_secret.vault.arn
    role_arn   = local.role_arn
  }
}

