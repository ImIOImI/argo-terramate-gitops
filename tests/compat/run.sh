#!/usr/bin/env bash
# Toolchain compatibility matrix for the mini stacks under tests/compat/.
#
#   tests/compat/run.sh [terramate|tofu|all]
#
# Environment:
#   TM_VERSIONS    Terramate versions to test       (default: the floor and latest)
#   TOFU_VERSIONS  OpenTofu versions to test        (default: the floor and latest)
#   AWS_VERSIONS   AWS provider versions to test    (default: the floor and latest)
#   PROBE=1        ignore the committed version constraints, to find a new floor
#   COMPAT_CACHE   where downloaded binaries and providers are kept
#
# Terramate check: in a scratch copy of the repo, `terramate generate` must
# leave every committed generated file unchanged, `terramate list` must see
# both compat stacks, and `terramate script run` must work with the flags
# the Makefile passes.
# OpenTofu check: tests/compat/aws-plan must init, validate and plan offline
# with exactly the given OpenTofu and AWS provider versions. Without PROBE,
# the committed constraints from _tmgen_versions.tf still apply, so a
# version outside the pinned range fails.
set -uo pipefail

ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
MODE=${1:-all}
TM_VERSIONS=${TM_VERSIONS:-"0.11.8 0.17.4"}
TOFU_VERSIONS=${TOFU_VERSIONS:-"1.6.0 1.13.9"}
AWS_VERSIONS=${AWS_VERSIONS:-"6.0.0 6.73.0"}
CACHE=${COMPAT_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/argo-terramate-gitops/compat}
mkdir -p "$CACHE/bin" "$CACHE/plugins"

case "$(uname -s)" in Linux) OS=linux ;; Darwin) OS=darwin ;; *) echo "unsupported OS" >&2; exit 2 ;; esac
case "$(uname -m)" in
  x86_64 | amd64) TM_ARCH=x86_64 TOFU_ARCH=amd64 ;;
  arm64 | aarch64) TM_ARCH=arm64 TOFU_ARCH=arm64 ;;
  *) echo "unsupported arch" >&2; exit 2 ;;
esac

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }

# fetch <url> <sums-url> <asset-name> <dest>: download and verify a release asset.
fetch() {
  local url=$1 sums=$2 name=$3 dest=$4 want got
  curl -fsSL -o "$dest" "$url" || return 1
  want=$(curl -fsSL "$sums" | awk -v n="$name" '$2 == n || $2 == "*"n {print $1}')
  got=$(sha256 "$dest")
  [[ -n $want && $want == "$got" ]] || { echo "checksum mismatch for $name" >&2; rm -f "$dest"; return 1; }
}

terramate_bin() {
  local v=$1 bin="$CACHE/bin/terramate-$1"
  if [[ ! -x $bin ]]; then
    local name="terramate_${v}_${OS}_${TM_ARCH}.tar.gz" base="https://github.com/terramate-io/terramate/releases/download/v$v" tmp
    tmp=$(mktemp -d)
    fetch "$base/$name" "$base/checksums.txt" "$name" "$tmp/$name" || { rm -rf "$tmp"; return 1; }
    tar -xzf "$tmp/$name" -C "$tmp" terramate && mv "$tmp/terramate" "$bin"
    rm -rf "$tmp"
  fi
  echo "$bin"
}

tofu_bin() {
  local v=$1 bin="$CACHE/bin/tofu-$1"
  if [[ ! -x $bin ]]; then
    local name="tofu_${v}_${OS}_${TOFU_ARCH}.zip" base="https://github.com/opentofu/opentofu/releases/download/v$v" tmp
    tmp=$(mktemp -d)
    fetch "$base/$name" "$base/tofu_${v}_SHA256SUMS" "$name" "$tmp/$name" || { rm -rf "$tmp"; return 1; }
    unzip -q "$tmp/$name" tofu -d "$tmp" && mv "$tmp/tofu" "$bin"
    rm -rf "$tmp"
  fi
  echo "$bin"
}

# Pull a quoted attribute value out of a generated .tf file.
tf_attr() { sed -nE "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"([^\"]*)\".*/\1/p" "$2" | head -1; }

RESULTS=()
FAILED=0
record() { # record <PASS|FAIL> <label> [detail]
  RESULTS+=("$(printf '%-4s  %s' "$1" "$2")")
  [[ $1 == PASS ]] || { FAILED=1; [[ -n ${3:-} ]] && printf '%s\n' "$3" | sed 's/^/      /' | tail -15 >&2; }
}

check_terramate() {
  local v=$1 bin work out
  bin=$(terramate_bin "$v") || { record FAIL "terramate $v" "download failed"; return; }
  work=$(mktemp -d)
  # Scratch copy of the tracked tree so generate can't touch the real checkout.
  (cd "$ROOT" && git ls-files -z --cached --others --exclude-standard | tar --null -cf - -T -) | tar -xf - -C "$work"
  if [[ ${PROBE:-0} == 1 ]]; then
    sed -i.bak -E 's/required_version[[:space:]]*=.*/required_version = ">= 0.0.0"/' "$work/terramate.tm.hcl" && rm -f "$work/terramate.tm.hcl.bak"
  fi
  (cd "$work" && git init -q && git add -A && git -c user.name=compat -c user.email=compat@localhost commit -qm base) >/dev/null
  if ! out=$(cd "$work" && "$bin" generate 2>&1); then
    record FAIL "terramate $v: generate" "$out"
  elif out=$(cd "$work" && git status --porcelain) && [[ -n $out ]]; then
    record FAIL "terramate $v: generated files differ from the committed ones" "$out$(cd "$work" && git diff)"
  elif ! out=$(cd "$work" && "$bin" list --tags compat 2>&1) ||
    [[ $(grep -c 'tests/compat/' <<<"$out") -ne 2 ]]; then
    record FAIL "terramate $v: list --tags compat" "$out"
  elif ! out=$(cd "$work" && "$bin" script run --tags compat --parallel 1 --disable-safeguards=git \
    --include-output-dependencies -- compat 2>&1) || ! grep -q compat-script-ok <<<"$out"; then
    record FAIL "terramate $v: script run (Makefile flags)" "$out"
  else
    record PASS "terramate $v"
  fi
  rm -rf "$work"
}

check_tofu() {
  local tv=$1 av=$2 bin work out req_tofu req_aws aws_constraint stack="$ROOT/tests/compat/aws-plan"
  bin=$(tofu_bin "$tv") || { record FAIL "tofu $tv + aws $av" "download failed"; return; }
  work=$(mktemp -d)
  cp "$stack"/*.tf "$work/" && rm -f "$work/_tmgen_versions.tf"
  aws_constraint="= $av"
  req_tofu=""
  if [[ ${PROBE:-0} != 1 ]]; then
    req_tofu=$(tf_attr required_version "$stack/_tmgen_versions.tf")
    req_aws=$(tf_attr version "$stack/_tmgen_versions.tf")
    aws_constraint="$req_aws, $aws_constraint"
  fi
  {
    echo 'terraform {'
    [[ -n $req_tofu ]] && echo "  required_version = \"$req_tofu\""
    echo '  required_providers {'
    echo "    aws = { source = \"hashicorp/aws\", version = \"$aws_constraint\" }"
    echo '  }'
    echo '}'
  } >"$work/versions.tf"
  export TF_PLUGIN_CACHE_DIR="$CACHE/plugins" TF_IN_AUTOMATION=1
  if ! out=$(cd "$work" && "$bin" init -input=false -no-color 2>&1); then
    record FAIL "tofu $tv + aws $av: init" "$out"
  elif ! out=$(cd "$work" && "$bin" validate -no-color 2>&1); then
    record FAIL "tofu $tv + aws $av: validate" "$out"
  elif ! out=$(cd "$work" && "$bin" plan -input=false -lock=false -refresh=false -no-color 2>&1); then
    record FAIL "tofu $tv + aws $av: plan" "$out"
  elif ! grep -q '1 to add' <<<"$out"; then
    record FAIL "tofu $tv + aws $av: plan did not propose the bucket" "$out"
  else
    record PASS "tofu $tv + aws $av"
  fi
  rm -rf "$work"
}

if [[ $MODE == terramate || $MODE == all ]]; then
  for v in $TM_VERSIONS; do check_terramate "$v"; done
fi
if [[ $MODE == tofu || $MODE == all ]]; then
  for tv in $TOFU_VERSIONS; do for av in $AWS_VERSIONS; do check_tofu "$tv" "$av"; done; done
fi

printf '%s\n' "${RESULTS[@]}"
exit $FAILED
