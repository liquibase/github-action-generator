# vault-grouped-secrets

Copy of `modules/vault-grouped-secrets` in [liquibase/liquibase-infrastructure](https://github.com/liquibase/liquibase-infrastructure/tree/main/modules/vault-grouped-secrets) (TECHOPS-1645).
It reads one grouped secret, `/vault/grouped/<group>`, by assuming that group's role from the vault-manager stack, and returns the `secret_keys` it lists.
The group must trust this stack's Spacelift role; see `vault-manager/GROUPED-SECRETS.md` in that repository.
