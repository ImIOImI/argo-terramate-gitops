generate_file "_tmgen-base.yaml" {
  condition = tm_contains(terramate.stack.tags, "argo_rollout")

  content = tm_yamlencode(let.manifest)

  lets {
    manifest = {
      api_version = "argoproj.io/v1alpha1"
      kind        = "Application"

      metadata = {
        name = "external-dns-${var.global.clusterName}"

        finalizers = [
          "resources-finalizer.argocd.argoproj.io"
        ]

        annotations = {
          "argocd.argoproj.io/sync-wave" = "-20"
        }
      }

      spec = {
        destination = {
          namespace = "external-dns"
          server    = globals.cluster.server
        }

        project = "system"

        source = {
          chart           = "external-dns"
          repo_url        = "https://kubernetes-sigs.github.io/external-dns"
          target_revision = "1.14.5"

          helm = {
            release_name = "external-dns"

            parameter = {
              name  = "provider"
              value = "aws"
            }

            parameter = {
              name  = "policy"
              value = "upsert-only"
            }

            values = <<-EOT
              serviceAccount:
                name: external-dns-sa
                annotations:
                  eks.amazonaws.com/role-arn: global.cluster.external_dns_iam_role_arn
            EOT
          }
        }

        sync_policy = {
          automated = {}

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
