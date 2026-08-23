#!/bin/bash

KERNEL_ROOT=$PWD
DRIVER_DIR="$KERNEL_ROOT/drivers"
KERNEL_OUTPUT=$KERNEL_ROOT/out/arch/arm64/boot

# ARCH
export ARCH=arm64
export SUBARCH=arm64

# AnyKernel
AK3_PATH=$KERNEL_ROOT/anykernel
CUSTOM_AK3_NAME=ReSukiSU-BPF-5.15-mysterious
FULL_AK3_NAME=$CUSTOM_AK3_NAME-$(date +%Y-%m-%d)

if [ ! -d "$AK3_PATH" ]; then
    git clone --depth=1 -b realme-sm8250 https://github.com/xxtvrxx233/AnyKernel3.git $AK3_PATH
fi

# Clean existing anykernel packages
if find $AK3_PATH -maxdepth 1 -type f -name "*.zip" | grep -q .; then
    find $AK3_PATH -maxdepth 1 -type f -name "*.zip" -delete
fi

# Clang
if [ ! -d "$KERNEL_ROOT/zyc-clang-16" ]; then
    if [ ! -f "/tmp/Clang-16.0.6-20250721.tar.gz" ]; then
        wget -O /tmp/Clang-16.0.6-20250721.tar.gz https://github.com/ZyCromerZ/Clang/releases/download/16.0.6-20250721-release/Clang-16.0.6-20250721.tar.gz
    fi
    mkdir "$KERNEL_ROOT/zyc-clang-16"
    tar -xvf /tmp/Clang-16.0.6-20250721.tar.gz -C "$KERNEL_ROOT/zyc-clang-16"
fi



# ReSukiSU
if [ ! -d "$KERNEL_ROOT/KernelSU" ]; then
     curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash
fi

echo "Preparing KSU build environment..."

# ---- drivers/Kconfig ----
KCONFIG_FILE="drivers/Kconfig"
KSU_KCONFIG_LINE='source "drivers/kernelsu/Kconfig"'

if ! grep -qF "$KSU_KCONFIG_LINE" "$KCONFIG_FILE"; then
    echo "Injecting KSU Kconfig entry..."
    echo "" >> "$KCONFIG_FILE"
    echo "$KSU_KCONFIG_LINE" >> "$KCONFIG_FILE"
else
    echo "KSU Kconfig entry already present, skipping"
fi

# ---- drivers/Makefile ----
MAKEFILE_FILE="drivers/Makefile"
KSU_MAKEFILE_LINE='obj-$(CONFIG_KSU) += kernelsu/'

if ! grep -qF "$KSU_MAKEFILE_LINE" "$MAKEFILE_FILE"; then
    echo "Injecting KSU Makefile entry..."
    echo "" >> "$MAKEFILE_FILE"
    echo "$KSU_MAKEFILE_LINE" >> "$MAKEFILE_FILE"
else
    echo "KSU Makefile entry already present, skipping"
fi

echo "KSU injection completed"

export CLANG_PATH=$KERNEL_ROOT/zyc-clang-16/bin
export PATH="$CLANG_PATH:$PATH"
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

KERNEL_DEFCONFIG="vendor/kona-perf_defconfig vendor/ksu.config"

echo "Build for OnePlus?"
read -r -p "Input [y / n]: " select

if [ "$select" = "y" ]; then
    export BRAND_SHOW_FLAG=oneplus
fi

echo
echo "Kernel is going to be built using $KERNEL_DEFCONFIG"
echo

make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip LLVM=1 LLVM_IAS=1 O=out $KERNEL_DEFCONFIG

make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip LLVM=1 LLVM_IAS=1 O=out -j$(nproc --all)

echo "Build complete"

if [ -f "$KERNEL_OUTPUT/dtb" ] && [ -f "$KERNEL_OUTPUT/dtbo.img" ] && [ -f "$KERNEL_OUTPUT/Image" ]; then
    cd $AK3_PATH
    cp "$KERNEL_OUTPUT/dtb"   .
    cp "$KERNEL_OUTPUT/dtbo.img"  .
    cp "$KERNEL_OUTPUT/Image"     .
    zip -r "$FULL_AK3_NAME.zip" *
    cd $KERNEL_ROOT

    echo "out: $AK3_PATH/$FULL_AK3_NAME.zip"

    # Clean existing 
    rm -f "$AK3_PATH/dtb"
    rm -f "$AK3_PATH/dtbo.img"
    rm -f "$AK3_PATH/Image"
fi
