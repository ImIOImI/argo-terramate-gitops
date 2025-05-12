globals {
  # Changing this config should create
  clusters = {
    dev = {
      description = "Development cluster"
      tags = [

      ]
      configs = {

      }
      manifests = [
        "istio",
        "argoRollouts",
        "externalDNS",
      ]
    }
    stg = {
      description = "Staging cluster"
      tags = [

      ]
      configs = {

      }
      manifests = [
        "istio",
        "argoRollouts",
        "externalDNS",
      ]
    }
  }
}
