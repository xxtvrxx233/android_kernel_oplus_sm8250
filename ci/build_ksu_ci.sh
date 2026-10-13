#!/bin/bash

KERNEL_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
KERNEL_OUTPUT=$KERNEL_ROOT/out/arch/arm64/boot
KSU_KBUILD="$KERNEL_ROOT/KernelSU/kernel/Kbuild"
KCONFIG_FILE="$KERNEL_ROOT/drivers/Kconfig"
KSU_KCONFIG_LINE='source "drivers/kernelsu/Kconfig"'
MAKEFILE_FILE="$KERNEL_ROOT/drivers/Makefile"
KSU_MAKEFILE_LINE='obj-$(CONFIG_KSU) += kernelsu/'

# ARCH
export ARCH=arm64
export SUBARCH=arm64

# AnyKernel
AK3_PATH=$KERNEL_ROOT/anykernel
CUSTOM_AK3_NAME=BT-BakaSU-BPF-5.10
FULL_AK3_NAME=$CUSTOM_AK3_NAME-$(date +%Y-%m-%d)

if [ ! -d "$AK3_PATH" ]; then
    git clone --depth=1 -b realme-sm8250 https://github.com/xxtvrxx233/AnyKernel3.git $AK3_PATH
fi

# Clean existing anykernel packages
if find $AK3_PATH -maxdepth 1 -type f -name "*.zip" | grep -q .; then
    find $AK3_PATH -maxdepth 1 -type f -name "*.zip" -delete
fi

# BakaSU
curl -LSs "https://raw.githubusercontent.com/xxtvrxx233/BakaSU/main/kernel/setup.sh" | bash

# Modify repo name
BASE_VER=$(grep -oE 'expr [0-9]+' "$KERNEL_ROOT/KernelSU/kernel/Kbuild" | awk '{print $2}' || echo "30000")

cd "$KERNEL_ROOT/KernelSU"
KSU_LOCAL_VERSION=$(git rev-list --count HEAD 2>/dev/null || echo "0")
KSU_HASH=$(git rev-parse --short=8 HEAD 2>/dev/null || echo "unknown")
KSU_VERSION_CODE=$(expr $BASE_VER + $KSU_LOCAL_VERSION + 700 2>/dev/null || echo "30700")
KSU_TAG=$(git describe --abbrev=0 --tags 2>/dev/null || echo "v4.1.0")
cd "$KERNEL_ROOT"

FINAL_KSU_VER="${KSU_TAG}-${KSU_HASH}@xxtvrxx233-Github_actions"
echo ">>> Version Code: $KSU_VERSION_CODE"
echo ">>> Version Name: $FINAL_KSU_VER"

export KSU_MAKE_ARGS="REPO_NAME=xxtvrxx233-Github_actions KSU_VERSION_FULL=$FINAL_KSU_VER KSU_COMMIT_SHA=$KSU_HASH KSU_VERSION=$KSU_VERSION_CODE"

# ---- drivers/Kconfig ----
if ! grep -qF "$KSU_KCONFIG_LINE" "$KCONFIG_FILE"; then
    echo "Injecting KSU Kconfig entry..."
    echo "" >> "$KCONFIG_FILE"
    echo "$KSU_KCONFIG_LINE" >> "$KCONFIG_FILE"
else
    echo "KSU Kconfig entry already present, skipping"
fi

# ---- drivers/Makefile ----
if ! grep -qF "$KSU_MAKEFILE_LINE" "$MAKEFILE_FILE"; then
    echo "Injecting KSU Makefile entry..."
    echo "" >> "$MAKEFILE_FILE"
    echo "$KSU_MAKEFILE_LINE" >> "$MAKEFILE_FILE"
else
    echo "KSU Makefile entry already present, skipping"
fi

# Clang Toolchain Logic
if [ ! -d "$KERNEL_ROOT/zyc-clang-16/bin" ]; then
    echo "Clang not found or cache missed, downloading..."
    if [ ! -f "/tmp/Clang-16.0.6-20250721.tar.gz" ]; then
        wget -O /tmp/Clang-16.0.6-20250721.tar.gz https://github.com/ZyCromerZ/Clang/releases/download/16.0.6-20250721-release/Clang-16.0.6-20250721.tar.gz
    fi
    mkdir -p "$KERNEL_ROOT/zyc-clang-16"
    tar -xvf /tmp/Clang-16.0.6-20250721.tar.gz -C "$KERNEL_ROOT/zyc-clang-16"
else
    echo "Clang toolchain restored from cache!"
fi

export CLANG_PATH=$KERNEL_ROOT/zyc-clang-16/bin
export PATH="/usr/lib/ccache:$CLANG_PATH:$PATH"
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

KERNEL_DEFCONFIG="vendor/kona-perf_defconfig vendor/ksu.config"

echo
echo "Kernel is going to be built using $KERNEL_DEFCONFIG"
echo


echo "=== KERNEL CONFIGURATION LOG ===" > "$KERNEL_ROOT/build.log"
make CC="ccache clang" AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip LLVM=1 LLVM_IAS=1 O=out $KERNEL_DEFCONFIG $KSU_MAKE_ARGS 2>&1 | tee -a "$KERNEL_ROOT/build.log"

echo "=== KERNEL COMPILATION LOG ===" >> "$KERNEL_ROOT/build.log"
make CC="ccache clang" AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip LLVM=1 LLVM_IAS=1 O=out $KSU_MAKE_ARGS -j$(nproc --all) 2>&1 | tee -a "$KERNEL_ROOT/build.log"

echo "Build complete"

ccache -s

if [ -f "$KERNEL_OUTPUT/dtb" ] && [ -f "$KERNEL_OUTPUT/dtbo.img" ] && [ -f "$KERNEL_OUTPUT/Image" ]; then
    cd $AK3_PATH
    cp "$KERNEL_OUTPUT/dtb"   .
    cp "$KERNEL_OUTPUT/dtbo.img"  .
    cp "$KERNEL_OUTPUT/Image"     .

echo "[+] Kernel files copied to $AK3_PATH"
else
    echo "[-] Error: Kernel files missing!"
    exit 1
fi
