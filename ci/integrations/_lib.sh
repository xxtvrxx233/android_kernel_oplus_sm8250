#!/bin/bash
# CI 集成脚本公共函数

ci_info() { echo ">>> [integration] $*"; }
ci_warn() { echo ">>> [integration][warn] $*" >&2; }

ci_die() {
    echo ">>> [integration][error] $*" >&2
    exit 1
}

ci_is_on() {
    case "${1:-}" in
        ""|off|OFF|false|FALSE|0|no|NO) return 1 ;;
        *) return 0 ;;
    esac
}

ci_enable_config() {
    local cfg="$1"
    [ -x "$KERNEL_ROOT/scripts/config" ] || ci_die "cannot find $KERNEL_ROOT/scripts/config"
    [ -f "$CI_CONFIG" ] || ci_die "cannot find $CI_CONFIG; run defconfig first"
    "$KERNEL_ROOT/scripts/config" --file "$CI_CONFIG" --enable "$cfg"
    ci_info "enabled $cfg"
}

ci_apply_patch() {
    local patch_file="$1"; shift
    [ -f "$patch_file" ] || ci_die "patch not found: $patch_file"
    if git -C "$KERNEL_ROOT" apply --check "$patch_file" 2>/dev/null; then
        git -C "$KERNEL_ROOT" apply "$patch_file" || ci_die "git apply failed: $patch_file"
        ci_info "applied $(basename "$patch_file")"
    else
        # 兼容上游内核的 patch 格式（-p1 -F3）
        patch -d "$KERNEL_ROOT" -p1 -N -F 3 "$@" < "$patch_file" || ci_die "patch failed: $patch_file"
        ci_info "applied $(basename "$patch_file") (patch -p1)"
    fi
}

ci_disable_config() {
    local cfg="$1"
    [ -x "$KERNEL_ROOT/scripts/config" ] || ci_die "cannot find $KERNEL_ROOT/scripts/config"
    [ -f "$CI_CONFIG" ] || ci_die "cannot find $CI_CONFIG; run defconfig first"
    "$KERNEL_ROOT/scripts/config" --file "$CI_CONFIG" --disable "$cfg"
    ci_info "disabled $cfg"
}

ci_require_config() {
    local cfg="$1"
    if ! grep -q "^${cfg}=y$" "$CI_CONFIG"; then
        ci_die "config not applied: $cfg=y (dependency may be unmet, check build.log)"
    fi
    ci_info "verified: $cfg=y"
}

ci_require_config_off() {
    local cfg="$1"
    if grep -q "^${cfg}=" "$CI_CONFIG"; then
        ci_die "config still enabled: $cfg"
    fi
    ci_info "verified: $cfg disabled"
}

ci_olddefconfig() {
    local out_dir="${CI_OUT:-$KERNEL_ROOT/out}"
    make -C "$KERNEL_ROOT" O="$out_dir" ARCH=arm64 \
        CC="${CC:-clang}" \
        AR="${AR:-llvm-ar}" \
        NM="${NM:-llvm-nm}" \
        OBJCOPY="${OBJCOPY:-llvm-objcopy}" \
        OBJDUMP="${OBJDUMP:-llvm-objdump}" \
        STRIP="${STRIP:-llvm-strip}" \
        LLVM="${LLVM:-1}" \
        LLVM_IAS="${LLVM_IAS:-1}" \
        olddefconfig || ci_die "make olddefconfig failed"
    ci_info "olddefconfig done"
}
