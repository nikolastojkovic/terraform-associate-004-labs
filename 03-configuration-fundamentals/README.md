# Terraform Associate 004 — Section 7
## Configuration Fundamentals Cheat Sheet

---

## 1. Terraform Blocks

Main Terraform block types:

| Block | Purpose |
|---|---|
| `terraform` | Terraform version, providers, backend |
| `provider` | Configure connection to provider |
| `resource` | Create/manage infrastructure |
| `data` | Read existing infrastructure/data |
| `variable` | Define configurable input values |
| `output` | Expose values from configuration |
| `module` | Reuse/group Terraform configuration |
| `import` | Bring existing infrastructure under Terraform management |

---

# 2. Provider Block

Providers allow Terraform to communicate with APIs such as AWS, Azure, GitHub, Kubernetes, etc.

```hcl
provider "aws" {
  region = "eu-central-1"
}
```

Always check the **provider documentation** because each provider has its own resources, arguments and attributes.

## Multiple Provider Configurations / Aliases

```hcl
provider "aws" {
  alias  = "prod"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "dev"
  region = "us-east-1"
}
```

Assign a specific provider configuration to a resource:

```hcl
resource "aws_instance" "dev_instance" {
  provider = aws.dev

  ami           = "ami-123"
  instance_type = "t3.micro"
}
```

Useful for:

```text
Multi-region
Multi-account
Multiple provider configurations
```

---

# 3. Resource Block

Resources represent infrastructure managed by Terraform.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-123"
  instance_type = "t3.micro"
}
```

Resource address:

```text
aws_instance.web
```

Reference a resource attribute:

```hcl
aws_instance.web.id
```

Pattern:

```text
<resource_type>.<resource_name>.<attribute>
```

Use meaningful resource names:

```text
web
dev_instance
prod_database
public_subnet
```

---

# 4. Data Block

`data` reads information about **existing resources** instead of creating them.

```hcl
data "aws_vpc" "prod" {
  filter {
    name   = "tag:Name"
    values = ["prd-vpc"]
  }
}
```

Use the retrieved information elsewhere:

```hcl
resource "aws_subnet" "public" {
  vpc_id     = data.aws_vpc.prod.id
  cidr_block = "10.0.6.0/24"
}
```

Reference pattern:

```text
data.<type>.<name>.<attribute>
```

Examples:

```hcl
data.aws_vpc.prod.id
data.aws_vpc.prod.arn
data.aws_vpc.prod.cidr_block
data.aws_vpc.prod.owner_id
```

### Remember

```text
resource → manage infrastructure

data → read existing information
```

---

# 5. Variables

Variables make Terraform configuration reusable.

```hcl
variable "datacenter" {
  description = "vSphere datacenter"
  type        = string
  default     = "prd-workload-dc"
}
```

Reference:

```hcl
var.datacenter
```

---

## Primitive Types

```hcl
string
number
bool
```

Examples:

```hcl
type = string
type = number
type = bool
```

---

## Collection Types

### List

Ordered collection:

```hcl
variable "servers" {
  type = list(string)

  default = [
    "server1",
    "server2"
  ]
}
```

Access by index:

```hcl
var.servers[0]
var.servers[1]
```

---

### Map

Key/value collection:

```hcl
variable "course_details" {
  type = map(string)

  default = {
    instructor = "Bryan"
    course     = "Terraform"
  }
}
```

Access:

```hcl
var.course_details["instructor"]
```

---

### Set

Collection of **unique, unordered values**:

```hcl
variable "regions" {
  type = set(string)

  default = [
    "us-east-1",
    "eu-central-1"
  ]
}
```

Important:

```text
LIST
→ ordered
→ duplicates allowed
→ index access

SET
→ unordered
→ unique values
→ no normal index access
```

---

# 6. Assigning Variable Values

There are several ways to supply values.

## Default

```hcl
variable "environment" {
  type    = string
  default = "dev"
}
```

---

## Environment Variable

```bash
export TF_VAR_environment="prod"
```

Pattern:

```text
TF_VAR_<variable_name>
```

This overrides the variable's default value.

---

## terraform.tfvars

```hcl
environment = "prod"
region      = "eu-central-1"
```

Terraform automatically loads:

```text
terraform.tfvars
terraform.tfvars.json
*.auto.tfvars
*.auto.tfvars.json
```

---

## Environment-specific tfvars

Example:

```text
dev.tfvars
stage.tfvars
prod.tfvars
```

Use explicitly:

```bash
terraform plan -var-file="dev.tfvars"
```

A plain `dev.tfvars` is **not automatically loaded** just because it exists.

---

## Command Line

```bash
terraform plan -var="environment=prod"
```

Multiple values:

```bash
terraform plan \
  -var="environment=prod" \
  -var="region=eu-central-1"
```

---

# 7. Variable Precedence

For the normal Terraform CLI workflow, think roughly:

```text
LOWER PRIORITY

variable default
      ↓
TF_VAR_ environment variables
      ↓
terraform.tfvars
      ↓
terraform.tfvars.json
      ↓
*.auto.tfvars / *.auto.tfvars.json
      ↓
-var / -var-file

HIGHER PRIORITY
```

If the same variable receives multiple values, the higher-precedence source wins.

---

# 8. Outputs

Outputs expose useful information from Terraform configuration.

```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

Common outputs:

```text
IP addresses
DNS names
resource IDs
ARNs
URLs
```

Outputs are displayed after deployment and stored in Terraform state.

View outputs:

```bash
terraform output
```

Specific output:

```bash
terraform output public_ip
```

Outputs can also pass information between modules.

---

## Sensitive Output

```hcl
output "password" {
  value     = var.password
  sensitive = true
}
```

This prevents Terraform from normally displaying the value in CLI output.

### Important

`sensitive = true` does **NOT** mean the value is encrypted or removed from Terraform state.

```text
sensitive
→ hide/redact normal CLI display

NOT
→ encrypt/remove from state
```

Protect the state file.

---

# 9. Terraform Block

The `terraform` block defines Terraform-level configuration.

Example:

```hcl
terraform {
  required_version = "~> 1.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }

  backend "s3" {
    bucket = "my-terraform-state"
    key    = "state/terraform.tfstate"
    region = "eu-central-1"
  }
}
```

It can configure:

```text
Terraform version
Required providers
Provider versions
Backend/state configuration
```

---

# 10. Version Constraints

## Exact Version

```hcl
required_version = "1.12.2"
```

Only:

```text
1.12.2
```

---

## Greater Than or Equal

```hcl
required_version = ">= 1.12.0"
```

Allows:

```text
1.12.0
1.12.1
1.13.0
1.14.0
2.x
...
```

Be careful: `>=` does **not** restrict Terraform to the same major version.

---

## Pessimistic Constraint `~>`

```hcl
required_version = "~> 1.12.0"
```

Allows patch upgrades:

```text
1.12.0
1.12.1
1.12.2
...
```

but not:

```text
1.13.0
```

Think:

```text
~> 1.12.0
= >= 1.12.0 and < 1.13.0
```

---

# 11. Quick Exam Reminders

```text
provider
→ communicate with external API

provider alias
→ multiple configurations/regions/accounts

resource
→ create/manage infrastructure

data
→ read existing infrastructure

resource reference
→ aws_instance.web.id

data reference
→ data.aws_vpc.prod.id

variable
→ reusable input

var.name
→ reference variable

list
→ ordered + indexed

map
→ key/value

set
→ unique + unordered

TF_VAR_name
→ environment variable input

terraform.tfvars
→ automatically loaded

dev.tfvars
→ requires -var-file unless using .auto.tfvars naming

-var / -var-file
→ high precedence

output
→ expose useful values

sensitive = true
→ hides normal output, DOES NOT remove value from state

terraform block
→ Terraform/provider/backend requirements

"1.12.2"
→ exact

">= 1.12.0"
→ 1.12+ including future major versions

"~> 1.12.0"
→ 1.12.x only
```

## Self-check

Before moving on, I should be able to explain:

1. `resource` vs `data`
2. How provider aliases work
3. `list` vs `map` vs `set`
4. Ways to assign variable values
5. Variable precedence
6. What outputs are used for
7. What `sensitive = true` actually does
8. What belongs in the `terraform` block
9. Difference between `=`, `>=` and `~>` version constraints