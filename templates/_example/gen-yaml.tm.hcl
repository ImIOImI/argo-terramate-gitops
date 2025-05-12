generate_file "_tmgen-appset.yaml" {
  condition = tm_contains(terramate.stack.tags, "argo")

  content = tm_yamlencode(let.manifest)

  lets {
    manifest = {
      "apiVersion" = "argoproj.io/v1alpha1"
      "kind"       = "ApplicationSet"
      "metadata" = {
        "name" = "sumer-platform-backend"
      }
      "spec" = {
        "generators" = [
          {
            "matrix" = {
              "generators" = [
                {
                  "clusters" = {
                    "selector" = {
                      "matchLabels" = {
                        "cluster_group" = "core-apps"
                        "cluster_type"  = "spoke"
                      }
                    }
                  }
                },
                {
                  "list" = {
                    "elements" = [
                      {
                        "appName" = "sumer-platform-backend"
                        "repoURL" = "https://github.com/SumerSports/sumer-platform-api.git"
                      },
                    ]
                  }
                },
              ]
            }
          },
        ]
        "goTemplate" = true
        "goTemplateOptions" = [
          "missingkey=error",
        ]
        "template" = {
          "metadata" = {
            "annotations" = {
              "dd_env"                                                                          = "{{.metadata.annotations.environment}}"
              "dd_service"                                                                      = "{{.appName}}"
              "notifications.argoproj.io/subscribe.cd-visibility-trigger.cd-visibility-webhook" = ""
            }
            "name" = "{{.appName}}-{{.metadata.annotations.environment}}"
          }
          "spec" = {
            "destination" = {
              "namespace" = "sumer-platform-apps"
              "server"    = "{{.server}}"
            }
            "ignoreDifferences" = [
              {
                "group" = "argoproj.io"
                "jsonPointers" = [
                  "/spec/replicas",
                ]
                "kind" = "Rollout"
              },
              {
                "group" = "apps"
                "jsonPointers" = [
                  "/spec/replicas",
                ]
                "kind" = "ReplicaSet"
              },
            ]
            "project" = "sumer-platform-apps"
            "sources" = [
              {
                "helm" = {
                  "parameters" = [
                    {
                      "name"  = "nameOverride"
                      "value" = "{{.appName}}"
                    },
                    {
                      "name"  = "environment"
                      "value" = "{{.metadata.annotations.environment}}"
                    },
                    {
                      "name"  = "metadata.repoUrl"
                      "value" = "https://github.com/SumerSports/sumer-platform-api"
                    },
                  ]
                  "valueFiles" = [
                    "$values/services/sumer-platform-api/helm/values.yaml",
                    "$values/services/sumer-platform-api/helm/{{.metadata.annotations.environment}}/values.yaml",
                  ]
                }
                "path"           = "charts/aws-microservice"
                "repoURL"        = "https://github.com/SumerSports/infra.git"
                "targetRevision" = "aws-microservice-0.6.18"
              },
              {
                "ref"            = "values"
                "repoURL"        = "{{.repoURL}}"
                "targetRevision" = "HEAD"
              },
            ]
            "syncPolicy" = {
              "automated" = {
                "prune"    = true
                "selfHeal" = true
              }
              "retry" = {
                "backoff" = {
                  "duration"    = "5s"
                  "factor"      = 2
                  "maxDuration" = "3m0s"
                }
                "limit" = 2
              }
              "syncOptions" = [
                "PruneLast=true",
                "ApplyOutOfSyncOnly=true",
                "CreateNamespace=true",
                "Replace=true",
                "RespectIgnoreDifferences=true",
              ]
            }
          }
        }
      }
    }
  }
}
