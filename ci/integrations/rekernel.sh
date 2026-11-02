#!/bin/bash
# Re:Kernel 内核集成。

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KERNEL_ROOT="${KERNEL_ROOT:-${GITHUB_WORKSPACE:-$(pwd)}}"
CI_OUT="${CI_OUT:-$KERNEL_ROOT/out}"
CI_CONFIG="${CI_CONFIG:-$CI_OUT/.config}"
export KERNEL_ROOT CI_OUT CI_CONFIG

. "$SCRIPT_DIR/_lib.sh"

ci_apply_patch "$SCRIPT_DIR/patches/rekernel-0001-core.patch"
ci_apply_patch "$SCRIPT_DIR/patches/rekernel-0002-call-sites.patch"

ci_enable_config CONFIG_REKERNEL

ci_olddefconfig
ci_require_config CONFIG_REKERNEL

ci_info "Re:Kernel integration done"
