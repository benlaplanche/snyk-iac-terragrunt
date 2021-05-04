terraform {

  extra_arguments "common_vars" {
    commands = ["plan"]

    arguments = [
      "-out=tf-plan.binary"
    ]
  }

  after_hook "Convert Plan output to json" {
    commands = ["plan"]
    execute      = ["sh", "-c", "terraform show -json tf-plan.binary > tf-plan.json"]
  }

  after_hook "Run Snyk Infrastructure as Code" {
    commands = ["plan"]
    execute = ["sh", "-c", "snyk iac test tf-plan.json --experimental --scan=planned-values"]
  }

  after_hook "Remove tf-plan.json" {
    commands = ["plan"]
    execute = ["sh", "-c", "rm tf-plan.json"]
    run_on_error = true
  }

  after_hook "Remove tf-plan.binary" {
    commands = ["plan"]
    execute = ["sh", "-c", "rm tf-plan.binary"]
    run_on_error = true
  }
}