generate_file "_tmgen-base.yaml" {
  condition = tm_contains(terramate.stack.tags, "argo_rollout")

  content = tm_yamlencode(let.manifest)

  lets {
    manifest = {
      metadata = {
        finalizers = ["resources-finalizer.argocd.argoproj.io"]
        name       = "argo-rollouts-${var.global.clusterName}"
      }

      spec = {
        destination = {
          namespace = "argo-rollouts"
          server    = globals.cluster.server
        }

        project = "system"

        source = {
          chart           = "argo-rollouts"
          repo_url        = "https://argoproj.github.io/argo-helm"
          target_revision = "2.37.3"

          helm = {
            values = <<-EOT
              notifications:
                configmap:
                  create: false
            EOT
          }
        }

        sync_policy = {
          automated = {
            prune     = true
            self_heal = true
          }

          sync_options = [
            "PruneLast=true",
            "RespectIgnoreDifferences=true",
            "ApplyOutOfSyncOnly=true",
            "CreateNamespace=true"
          ]
        }
      }
    }
  }
}
