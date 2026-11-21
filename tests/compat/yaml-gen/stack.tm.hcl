stack {
  name        = "Compat: YAML generation"
  description = "Mini stack exercising the Terramate features the manifests rely on"
  id          = "compat-yaml-gen"

  tags = [
    "compat",
    "argo",
  ]
}

globals {
  cluster = {
    name   = "compat"
    server = "https://kubernetes.default.svc"
  }
}

# Exercised the same way the Makefile drives `init`/`plan`.
script "compat" {
  description = "Prove script run works with the Makefile's flags"

  job {
    command = ["echo", "compat-script-ok"]
  }
}
