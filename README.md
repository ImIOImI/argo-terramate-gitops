# argo-terramate-gitops
Use Terramate to generate Argo manifests

## Creating a stack
### Creating a new cluster stack
```bash
terramate create \
  clusters/dev \
  --name "Dev Cluster" \
  --description "Development cluster"
  --id "dev-cluster"
```
### Creating a new manifest

#### Development clusters
```bash
terramate create \
  clusters/dev/system/argo-rollout \
  --name "Dev Argo Rollout" \
  --description "Development argo rollout application" \
  --id "dev-cluster-system-argo-rollout"

 terramate create \
  clusters/dev/system/external-dns \
  --name "Dev External DNS" \
  --description "Development external dns application" \
  --id "dev-cluster-system-external-dns"
```

#### Staging clusters
```bash
terramate create \
  clusters/stg/system/argo-rollout \
  --name "Stg Argo Rollout" \
  --description "Staging argo rollout application" \
  --id "stg-cluster-system-argo-rollout"

 terramate create \
  clusters/stg/system/external-dns \
  --name "Stg External DNS" \
  --description "Staging external dns application" \
  --id "stg-cluster-system-external-dns"

terramate create \
  clusters/stg/apps/guestbook \
  --name "Stg Argo Rollout" \
  --description "Staging argo rollout application" \
  --id "stg-cluster-apps-guestbook"

 terramate create \
  clusters/stg/system/argo-rollout \
  --name "Stg Argo Rollout" \
  --description "Staging argo rollout application" \
  --id "stg-cluster-system-argo-rollout"
```
