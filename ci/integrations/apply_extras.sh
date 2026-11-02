#!/bin/bash
# CI 可选内核集成调度器。
#
# 由 ci/build_ci.sh 与 ci/build_ksu_ci.sh 在 make defconfig 之后、内核编译之前调用
# 开关来自 workflow 环境变量：DROIDSPACES / REKERNEL / NOMOUNT



SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KERNEL_ROOT="${KERNEL_ROOT:-${GITHUB_WORKSPACE:-$(pwd)}}"
CI_OUT="${CI_OUT:-$KERNEL_ROOT/out}"
CI_CONFIG="${CI_CONFIG:-$CI_OUT/.config}"
export KERNEL_ROOT CI_OUT CI_CONFIG

. "$SCRIPT_DIR/_lib.sh"

DROIDSPACES="${DROIDSPACES:-off}"
REKERNEL="${REKERNEL:-false}"
NOMOUNT="${NOMOUNT:-false}"

ci_info "optional integrations: DroidSpaces=$DROIDSPACES Re:Kernel=$REKERNEL NoMount=$NOMOUNT"

if ci_is_on "$DROIDSPACES"; then
    bash "$SCRIPT_DIR/droidspaces.sh" "$DROIDSPACES" || ci_die "DroidSpaces integration failed"
fi

if ci_is_on "$REKERNEL"; then
    bash "$SCRIPT_DIR/rekernel.sh" || ci_die "Re:Kernel integration failed"
fi

if ci_is_on "$NOMOUNT"; then
    bash "$SCRIPT_DIR/nomount.sh" || ci_die "NoMount integration failed"
fi

ci_info "optional integrations done"
