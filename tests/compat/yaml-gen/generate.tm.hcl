# Same building blocks as templates/manifests/*: generate_file + condition,
# lets, globals, tm_contains, tm_yamlencode and a heredoc value.
generate_file "_tmgen-app.yaml" {
  condition = tm_contains(terramate.stack.tags, "argo")

  content = tm_yamlencode(let.manifest)

  lets {
    manifest = {
      apiVersion = "argoproj.io/v1alpha1"
      kind       = "Application"

      metadata = {
        name = "compat-${global.cluster.name}"
        annotations = {
          "argocd.argoproj.io/sync-wave" = "-20"
        }
      }

      spec = {
        destination = {
          namespace = "compat"
          server    = global.cluster.server
        }
        project = "system"
        source = {
          chart          = "external-dns"
          repoURL        = "https://kubernetes-sigs.github.io/external-dns"
          targetRevision = "1.14.5"
          helm = {
            values = <<-EOT
              serviceAccount:
                name: external-dns-sa
            EOT
          }
        }
        syncPolicy = {
          automated   = {}
          syncOptions = ["CreateNamespace=true"]
        }
      }
    }
  }
}
