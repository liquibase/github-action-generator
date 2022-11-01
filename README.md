# GitHub Actions Generator
Main repository for the tools and automation to generate Liquibase GitHub Actions at https://github.com/liquibase-github-actions. Uses generated protobuf files from https://github.com/liquibase/protobuf-generator to create an action for each Liquibase command. 
```mermaid
graph LR
    A[Create Command List] --> |commands.json| B[Terraform]
    B --> |create liquibase-github-actions/*command* repo| C{Generate Action}
    C -->|calculate-checksum| D[Liquibase Calculate Checksum Action]
    C -->|changelog-sync| E[Liquibase Changelog Sync Action]
    C -->|...| F[Liquibase ... Action]
    C -->|vaildate| G[Liquibase Validate Action]
```
