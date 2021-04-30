# Using Snyk IaC with Terragrunt

You integrate Snyk Infrastructure as Code into your Terragrunt workflow.

This example will automatically run Snyk IaC after every `plan` command.
If there are any issues returned by Snyk IaC then you'll see an error and the `terragrunt plan` command will fail.

## How to use

Copy the contents of the `terragrunt.hcl` file into your top-level `terragrunt.hcl` file and run `terragrunt plan`

If there are any configuration issues found - then the command will fail with the error

```bash
ERRO[0006] Hit multiple errors:
Hit multiple errors:
exit status 1
```

If no configuration issues are found, the command will finish successfully.

## Example

Running `terragrunt plan` on the provided `s3.tf` file would give the following output

```bash
➜  snyk-iac-terragrunt git:(main) ✗ terragrunt plan

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.pictures-of-snyk-dogs will be created
  + resource "aws_s3_bucket" "pictures-of-snyk-dogs" {
      + acceleration_status         = (known after apply)
      + acl                         = "public-read-write"
      + arn                         = (known after apply)
      + bucket                      = "pictures-of-snyk-dogs"
      + bucket_domain_name          = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = {
          + "Environment" = "Production"
          + "Name"        = "Pictures of Snyk Dogs"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + versioning {
          + enabled    = (known after apply)
          + mfa_delete = (known after apply)
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Saved the plan to: tf-plan.binary

To perform exactly these actions, run the following command to apply:
    terraform apply "tf-plan.binary"
INFO[0002] Executing hook: Convert Plan output to json
INFO[0003] Executing hook: Run Snyk Infrastructure as Code

Testing tf-plan.json...


Infrastructure as code issues:
  ✗ S3 Bucket is publicly readable and writable [High Severity] [SNYK-CC-TF-19] in S3
    introduced by resource > aws_s3_bucket[pictures-of-snyk-dogs] > acl

  ✗ S3 bucket MFA delete control disabled [Low Severity] [SNYK-CC-TF-127] in S3
    introduced by aws_s3_bucket[pictures-of-snyk-dogs] > versioning > mfa_delete

  ✗ S3 bucket versioning disabled [Low Severity] [SNYK-CC-TF-124] in S3
    introduced by aws_s3_bucket[pictures-of-snyk-dogs] > versioning > enabled


Organization:      ben.laplanche
Type:              Terraform
Target file:       tf-plan.json
Project name:      snyk-iac-terragrunt
Open source:       no
Project path:      tf-plan.json

Tested tf-plan.json for known issues, found 3 issues

ERRO[0006] Error running hook Run Snyk Infrastructure as Code with message: exit status 1
INFO[0006] Executing hook: Remove tf-plan.json
INFO[0006] Executing hook: Remove tf-plan.binary
ERRO[0006] Hit multiple errors:
Hit multiple errors:
exit status 1
```

You can see that 3 configuration issues were found and as a result the command failed as expected.

## Walkthrough

This functionality works as follows, all snippets shown are in `terragrunt.hcl`

```hcl
  extra_arguments "common_vars" {
    commands = ["plan"]

    arguments = [
      "-out=tf-plan.binary"
    ]
  }
```

This asks terragrunt to always save the output of the `terraform plan` command to a file called `tf-plan.binary`
We'll consider this to be a temporary file and clean it up later.

```hcl
  after_hook "Convert Plan output to json" {
    commands = ["plan"]
    execute      = ["sh", "-c", "terraform show -json tf-plan.binary > tf-plan.json"]
  }
```

Next we convert the `tf-plan.binary` file into a json file called `tf-plan.json`

```hcl
  after_hook "Run Snyk Infrastructure as Code" {
    commands = ["plan"]
    execute = ["sh", "-c", "snyk iac test tf-plan.json --experimental"]
```

We can now scan this file using the Snyk Infrastructure as Code CLI

```hcl
  after_hook "Remove tf-plan.json" {
    commands = ["plan"]
    execute = ["sh", "-c", "rm tf-plan.json"]
    run_on_error = true
  }
```

We then clean up the temporary `tf-plan.json` file.
We have `run_on_error = true` set here as the previous step of running Snyk IaC may return a non 0 exit code if any configuration issues are detected.

```hcl
  after_hook "Remove tf-plan.binary" {
    commands = ["plan"]
    execute = ["sh", "-c", "rm tf-plan.binary"]
    run_on_error = true
  }
```

Lastly we clean up the `tf-plan.binary` file as well.
