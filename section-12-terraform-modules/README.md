# Sections 11–12 — Refactoring Terraform State and Modules

# Section 11: Refactoring Terraform State

## 1. What Is State Refactoring?

Refactoring means changing the structure or address of Terraform resources without unnecessarily destroying and recreating the actual infrastructure.

Typical scenarios:
- Renaming a resource.
- Moving a resource into a module.
- Removing a resource from Terraform management.
- Importing an existing resource into Terraform state.

The main goal is to preserve existing infrastructure while changing how Terraform manages it.

## 2. The `moved` Block

Use the `moved` block when changing a resource address.

Example — renaming a resource:

Before:

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

After:

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

Terraform understands that the resource has moved to a new address instead of treating it as a new resource.

### Moving a resource into a module

```hcl
moved {
  from = aws_instance.app
  to   = module.app_infra.aws_instance.app
}
```

**Important:**
- `from` is the old resource address.
- `to` is the new resource address.
- The destination must exist in the new configuration.
- Review `terraform plan` before applying.

Keep historical `moved` blocks when they are needed to support users upgrading from older configurations.

## 3. The `removed` Block

Use the `removed` block when you want to stop managing a resource through Terraform.

Example — remove from state without destroying the actual infrastructure:

```hcl
removed {
  from = aws_instance.legacy

  lifecycle {
    destroy = false
  }
}
```

Apply the change:

```bash
terraform plan
terraform apply
```

The resource is removed from Terraform state, but the real infrastructure remains in AWS.

**Remember:**
- `destroy = false` means preserve the real resource.
- Removing a resource from state is not the same as destroying it.

## 4. The `import` Block

Use an `import` block to bring an existing infrastructure object into Terraform state.

Example:

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

Terraform plans the import and adds the existing object to state when applied.

The resource configuration must represent the real infrastructure. Import does not automatically generate a complete `.tf` configuration.

### CLI alternative

```bash
terraform import aws_instance.app i-0123456789abcdef0
```

The CLI import command imports the object into state. You still need to maintain the corresponding resource configuration.

## 5. moved vs. removed vs. import

| Feature | Purpose |
|---|---|
| `moved` | Change a resource address without recreating infrastructure |
| `removed` | Stop managing a resource through Terraform |
| `import` | Bring an existing infrastructure object into Terraform state |

Examples:

- Rename `aws_instance.app` → `moved`.
- Stop managing an EC2 instance but leave it running → `removed` with `destroy = false`.
- Import an EC2 instance created manually → `import`.

---

# Section 12: Terraform Modules

## 6. What Is a Terraform Module?

A Terraform module is a collection of Terraform configuration files in a directory.

Modules help:
- Reuse Terraform code.
- Reduce duplication.
- Organize infrastructure.
- Standardize resource provisioning.
- Build reusable infrastructure components.

Every Terraform configuration is technically a module.

### Root Module

The root module is the directory where you execute Terraform commands:

```bash
terraform init
terraform plan
terraform apply
```

### Child Module

A child module is a module called by another module through a `module` block.

Example structure:

```text
terraform-project/
├── main.tf
├── variables.tf
├── outputs.tf
└── modules/
    └── app_infra/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

Here:
- The project directory is the root module.
- `modules/app_infra` is a child module.

## 7. Calling a Module

Use the `module` block to call a child module.

```hcl
module "app_infra" {
  source = "./modules/app_infra"

  instance_type = "t3.micro"
  environment   = "dev"
}
```

The `source` argument specifies where Terraform should find the module.

Common source types:

| Source | Example |
|---|---|
| Local path | `./modules/network` |
| Terraform Registry | `terraform-aws-modules/vpc/aws` |
| Git repository | `git::https://github.com/example/modules.git` |

Local modules do not use Registry version constraints.

## 8. Parent and Child Module Relationships

A parent module calls a child module and passes input variables to it.

Example:

**Root module — main.tf**

```hcl
module "app" {
  source = "./modules/app"

  instance_type = "t3.small"
  environment   = "dev"
}
```

**Child module — variables.tf**

```hcl
variable "instance_type" {
  type = string
}

variable "environment" {
  type = string
}
```

**Child module — main.tf**

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Environment = var.environment
  }
}
```

**Important:** Child modules cannot directly access variables or locals declared in their parent modules. Values must be explicitly passed through module inputs.

## 9. Module Outputs

Child modules can expose values using output blocks.

**Child module — outputs.tf**

```hcl
output "instance_id" {
  value = aws_instance.app.id
}
```

The root module accesses the output through the module reference:

```hcl
output "app_instance_id" {
  value = module.app.instance_id
}
```

General syntax:

```hcl
module.<MODULE_NAME>.<OUTPUT_NAME>
```

Outputs are the main way for child modules to expose information to their parent modules.

## 10. Variable Scope in Modules

Variables are scoped to the module where they are declared.

Example:

```hcl
module "network" {
  source = "./modules/network"

  vpc_cidr = "10.0.0.0/16"
}
```

Inside the child module:

```hcl
variable "vpc_cidr" {
  type = string
}
```

Use the variable in the child module:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}
```

Remember:
- Parent passes values to child modules.
- Child modules receive values through input variables.
- Child modules expose values through outputs.
- Child modules do not automatically inherit parent variables or locals.

## 11. Module Versioning and Constraints

When using modules from the Terraform Registry, specify a version to control which module release Terraform uses.

Example:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "demo-vpc"
  cidr = "10.0.0.0/16"
}
```

Version constraints can be used:

```hcl
version = "~> 5.0"
```

This allows versions from 5.0.0 up to, but not including, 6.0.0.

Another example:

```hcl
version = "~> 5.21.0"
```

This allows versions from 5.21.0 up to, but not including, 5.22.0.

**Remember:** Module version constraints work similarly to provider version constraints, but they are specified inside the module block.

### Important distinction

- Provider version constraints are configured in the `terraform` block under `required_providers`.
- Registry module version constraints are configured inside the `module` block.
- Local modules do not support the Registry `version` argument.

## 12. Using Modules from Terraform Registry

Terraform Registry provides reusable modules created by HashiCorp, cloud providers, and the community.

Example:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "demo-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
}
```

After adding or changing a module source:

```bash
terraform init
```

Terraform downloads the module and prepares the working directory.

To upgrade modules within their configured version constraints:

```bash
terraform init -upgrade
```

**Important:** `terraform init -upgrade` may also upgrade providers within their configured constraints. Review the changes and lock file afterward.

## 13. Creating Your Own Modules

A reusable module should have a clear purpose and expose configurable inputs and useful outputs.

Recommended structure:

```text
modules/
└── ec2/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

Example module interface:

**variables.tf**

```hcl
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "environment" {
  type = string
}
```

**main.tf**

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Environment = var.environment
  }
}
```

**outputs.tf**

```hcl
output "instance_id" {
  value = aws_instance.app.id
}
```

Call the module from the root module:

```hcl
module "ec2" {
  source = "./modules/ec2"

  instance_type = "t3.small"
  environment   = "dev"
}
```

### Good module design practices

- Keep modules focused on one logical purpose.
- Use input variables for configurable values.
- Expose important values through outputs.
- Avoid hardcoding environment-specific settings.
- Document required inputs and outputs.
- Use versioning when publishing reusable modules.

## 14. Useful Module Concepts

| Concept | Description |
|---|---|
| Root module | The module where Terraform commands are executed |
| Child module | A module called by another module |
| `source` | Defines the module location |
| `version` | Selects a Registry module version |
| Input variables | Pass configuration from parent to child |
| Outputs | Expose values from child to parent |
| `terraform init` | Downloads and initializes modules |
| `terraform init -upgrade` | Upgrades modules and providers within configured constraints |

---

# Final Exam Checklist

## Section 11 — Refactoring

- [ ] Understand the purpose of state refactoring.
- [ ] Know how to use `moved` blocks.
- [ ] Understand moving resources into modules.
- [ ] Know how `removed` with `destroy = false` works.
- [ ] Understand `import` blocks versus CLI `terraform import`.
- [ ] Know the difference between `moved`, `removed`, and `import`.

## Section 12 — Modules

- [ ] Understand root modules and child modules.
- [ ] Know how to call a module using the `module` block.
- [ ] Understand local module sources versus Registry sources.
- [ ] Know how parent modules pass variables to child modules.
- [ ] Understand module input variables and outputs.
- [ ] Remember that child modules cannot directly access parent variables or locals.
- [ ] Understand module version constraints.
- [ ] Know the difference between provider and module version constraints.
- [ ] Understand `terraform init` and `terraform init -upgrade`.
- [ ] Know how to organize and create reusable modules.

## Most Important Takeaways

1. `moved` preserves an existing resource while changing its Terraform address.
2. `removed` can remove a resource from state without destroying the real infrastructure.
3. `import` brings an existing infrastructure object into Terraform state.
4. Modules are reusable collections of Terraform configuration.
5. Parent modules pass values through input variables; child modules return values through outputs.
6. Use Registry module version constraints to control module versions.
7. `terraform init` downloads and initializes modules; `terraform init -upgrade` upgrades eligible dependencies.