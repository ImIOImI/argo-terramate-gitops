# Toolchain pins. The tested ranges live in tests/compat/README.md;
# re-run `make compat` after changing anything here.
terramate {
  required_version = ">= 0.11.8, < 0.18.0"

  config {
    # The Makefile drives tofu through `terramate script run
    # --include-output-dependencies`, which needs both experiments.
    experiments = ["scripts", "outputs-sharing"]
  }
}
