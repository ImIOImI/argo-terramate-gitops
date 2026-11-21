# Toolchain compatibility tests

Two mini stacks, plus `run.sh`, which downloads each requested tool version
(checksum-verified, cached in `~/.cache/argo-terramate-gitops/compat`) and runs
the stacks against it.

| Stack | What it proves |
|-------|----------------|
| `yaml-gen` | `terramate generate` reproduces the committed `_tmgen-app.yaml` byte for byte (generate_file, lets, globals, `tm_contains`, `tm_yamlencode`, heredocs), `terramate list` sees the compat stacks, and `terramate script run` accepts the Makefile's flags |
| `aws-plan` | OpenTofu + the AWS provider init, validate and plan offline (mock credentials, every API lookup skipped) using the generated `_tmgen_versions.tf` |

```bash
make compat                                   # floor + latest of each range
TM_VERSIONS="0.16.0" tests/compat/run.sh terramate
TOFU_VERSIONS="1.10.10" AWS_VERSIONS="6.40.0" tests/compat/run.sh tofu
PROBE=1 TM_VERSIONS="0.11.7" tests/compat/run.sh terramate   # ignore pins, to look for a new floor
```

## Pinned ranges (tested 2026-11-21)

| Tool | Constraint | Where | Latest tested |
|------|------------|-------|---------------|
| Terramate | `>= 0.11.8, < 0.18.0` | `terramate.tm.hcl` | 0.17.4 |
| OpenTofu | `>= 1.6.0, < 2.0.0` | `versions.tm.hcl` → `_tmgen_versions.tf` | 1.13.9 |
| AWS provider | `>= 6.0.0, < 7.0.0` | `versions.tm.hcl` → `_tmgen_versions.tf` | 6.73.0 |

Results with the pins ignored (`PROBE=1`):

- **Terramate**: the latest patch of every minor from 0.4 to 0.17 passes generate/list. `script run` with the Makefile's
  `--parallel` / `--include-output-dependencies` flags first works in **0.11.8**; 0.11.0–0.11.7 and older fail.
  Both `scripts` and `outputs-sharing` are still experiments in 0.17.4, so `terramate.tm.hcl` enables them.
- **OpenTofu × AWS**: 1.6.0, and the latest patch of every minor from 1.6 to 1.13, each pass with AWS 5.100.0, 6.0.0
  and 6.73.0 (26 combinations in all). The AWS range is held to 6.x on purpose; 5.x works with this stack but is the old major.
- The upper bounds stop at the next untested release line: Terramate is pre-1.0, so a new minor can break things.

When a new release comes out, run it with `PROBE=1` first, then widen the
constraint and the defaults at the top of `run.sh`.
