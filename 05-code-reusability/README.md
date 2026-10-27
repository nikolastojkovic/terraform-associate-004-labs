# Sections 10–11 — Code Reusability and Refactoring Terraform State

## Section 10: Making Code Reusable

### 1. Built-in Functions

Terraform provides built-in functions to transform, combine, and standardize values.

Common functions:

| Function | Purpose | Example |
|---|---|---|
| `lower()` | Convert text to lowercase | `lower("DEV")` → `"dev"` |
| `upper()` | Convert text to uppercase | `upper("dev")` → `"DEV"` |
| `title()` | Capitalize words | `title("hello world")` |
| `replace()` | Replace matching text | `replace("dev-app", "dev", "prod")` |
| `join()` | Combine list elements into a string | `join(",", ["a", "b"])` |
| `split()` | Split a string into a list | `split(",", "a,b")` |
| `length()` | Return the length of a collection or string | `length(["a", "b"])` → `2` |
| `lookup()` | Retrieve a map value with an optional default | `lookup(var.ports, "web", 80)` |
| `merge()` | Combine maps or objects | `merge(local.common_tags, var.extra_tags)` |
| `concat()` | Combine lists | `concat(var.public_subnets, var.extra_subnets)` |
| `toset()` | Convert a value to a set | `toset(["a", "b", "a"])` |
| `tomap()` | Convert a value to a map | `tomap({ env = "dev" })` |
| `try()` | Return the first expression that does not produce an error | `try(var.settings.region, "eu-central-1")` |
| `can()` | Test whether an expression can be evaluated without an error | `can(var.config.region)` |

Example:

```hcl
variable "environment" {
  type    = string
  default = "DEV"
}

locals {
  environment = lower(var.environment)
}
```

Use `terraform console` to experiment with expressions:

```bash
terraform console
```

Then enter:

```hcl
lower("DEV")
merge({ env = "dev" }, { app = "api" })
length(["a", "b", "c"])
```

**Remember:** Terraform functions calculate values; they do not create infrastructure resources.

### 2. Dynamic Values and Expressions

Use expressions to derive values instead of hardcoding the same value repeatedly.

```hcl
variable "project_name" {
  type    = string
  default = "demo"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  resource_prefix = "${var.project_name}-${var.environment}"
}
```

The resulting prefix is `demo-dev`.

You can also use functions and expressions directly in resource arguments:

```hcl
tags = {
  Name        = local.resource_prefix
  Environment = lower(var.environment)
}
```

### 3. Locals: Avoid Code Duplication

Locals assign names to expressions that you want to reuse within a module.

```hcl
variable "project_name" {
  type    = string
  default = "demo"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

Reuse the values:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs"

  tags = local.common_tags
}
```

**Benefits:**
- Reduce duplication.
- Make configuration easier to maintain.
- Standardize resource names and tags.
- Centralize derived values.

**Remember:** Variables accept input; locals derive and reuse values.

### 4. The `count` Meta-Argument

Use `count` to create multiple instances of a resource based on a number.

```hcl
variable "instance_count" {
  type    = number
  default = 2
}

resource "aws_instance" "app" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

Terraform creates two instances with addresses:

```text
aws_instance.app[0]
aws_instance.app[1]
```

Access one instance:

```hcl
aws_instance.app[0].id
```

Access all instance IDs:

```hcl
aws_instance.app[*].id
```

Use `count` when instances are largely interchangeable and you know how many you need.

**Caution:** Because instances are indexed, removing an element from a list used with `count` can shift indexes and cause unwanted changes.

### 5. The `for_each` Meta-Argument

Use `for_each` to create multiple resource instances from a map or a set of strings.

Example with a set:

```hcl
variable "environments" {
  type    = set(string)
  default = ["dev", "staging", "prod"]
}

resource "aws_s3_bucket" "environment" {
  for_each = var.environments
  bucket   = "demo-${each.key}"
}
```

Example with a map:

```hcl
variable "instance_types" {
  type = map(string)

  default = {
    dev    = "t3.micro"
    staging = "t3.small"
  }
}

resource "aws_instance" "app" {
  for_each      = var.instance_types
  ami           = var.ami_id
  instance_type = each.value

  tags = {
    Name = "app-${each.key}"
  }
}
```

Important expressions:

- `each.key` — the current map key or set element.
- `each.value` — the current map value; for a set of strings, it is the same as `each.key`.

Resource addresses look like:

```text
aws_instance.app["dev"]
aws_instance.app["staging"]
```

Use `for_each` when resources have meaningful identities, such as environments, users, or named applications.

### 6. `count` vs. `for_each`

| Feature | `count` | `for_each` |
|---|---|---|
| Input | Non-negative integer | Map or set of strings |
| Resource identity | Numeric index | Named key |
| Address example | `aws_instance.app[0]` | `aws_instance.app["dev"]` |
| Best suited for | Similar, interchangeable instances | Instances with distinct identities |
| Common risk | Index shifts when list elements change | Changing or removing keys changes instance addresses |

**Exam tip:** `count` uses `count.index`; `for_each` uses `each.key` and `each.value`.

---

## Section 11: Refactoring Terraform State

### 7. What Is State Refactoring?

Refactoring changes the organization or address of Terraform resources while preserving the existing infrastructure.

For example, you may rename a resource or move it into a module.

Without a state-aware refactoring mechanism, Terraform might interpret the new address as a new resource and the old address as a resource to destroy.

The goal is to tell Terraform that the resource has moved, not that it should be recreated.

### 8. The `moved` Block

Use a `moved` block to declare a resource address change.

Before:

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

After renaming the resource to `application`:

```hcl
resource "aws_instance" "application" {
  ami           = var.ami_id
  instance_type = "t3.micro"
}

moved {
  from = aws_instance.app
  to   = aws_instance.application
}
```

Terraform interprets this as a change of address rather than a request to destroy and recreate the instance.

After applying the refactoring, the `moved` block can generally remain in the configuration to help existing state instances migrate when users upgrade from an older version.

### 9. Moving Resources into a Module

Suppose a resource previously existed at the root:

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

You move the resource into a module and its new address becomes:

```text
module.app_infra.aws_instance.app
```

Declare the move:

```hcl
moved {
  from = aws_instance.app
  to   = module.app_infra.aws_instance.app
}
```

Run:

```bash
terraform plan
```

Review the plan to verify that Terraform recognizes the move and does not propose unnecessary resource destruction or recreation.

**Important:** The destination address must correspond to a resource that exists in the updated configuration.

### 10. The `removed` Block

Use a `removed` block when you want to stop managing a resource through Terraform configuration.

To remove a resource from Terraform management without destroying the real infrastructure:

```hcl
removed {
  from = aws_instance.legacy

  lifecycle {
    destroy = false
  }
}
```

Then run:

```bash
terraform plan
terraform apply
```

The `destroy = false` setting instructs Terraform to remove the resource from state without destroying the actual object.

If you want Terraform to destroy the resource, the normal resource removal workflow can be appropriate; review the plan carefully before applying.

**Remember:** Removing a resource from state and destroying a resource are different operations.

### 11. The `import` Block

Use an `import` block to declare that an existing infrastructure object should be imported into Terraform state.

```hcl
import {
  to = aws_instance.app
  id = "i-0123456789abcdef0"
}

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

Run:

```bash
terraform plan
terraform apply
```

Terraform plans the import and applies it when approved.

The resource configuration must match the real infrastructure. An import block does not automatically generate a complete configuration for the imported object.

**CLI alternative:**

```bash
terraform import aws_instance.app i-0123456789abcdef0
```

The CLI command imports the object into state, but you must ensure the matching resource configuration is present and correct.

### 12. `moved` vs. `removed` vs. `import`

| Feature | Purpose |
|---|---|
| `moved` block | Change a resource's address while preserving its identity |
| `removed` block | Stop managing a resource through Terraform; can preserve the real object |
| `import` block | Bring an existing infrastructure object into Terraform state |

Quick examples:

- Renaming `aws_instance.app` to `aws_instance.application` → `moved`.
- Stop managing an EC2 instance but leave it running → `removed` with `destroy = false`.
- Import an EC2 instance created manually in AWS → `import`.

### 13. Safe Refactoring Workflow

1. Update the Terraform configuration.
2. Add the relevant `moved`, `removed`, or `import` block.
3. Run `terraform fmt`.
4. Run `terraform validate`.
5. Run `terraform plan`.
6. Review resource actions carefully.
7. Apply only after confirming the plan is correct.

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

For refactoring, a plan that unexpectedly proposes destroying and recreating an existing resource is a signal to stop and investigate.

---

## Final Exam Checklist

- [ ] Know common Terraform functions and how to use `terraform console`.
- [ ] Understand variables vs. locals.
- [ ] Know how locals reduce duplicated expressions and tags.
- [ ] Understand `count`, `count.index`, and indexed resource addresses.
- [ ] Understand `for_each`, `each.key`, and `each.value`.
- [ ] Know when `count` or `for_each` is more appropriate.
- [ ] Understand why state-aware refactoring is necessary.
- [ ] Know how to use a `moved` block for renaming or moving resources.
- [ ] Know how `removed` with `destroy = false` preserves real infrastructure.
- [ ] Understand import blocks versus the CLI `terraform import` command.
- [ ] Always review the plan before applying a refactoring.

**Core takeaway:** Reusable Terraform code uses functions, locals, `count`, and `for_each` to reduce duplication. State refactoring uses `moved`, `removed`, and `import` blocks to change how resources are managed without causing unintended infrastructure changes.