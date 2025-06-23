# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status
⚠️ **DEPRECATED**: This project is being replaced by [liquibase/setup-liquibase](https://github.com/liquibase/setup-liquibase).

**Migration Timeline:**
- Current Status: Adding deprecation notices
- Target: Archive this repository once migration is complete
- Replacement: All functionality moved to setup-liquibase action

## Context Sharing

### Related Projects
- **Replacement Project**: `../setup-liquibase/`
- **Related Documentation**: See `../setup-liquibase/CLAUDE.md` for current project context
- **GitHub**: [liquibase/setup-liquibase](https://github.com/liquibase/setup-liquibase)

### Project Purpose (Historical)
This Go-based tool was designed to generate individual GitHub Actions for each Liquibase command. However, the new approach uses a single setup action that installs Liquibase and allows users to run any command directly, which is:
- More flexible and maintainable
- Follows GitHub Actions best practices
- Reduces complexity for users
- Easier to test and maintain

## Deprecation Tasks
- [x] Add deprecation notice to README.md
- [x] Add deprecation notices to generated action READMEs
- [x] Add runtime deprecation warnings to generated actions
- [ ] Update repository description on GitHub
- [ ] Create migration guide pointing to setup-liquibase
- [ ] Update any documentation references
- [ ] Archive repository when migration is complete

## Migration Information

### Old Approach (This Repository)
```yaml
# Multiple individual actions for each command
- uses: liquibase-github-actions/update@v4.32.0
  with:
    changelogFile: 'changelog.xml'
    url: 'jdbc:h2:mem:test'
```

### New Approach (setup-liquibase)
```yaml
# Single setup action, then run any command
- uses: liquibase/setup-liquibase@v1
  with:
    version: '4.32.0'
    edition: 'oss'
- run: liquibase update --changelog-file=changelog.xml --url=jdbc:h2:mem:test
```

## Development Commands

### Build Commands
```bash
# Build the protobuf generator
make build

# Build Docker image
make docker VERSION=4.32.0

# Create command list (requires Docker)
make create-list VERSION=4.32.0

# Generate action for specific command
make generate VERSION=4.32.0 COMMAND="update"
```

### Testing and Validation
```bash
# Validate generated protobuf
protoc --proto_path=. --liquibase_out=. --liquibase_opt=paths=source_relative --liquibase_opt=version=4.32.0 path/to/command.proto

# Test generated action locally
cd action/command_name && docker build -t test-action .
```

### Infrastructure Commands
```bash
# Terraform/OpenTofu operations
tofu fmt
tofu init
tofu validate
tofu plan
tofu apply

# Spacelift operations (requires auth)
spacectl stack local-preview --id liquibase-github-actions
spacectl stack deploy --id liquibase-github-actions --auto-confirm
```

## Architecture Overview

### Core Components

**Protobuf Generator (`main.go`)**
- Generates GitHub Actions from Liquibase protobuf definitions
- Creates action.yml, Dockerfile, README.md, and shell scripts
- Handles command-specific parameters and global options
- Uses Go protobuf compiler plugin architecture

**Infrastructure Automation (`main.tf`)**
- Terraform configuration for GitHub repository management
- Creates individual repositories for each Liquibase command
- Manages repository settings and permissions via GitHub provider
- Reads command list from `commands.json`

**Build System (`Makefile`)**
- Orchestrates Docker builds and protobuf generation
- Coordinates between Go binary, Docker container, and script execution
- Handles command-specific generation workflow

**Script Automation (`scripts/`)**
- `create-action.sh`: Sets up protobuf files and generates action components
- `push-to-repository.sh`: Handles git operations, tagging, and GitHub releases
- `get-latest-release.sh`: Retrieves latest Liquibase version
- `output-release-edit.sh`: Generates release edit links

### Generation Workflow

1. **Command Discovery**: Docker container runs Liquibase to generate `commands.json`
2. **Repository Creation**: Terraform creates GitHub repositories for each command
3. **Action Generation**: For each command:
   - Protobuf files are processed by the Go generator
   - Action YAML, Dockerfile, shell script, and README are generated
   - Files are pushed to individual command repositories
4. **Release Management**: GitHub releases are created automatically

### Key Data Flow

```
Liquibase CLI → commands.json → Terraform → GitHub Repos
Protobuf definitions → Go generator → Action files → Git push → GitHub releases
```

## Environment Variables

### Required for CI/CD
- `LIQUIBASE_VERSION`: Version of Liquibase to use (e.g., "4.32.0")
- `GITHUB_TOKEN`: GitHub App token for repository operations
- `LIQUIBASE_TERRAFORM_GH_APP_ID`: GitHub App ID for Terraform
- `LIQUIBASE_TERRAFORM_GH_INSTALL_ID_ACTIONS`: GitHub App installation ID
- `LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY`: Path to GitHub App private key file

### Required for Spacelift
- `SPACELIFT_API_KEY_ENDPOINT`
- `SPACELIFT_API_KEY_ID`
- `SPACELIFT_API_KEY_SECRET`

## File Structure

### Generated Output Structure
```
action/
├── command_name/
│   ├── action.yml          # GitHub Action definition
│   ├── command_name.sh     # Shell script entry point
│   ├── Dockerfile          # Docker container definition
│   ├── README.md           # Action documentation
│   └── *.proto             # Protobuf definitions
```

### Key Dependencies
- Go 1.23+ with protobuf support
- Docker for containerized builds
- OpenTofu for infrastructure management
- GitHub CLI for repository operations

## Technical Context

### Repository Structure
- **Language**: Go
- **Purpose**: Generate multiple individual GitHub Actions
- **Build System**: Makefile, Terraform for infrastructure
- **Deprecation Reason**: Replaced by more flexible single-action approach

### Key Files
- `main.go` - Main generator logic
- `Makefile` - Build automation
- `scripts/` - Various automation scripts
- `main.tf` - Infrastructure as code

## Important Notes
- Do not accept new feature requests - redirect to setup-liquibase
- Do not create new actions from this generator
- Focus only on deprecation and migration activities
- Preserve historical functionality during transition period

## References
- **Replacement**: [liquibase/setup-liquibase](https://github.com/liquibase/setup-liquibase)
- **Jira**: DAT-20276 (Release automation simplification)
- **Migration Guide**: Will be created as part of deprecation process