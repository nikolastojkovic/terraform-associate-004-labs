# Section 9 — Understanding and Managing Terraform State

## 1. What Is Terraform State?

Terraform state maps resources in Terraform configuration to real infrastructure objects.

Terraform uses state to:
- Track resources it manages.
- Determine what has changed.
- Plan infrastructure updates.
- Store resource attributes and identifiers.

The default local state file is `terraform.tfstate`.

**Important:** State can contain sensitive information. Never commit state files, credentials, or secrets to a public repository.

## 2. Inspecting Terraform State

### List resources

```bash
terraform state list
```

Lists resource addresses tracked in the current state.

### Show one resource

```bash
terraform state show aws_instance.example
```

Displays the attributes recorded for a specific resource in state.

### Show the current state

```bash
terraform show
```

Displays a human-readable representation of the current state.

### Inspect a saved plan

```bash
terraform show tfplan
terraform show -json tfplan
```

The JSON representation can expose sensitive values. Handle it accordingly.

### Pull the current state

```bash
terraform state pull
```

Downloads and prints the current state from the configured backend.

**Important:** `terraform state pull` does not refresh state by querying the cloud provider. It retrieves the state currently stored in the backend.

## 3. Important State Management Commands

| Command | Purpose |
|---|---|
| `terraform state list` | List resources in state |
| `terraform state show ADDRESS` | Show one resource's state |
| `terraform state mv SOURCE DESTINATION` | Move or rename a resource address in state |
| `terraform state rm ADDRESS` | Remove a resource from state without destroying the real object |
| `terraform state pull` | Retrieve and print the current state |
| `terraform state push FILE` | Push a local state file to the configured backend |
| `terraform state replace-provider OLD NEW` | Replace a provider reference recorded in state |

Examples:

```bash
terraform state mv aws_instance.web aws_instance.app
terraform state rm aws_instance.legacy
terraform state list
```

**Remember:**
- `state mv` changes the address recorded in state; it does not normally recreate the infrastructure.
- `state rm` removes Terraform's tracking of the object; it does not delete the real infrastructure.
- `state push` can overwrite important state. Use it only when you understand the consequences.

## 4. Local State vs. Remote State

### Local state

Terraform stores state locally by default:

```text
terraform.tfstate
terraform.tfstate.backup
```

Local state is convenient for learning and simple experiments, but it is less suitable for team collaboration.

### Remote state

A remote backend stores state in a shared location, such as an Amazon S3 bucket.

Benefits:
- Shared state for team members and CI/CD pipelines.
- Centralized access control.
- Encryption and access policies when configured.
- State locking when supported and configured.

Remote state still requires appropriate security controls. Do not assume it is automatically secure.

## 5. Migrating State to a Remote Backend

When changing the backend configuration, you may need to migrate existing state.

Typical workflow:

1. Configure the new backend in the Terraform configuration.
2. Run Terraform initialization with the appropriate option.
3. Confirm the migration if prompted.
4. Verify the state and review the resulting plan.

```bash
terraform init -migrate-state
terraform state list
terraform plan
```

### `-migrate-state` vs. `-reconfigure`

```bash
terraform init -migrate-state
```

Attempts to migrate existing state to the newly configured backend.

```bash
terraform init -reconfigure
```

Reinitializes Terraform using the current backend configuration without migrating existing state to the new backend.

**Exam tip:** Use `-migrate-state` when the existing state must be transferred. Do not treat `-reconfigure` as a state migration command.

## 6. State Drift and Refresh-Only Mode

**Drift** occurs when real infrastructure changes outside Terraform, for example when someone manually changes an AWS resource in the console.

The infrastructure, Terraform state, and Terraform configuration may no longer agree.

### Step 1 — Preview state refresh

```bash
terraform plan -refresh-only
```

Terraform checks the real infrastructure and previews updates to state.

### Step 2 — Apply the state refresh

```bash
terraform apply -refresh-only
```

Terraform updates state to reflect the observed infrastructure. It does not automatically update your `.tf` files or attempt to reconcile infrastructure with the configuration.

### Step 3 — Update configuration manually

If the manual cloud change should become part of the desired configuration, edit the relevant `.tf` files yourself.

### Step 4 — Verify the result

```bash
terraform plan
```

Review the plan to ensure Terraform will not make unwanted changes.

### Key distinction

| Command | Purpose |
|---|---|
| `terraform state pull` | Retrieves the state currently stored in the backend |
| `terraform plan -refresh-only` | Previews state updates based on observed infrastructure |
| `terraform apply -refresh-only` | Applies those state updates |
| `terraform plan` | Plans changes needed to reconcile infrastructure with configuration |

**Important:** Refresh-only updates state, not configuration. The `.tf` files must be updated separately if the observed changes should become the desired configuration.

The older `terraform refresh` command is deprecated; prefer the refresh-only workflow.

## 7. Losing Terraform State

If Terraform state is lost, Terraform may no longer know which real objects correspond to resources in the configuration.

An ordinary `terraform apply` could propose creating resources that already exist.

Recommended recovery:
1. Restore state from a reliable backup or remote backend version.
2. Inspect the recovered state.
3. Run `terraform plan`.
4. If necessary, import existing resources into state.

Never blindly apply a plan after losing state.

## 8. Terraform Workspaces

Workspaces allow one configuration to use multiple state instances.

Useful commands:

```bash
terraform workspace list
terraform workspace show
terraform workspace new dev
terraform workspace select dev
terraform workspace delete dev
```

| Command | Purpose |
|---|---|
| `workspace list` | List workspaces |
| `workspace show` | Show the current workspace |
| `workspace new NAME` | Create and select a workspace |
| `workspace select NAME` | Switch to another workspace |
| `workspace delete NAME` | Delete a workspace, subject to Terraform's restrictions |

**Important:** Workspaces separate state instances, but they do not automatically provide full environment isolation. Separate configurations and backend arrangements may be more suitable for complex production environments.

## 9. State Locking

State locking helps prevent concurrent operations from modifying the same state simultaneously.

- Locking depends on the backend and its configuration.
- Do not disable locking casually.
- If a lock error occurs, check whether another Terraform operation is still running.
- Use `terraform force-unlock LOCK_ID` only when you have confirmed the lock is stale and it is safe to remove.

## 10. Importing Existing Infrastructure

Terraform can import an existing infrastructure object into state so that Terraform can manage it.

Example:

```bash
terraform import aws_instance.example i-0123456789abcdef0
```

The resource address must correspond to a suitable resource block in the configuration.

Importing an object does not automatically generate a complete Terraform configuration. You must ensure the configuration correctly represents the resource.

## 11. Commands to Memorize

| Task | Command |
|---|---|
| List resources | `terraform state list` |
| Inspect a resource | `terraform state show ADDRESS` |
| Show current state | `terraform show` |
| Retrieve backend state | `terraform state pull` |
| Move a state address | `terraform state mv SOURCE DESTINATION` |
| Stop tracking a resource | `terraform state rm ADDRESS` |
| Migrate state | `terraform init -migrate-state` |
| Reinitialize without migration | `terraform init -reconfigure` |
| Preview state refresh | `terraform plan -refresh-only` |
| Apply state refresh | `terraform apply -refresh-only` |
| List workspaces | `terraform workspace list` |
| Show current workspace | `terraform workspace show` |
| Import existing infrastructure | `terraform import ADDRESS ID` |

## 12. Final Exam Checklist

- [ ] Understand the purpose of Terraform state.
- [ ] Distinguish `terraform show` from `terraform state show`.
- [ ] Know how to list, inspect, move, and remove state entries.
- [ ] Understand local versus remote state.
- [ ] Know the difference between `-migrate-state` and `-reconfigure`.
- [ ] Understand drift and refresh-only mode.
- [ ] Know that `terraform state pull` does not refresh state from the cloud.
- [ ] Remember that refresh-only does not update `.tf` configuration files.
- [ ] Understand workspaces and their limitations.
- [ ] Know why state locking and secure state storage matter.
- [ ] Understand that removing an object from state does not destroy the real resource.

**Core takeaway:** Terraform state connects configuration to real infrastructure. Inspect it carefully, protect it, and understand the difference between updating state and changing the desired configuration.