generate_file "_tmgen-base.yaml" {
  condition = tm_contains(terramate.stack.tags, "guestbook")

  content = tm_yamlencode(let.manifest)

  lets {
    manifest = {
      apiVersion = "argoproj.io/v1alpha1"
      kind       = "ApplicationSet"
      metadata = {
        name      = "guestbook"
        namespace = "argocd"
      }
      spec = {
        project = global.guestbook.project
        source = {
          repoURL        = "https://github.com/argoproj/argocd-example-apps.git"
          targetRevision = global.guestbook.target_revision
          path           = "guestbook"
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "guestbook"
        }
      }
    }
  }
}
