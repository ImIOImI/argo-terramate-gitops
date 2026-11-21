# OpenTofu and provider pins, rendered into every stack tagged "tofu".
globals {
  toolchain = {
    tofu = ">= 1.6.0, < 2.0.0"
    aws  = ">= 6.0.0, < 7.0.0"
  }
}

generate_hcl "_tmgen_versions.tf" {
  condition = tm_contains(terramate.stack.tags, "tofu")

  content {
    terraform {
      required_version = global.toolchain.tofu

      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = global.toolchain.aws
        }
      }
    }
  }
}
