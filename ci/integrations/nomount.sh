#!/bin/bash
# NoMount 内核集成

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KERNEL_ROOT="${KERNEL_ROOT:-${GITHUB_WORKSPACE:-$(pwd)}}"
CI_OUT="${CI_OUT:-$KERNEL_ROOT/out}"
CI_CONFIG="${CI_CONFIG:-$CI_OUT/.config}"
export KERNEL_ROOT CI_OUT CI_CONFIG

. "$SCRIPT_DIR/_lib.sh"

NOMOUNT_SRC="${NOMOUNT_SRC:-}"
NOMOUNT_REPO="${NOMOUNT_REPO:-https://github.com/maxsteeel/nomount}"
NOMOUNT_REF="${NOMOUNT_REF:-v2.2.0}"
NOMOUNT_SUBDIR="${NOMOUNT_SUBDIR:-kernel/src}"
NOMOUNT_CLONE_DIR="${NOMOUNT_CLONE_DIR:-$KERNEL_ROOT/.nomount-src}"

if [ -n "$NOMOUNT_SRC" ]; then
    src="$NOMOUNT_SRC"
else
    ci_info "cloning NoMount: $NOMOUNT_REPO ${NOMOUNT_REF:+(ref=$NOMOUNT_REF)}"
    rm -rf "$NOMOUNT_CLONE_DIR"
    if [ -n "$NOMOUNT_REF" ] && \
       git clone --quiet --branch "$NOMOUNT_REF" "$NOMOUNT_REPO" "$NOMOUNT_CLONE_DIR" 2>/dev/null; then
        :
    else
        rm -rf "$NOMOUNT_CLONE_DIR"
        git clone --quiet "$NOMOUNT_REPO" "$NOMOUNT_CLONE_DIR" \
            || ci_die "failed to clone NoMount"
        if [ -n "$NOMOUNT_REF" ]; then
            git -C "$NOMOUNT_CLONE_DIR" fetch --quiet origin "$NOMOUNT_REF" \
                || ci_die "failed to fetch NoMount ref: $NOMOUNT_REF"
            git -C "$NOMOUNT_CLONE_DIR" checkout --quiet FETCH_HEAD \
                || ci_die "failed to check out NoMount ref: $NOMOUNT_REF"
        fi
    fi
    src="$NOMOUNT_CLONE_DIR/$NOMOUNT_SUBDIR"
fi

[ -d "$src" ] || ci_die "NoMount source directory not found: $src"
[ -f "$src/Kconfig" ] || ci_die "NoMount source is missing Kconfig: $src/Kconfig"
[ -f "$src/Makefile" ] || ci_die "NoMount source is missing Makefile: $src/Makefile"


rm -rf "$KERNEL_ROOT/fs/nomount"
rel_src=$(realpath --relative-to="$KERNEL_ROOT/fs" "$src") \
    || ci_die "cannot compute relative path to NoMount source: $src"
ln -sfn "$rel_src" "$KERNEL_ROOT/fs/nomount" \
    || ci_die "failed to create fs/nomount symlink"
ci_info "linked fs/nomount -> $rel_src (temporary, not committed)"


ci_apply_patch "$SCRIPT_DIR/patches/nomount-0001-fs-hooks.patch"

ci_enable_config CONFIG_NOMOUNT
ci_olddefconfig
ci_require_config CONFIG_NOMOUNT

ci_info "NoMount integration done"
