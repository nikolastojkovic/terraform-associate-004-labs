# Terraform Associate 004 — Sections 1–4

Quick reference notes for the **HashiCorp Certified: Terraform Associate (004)** exam.

Topics covered:

- Terraform Fundamentals
- Terraform Core and Providers
- Terraform Workflow
- Terraform CLI
- Terraform Plan
- Terraform State basics
- Dependencies
- Parallelism
- Resource Targeting

---

## 1. Terraform Core and Providers

Terraform consists of **Terraform Core** and **Terraform Providers**.

### Terraform Core

Terraform Core:

- reads and evaluates the HCL configuration
- builds the dependency graph
- compares the desired configuration with the known infrastructure state
- creates the execution plan
- determines which resources need to be created, changed, replaced, or destroyed

Terraform Core does **not** directly know how to create an AWS EC2 instance, Azure VM, GitHub repository, etc.

### Terraform Provider

A provider is a plugin that allows Terraform to communicate with an external API.

Examples:

```text
Terraform Core
      |
      +---- AWS Provider ----> AWS API
      |
      +---- Azure Provider --> Azure API
      |
      +---- GitHub Provider -> GitHub API
```

Example:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}
```

The AWS provider understands how to communicate with the AWS API.

---

## 2. Terraform Resource

A `resource` represents infrastructure that Terraform should manage.

Example:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-123456"
  instance_type = "t3.micro"
}
```

Terraform address:

```text
aws_instance.web
```

General format:

```text
<RESOURCE_TYPE>.<RESOURCE_NAME>
```

For example:

```text
aws_instance.web
aws_vpc.main
aws_subnet.public
```

---

# 3. Terraform Workflow

A common practical CLI workflow is:

```text
terraform init
      ↓
terraform fmt
      ↓
terraform validate
      ↓
terraform plan
      ↓
terraform apply
      ↓
terraform destroy
```

However, the **official core Terraform workflow** is:

```text
WRITE
  ↓
PLAN
  ↓
APPLY
```

### Write

Define the desired infrastructure using Terraform configuration (`.tf` files).

### Plan

Preview the changes Terraform intends to make.

### Apply

Execute the proposed changes.

### Exam reminder

If the exam asks:

> What are the three stages of the core Terraform workflow?

Answer:

**Write → Plan → Apply**

`terraform init` is an important preparation command, but **Init is not one of the three conceptual stages of the core workflow**.

---

# 4. terraform init

```bash
terraform init
```

Initializes the Terraform working directory.

Among other initialization tasks, Terraform can:

- initialize the configured backend
- find/install required providers
- download referenced modules
- create/update provider dependency information

It usually creates the local:

```text
.terraform/
```

directory.

### Important

`terraform init` does **not** mean:

> "Terraform reads all existing infrastructure from AWS and creates the state."

It also should not be thought of as a general command whose purpose is to verify cloud credentials.

Provider authentication/API access becomes relevant when Terraform performs operations that need to interact with the provider.

---

# 5. terraform fmt

```bash
terraform fmt
```

Formats Terraform configuration into Terraform's canonical style.

Example:

```bash
terraform fmt -recursive
```

formats Terraform files recursively through subdirectories.

---

# 6. terraform validate

```bash
terraform validate
```

Checks whether the Terraform configuration is internally valid.

Think:

```text
validate
   ↓
Is my Terraform configuration valid?
```

It does **not** validate whether the desired infrastructure is actually deployable to AWS/Azure.

For example, it does not generally answer questions such as:

- Does this AWS AMI really exist?
- Do my credentials have permission to create the resource?
- Is this resource allowed by the cloud account?

Those checks may require provider/API interaction during operations such as `plan` or `apply`.

---

# 7. terraform plan

```bash
terraform plan
```

Creates an **execution plan**.

Terraform determines what changes are necessary to move from the current situation toward the desired configuration.

Conceptually:

```text
Terraform Configuration
       +
Terraform State
       +
Real Infrastructure / Provider
       ↓
     PLAN
       ↓
Proposed changes
```

`terraform plan` does **not normally apply those changes**.

It tells us what Terraform intends to do.

---

# 8. Terraform Plan Symbols

Important symbols in `terraform plan`:

| Symbol | Meaning |
|---|---|
| `+` | Create |
| `-` | Destroy |
| `~` | Update in-place |
| `-/+` | Destroy and then create replacement |
| `+/-` | Create replacement and then destroy old object |

Examples:

```text
+ aws_instance.web
```

Terraform intends to create the resource.

```text
- aws_instance.web
```

Terraform intends to destroy it.

```text
~ aws_instance.web
```

Terraform intends to update it in-place.

```text
-/+ aws_instance.web
```

Terraform must replace the resource:

```text
DESTROY
   ↓
CREATE
```

---

# 9. terraform apply

```bash
terraform apply
```

Executes the changes required to reach the desired configuration.

Typical workflow:

```bash
terraform plan
terraform apply
```

A saved plan can also be created:

```bash
terraform plan -out=tfplan
```

and then applied:

```bash
terraform apply tfplan
```

This is useful because Terraform applies the previously generated plan rather than generating a new one at that point.

---

# 10. terraform destroy

```bash
terraform destroy
```

Destroys infrastructure managed by the current Terraform configuration/state.

Always inspect what Terraform intends to destroy before confirming destructive operations.

---

# 11. Terraform State — Basic Concept

Terraform state records Terraform's mapping between configuration objects and managed real-world objects.

Default local state file:

```text
terraform.tfstate
```

Example:

```text
Terraform configuration

aws_instance.web
       |
       | mapping stored in state
       ↓
AWS EC2
i-0123456789abcdef
```

Think of it this way:

```text
CONFIGURATION
"What do I want?"

       ↓

TERRAFORM STATE
"What objects does Terraform know/manage?"

       ↕

REAL INFRASTRUCTURE
"What actually exists?"
```

State will be covered much more deeply later in the course.

### Important exam concept

Do **not** confuse:

```text
terraform.tfstate
```

with:

```text
.terraform.lock.hcl
```

They have completely different purposes.

---

# 12. What if terraform.tfstate is deleted?

If local state is lost while the infrastructure still exists, Terraform does **not simply rediscover everything and reconstruct the state automatically**.

For example:

```text
AWS:
EC2 exists

Configuration:
aws_instance.web exists

State:
MISSING
```

Terraform has lost its mapping to that existing EC2 object.

This can cause Terraform to attempt to create another resource.

Existing infrastructure may need to be brought back under Terraform management using mechanisms such as **import**.

Therefore:

> Terraform state is important and should be protected.

---

# 13. Configuration Drift

Example:

Terraform configuration says:

```text
EC2 should exist
```

State knows about:

```text
EC2 i-12345
```

But someone manually deletes the EC2 instance through AWS Console.

Now:

```text
Desired configuration: EC2 exists
State:                 EC2 is managed
Real AWS:              EC2 missing
```

Terraform detects a difference between the desired/known configuration and real infrastructure during its normal refresh/planning behavior.

A subsequent plan will generally propose recreating the missing resource:

```text
+ aws_instance.web
```

This is an example of **infrastructure drift**.

---

# 14. Dependencies

Terraform builds a **dependency graph** to determine the correct order of operations.

There are two important concepts:

## Implicit Dependencies

Terraform can automatically detect a dependency when one resource references another.

Example:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.1.0/24"
}
```

Terraform sees:

```hcl
vpc_id = aws_vpc.main.id
```

and therefore knows:

```text
aws_vpc.main
      ↓
aws_subnet.public
```

The VPC must exist before Terraform can create the subnet.

This is an **implicit dependency**.

---

## Explicit Dependencies

Sometimes the dependency is real but Terraform cannot infer it from references in the configuration.

Then we can use:

```hcl
depends_on
```

Example:

```hcl
resource "example_resource" "app" {

  depends_on = [
    example_resource.database
  ]
}
```

This explicitly tells Terraform:

```text
database
    ↓
   app
```

### Important

Prefer **implicit dependencies** when Terraform can infer the relationship naturally.

Use `depends_on` when there is a genuine dependency that Terraform **cannot infer from the configuration**.

Do not add `depends_on` everywhere unnecessarily.

---

# 15. Terraform Parallelism

Terraform can perform independent operations concurrently.

By default, Terraform limits concurrent graph operations to:

```text
10
```

The limit can be changed with:

```bash
terraform apply -parallelism=5
```

Example:

```text
Default:

10 concurrent operations

With:

-parallelism=5

5 concurrent operations
```

### Why reduce parallelism?

Possible reasons include:

- API rate limits
- provider/API throttling
- troubleshooting
- reducing concurrent pressure on an external API

Example:

```bash
terraform apply -parallelism=2
```

This does **not** mean Terraform ignores dependencies.

Terraform still respects its dependency graph.

---

# 16. Resource Targeting

Terraform supports the `-target` option.

Example:

```bash
terraform plan -target=aws_instance.web
```

or:

```bash
terraform apply -target=aws_instance.web
```

This asks Terraform to focus planning/applying on a particular resource address and the dependencies needed for it.

### Important exam point

`-target` is **not intended to be the normal everyday Terraform workflow**.

It is mainly useful for exceptional circumstances such as:

- troubleshooting
- recovering from errors
- working around unusual situations

Normal Terraform operations should generally allow Terraform to evaluate the complete dependency graph.

### Destroy targeting

A targeted destroy can be performed with:

```bash
terraform destroy -target=aws_instance.web
```

Be careful: targeting individual resources can have consequences for dependent infrastructure.

---

# 17. Important Distinctions

### Terraform Core vs Provider

```text
Terraform Core
    ↓
understands configuration
builds dependency graph
creates plan

Provider
    ↓
understands external API
AWS / Azure / GitHub / etc.
```

---

### validate vs plan

```text
terraform validate
        ↓
configuration validity

terraform plan
        ↓
what infrastructure changes are needed?
```

---

### Configuration vs State

```text
Configuration = what I WANT

State = what Terraform KNOWS/MANAGES

Real infrastructure = what ACTUALLY EXISTS
```

---

### Implicit vs Explicit Dependency

```text
Implicit
Resource reference
      ↓
Terraform discovers dependency


Explicit
depends_on
      ↓
We explicitly declare dependency
```

---

# 18. Quick Exam Review

Before moving to the next sections, I should be able to answer these without looking at the notes:

1. What are the three stages of the official Terraform workflow?

2. What is the difference between Terraform Core and a Terraform provider?

3. What does `terraform init` do?

4. What is the difference between `terraform validate` and `terraform plan`?

5. Does `terraform plan` normally modify infrastructure?

6. What does `+` mean in a Terraform plan?

7. What does `-` mean?

8. What does `~` mean?

9. What does `-/+` mean?

10. What is Terraform state?

11. What can happen if state is lost but the real infrastructure still exists?

12. What happens if an EC2 instance managed by Terraform is manually deleted but remains in the configuration?

13. What is an implicit dependency?

14. When should `depends_on` be used?

15. What is Terraform's default parallelism limit?

16. Why might `-parallelism` be reduced?

17. What does `-target` do?

18. Should `-target` be part of the normal Terraform workflow?

---

## Sections 1–4 — Key Exam Reminders

```text
Official workflow:
WRITE → PLAN → APPLY

terraform init:
Initialize working directory

terraform validate:
Validate configuration

terraform plan:
Preview proposed infrastructure changes

terraform apply:
Execute changes

terraform destroy:
Destroy managed infrastructure

Plan:
+   CREATE
-   DESTROY
~   UPDATE IN-PLACE
-/+ REPLACE (destroy, then create)

Dependencies:
Implicit → Terraform infers from references
Explicit → depends_on

Default parallelism:
10

-target:
Exceptional/special-purpose targeting, not normal workflow

State:
Maps Terraform-managed objects to real infrastructure
```