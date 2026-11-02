#!/bin/bash
# DroidSpaces 容器支持

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KERNEL_ROOT="${KERNEL_ROOT:-${GITHUB_WORKSPACE:-$(pwd)}}"
CI_OUT="${CI_OUT:-$KERNEL_ROOT/out}"
CI_CONFIG="${CI_CONFIG:-$CI_OUT/.config}"
export KERNEL_ROOT CI_OUT CI_CONFIG

. "$SCRIPT_DIR/_lib.sh"

MODE="${1:-standard}"
case "$MODE" in
    standard|extend) ;;
    *) ci_die "DroidSpaces: unknown mode '$MODE' (expected standard or extend)" ;;
esac

ci_apply_patch "$SCRIPT_DIR/patches/droidspaces-0001-cgroup-noprefix-alias.patch"

# ---- 容器基础配置 ----
STANDARD_CONFIGS="
CONFIG_SYSVIPC
CONFIG_POSIX_MQUEUE
CONFIG_PID_NS
CONFIG_UTS_NS
CONFIG_IPC_NS
CONFIG_NET_NS
CONFIG_DEVTMPFS
CONFIG_TMPFS_XATTR
CONFIG_SECCOMP_FILTER
CONFIG_FW_LOADER
CONFIG_CGROUPS
CONFIG_CGROUP_DEVICE
CONFIG_CGROUP_PIDS
CONFIG_CGROUP_SCHED
CONFIG_FAIR_GROUP_SCHED
CONFIG_NETFILTER_ADVANCED
CONFIG_NETFILTER_XTABLES
CONFIG_NF_NAT
CONFIG_IP_NF_NAT
CONFIG_NF_TABLES
CONFIG_NF_NAT_REDIRECT
CONFIG_NF_NAT_IPV4
CONFIG_IP_NF_TARGET_MASQUERADE
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE
CONFIG_BRIDGE_NETFILTER
CONFIG_VETH
"

for cfg in $STANDARD_CONFIGS; do
    ci_enable_config "$cfg"
done

ci_disable_config CONFIG_CGROUP_NET_PRIO

# ---- extend 追加 ----
EXTEND_CONFIGS=""
if [ "$MODE" = "extend" ]; then
    EXTEND_CONFIGS="
CONFIG_USER_NS
CONFIG_MACVLAN
CONFIG_BT_HCIVHCI
"
    for cfg in $EXTEND_CONFIGS; do
        ci_enable_config "$cfg"
    done
    ci_disable_config CONFIG_STATIC_USERMODEHELPER
fi

ci_olddefconfig

for cfg in $STANDARD_CONFIGS; do
    ci_require_config "$cfg"
done
ci_require_config_off CONFIG_CGROUP_NET_PRIO

if [ "$MODE" = "extend" ]; then
    for cfg in $EXTEND_CONFIGS; do
        ci_require_config "$cfg"
    done
    ci_require_config_off CONFIG_STATIC_USERMODEHELPER
fi

ci_info "DroidSpaces ($MODE) configured"
