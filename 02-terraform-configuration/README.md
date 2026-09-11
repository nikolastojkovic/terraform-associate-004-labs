# Terraform Associate 004 — Sections 5–6

Quick exam reminder for **Terraform CLI** and **Terraform File Structure**.

---

## Terraform CLI Help

General help:

```bash
terraform -help
```

Help for a specific command:

```bash
terraform plan -help
```

---

## terraform fmt

Formats Terraform configuration files into the standard Terraform format.

Current directory:

```bash
terraform fmt
```

Including subdirectories:

```bash
terraform fmt -recursive
```

`fmt` can modify `.tf` files on the filesystem to correct their formatting.

---

## Environment Variables

### Terraform Logging

Enable debug logging:

```bash
export TF_LOG=DEBUG
```

Disable it:

```bash
unset TF_LOG
```

Common levels:

```text
TRACE
DEBUG
INFO
WARN
ERROR
```

---

### Terraform Input Variables

A Terraform variable can be supplied without modifying the `.tf` file:

```bash
export TF_VAR_srv_name="prod1"
```

This supplies a value for:

```hcl
variable "srv_name" {
  type = string
}
```

Pattern:

```text
TF_VAR_<variable_name>
```

---

### Provider Credentials

Providers can use their own environment variables.

AWS example:

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

Important difference:

```text
TF_VAR_srv_name
      ↓
Terraform input variable

AWS_ACCESS_KEY_ID
      ↓
AWS authentication
```

Never commit credentials or secrets to Git.

---

# Terraform File Structure

Common Terraform files:

```text
project/
├── main.tf
├── terraform.tf
├── providers.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

Typical purpose:

| File | Purpose |
|---|---|
| `main.tf` | Main resources/configuration |
| `terraform.tf` | Terraform and provider requirements |
| `providers.tf` | Provider configuration |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output declarations |
| `terraform.tfvars` | Input variable values |

These filenames are mostly **conventions for organization**.

Terraform reads the `.tf` files in the working directory as one configuration/module.

---

## Organizing Larger Projects

Resources can be separated logically:

```text
network.tf     → VPC, subnets, routes
compute.tf     → EC2, compute resources
dns.tf         → DNS resources
kubernetes.tf  → Kubernetes resources
```

Terraform does **not** execute files according to filename order.

Dependencies determine the order of resource operations.

---

## terraform.tfvars

Used to provide values for input variables:

```hcl
instance_type = "t3.micro"
environment   = "dev"
```

`.tfvars` files may contain sensitive or environment-specific values, so they are often ignored by Git:

```gitignore
*.tfvars
*.tfvars.json
```

But remember:

> `.tfvars` is not automatically secret. The important rule is never commit sensitive values.

---

# Exam Reminders

```text
terraform fmt
→ format current configuration

terraform fmt -recursive
→ also format subdirectories

terraform plan -help
→ help for plan only

TF_LOG=DEBUG
→ enable debug logging

TF_VAR_name="value"
→ set Terraform input variable

AWS_ACCESS_KEY_ID
→ AWS authentication

variables.tf
→ variable declarations

outputs.tf
→ outputs

providers.tf
→ provider configuration

terraform.tfvars
→ variable values

File names
→ organization, NOT execution order
```