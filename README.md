# argo-terramate-gitops
Use Terramate to generate Argo manifests

## Toolchain
| Tool | Constraint | Latest tested |
|------|------------|---------------|
| Terramate | `>= 0.11.8, < 0.18.0` | 0.17.4 |
| OpenTofu | `>= 1.6.0, < 2.0.0` | 1.13.9 |
| AWS provider | `>= 6.0.0, < 7.0.0` | 6.73.0 |

Pins live in `terramate.tm.hcl` and `versions.tm.hcl`; any stack tagged `tofu` gets a generated
`_tmgen_versions.tf`. `make compat` checks the floor and latest of each range against the mini
stacks in `tests/compat/` (see its README for how the ranges were found).

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
