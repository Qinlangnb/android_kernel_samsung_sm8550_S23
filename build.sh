#!/bin/bash
TOOLCHAIN=$(realpath "/home/kokuban/PlentyofToolchain/toolchainS23/prebuilts")

export PATH=$TOOLCHAIN/build-tools/linux-x86/bin:$PATH
export PATH=$TOOLCHAIN/build-tools/path/linux-x86:$PATH
export PATH=$TOOLCHAIN/clang/host/linux-x86/clang-r450784e/bin:$PATH
export PATH=$TOOLCHAIN/clang-tools/linux-x86/bin:$PATH

echo $PATH

set -e

LTO=thin

TARGET_DEFCONFIG=${1:-gki_defconfig}

cd "$(dirname "$0")"

LOCALVERSION=-android13-Kokuban-Firefly-GKI

ARGS="
CC=clang
ARCH=arm64
LLVM=1 LLVM_IAS=1
LOCALVERSION=$LOCALVERSION
"

# build kernel
make -j$(nproc) -C $(pwd) O=$(pwd)/out ${ARGS} $TARGET_DEFCONFIG

if [ "$LTO" = "thin" ]; then
  ./scripts/config --file out/.config -e LTO_CLANG_THIN -d LTO_CLANG_FULL
fi

make -j$(nproc) -C $(pwd) O=$(pwd)/out ${ARGS}

# pack AnyKernel3
cd out
if [ ! -d AnyKernel3 ]; then
  git clone --depth=1 https://github.com/YuzakiKokuban/AnyKernel3.git -b kalama
fi
cp arch/arm64/boot/Image AnyKernel3/zImage
name=S23_kernel_`cat include/config/kernel.release`_`date '+%Y_%m_%d'`
cd AnyKernel3
zip -r ${name}.zip * -x *.zip
cd ..
cp arch/arm64/boot/Image AnyKernel3/tools/kernel
cd AnyKernel3/tools
chmod +x libmagiskboot.so
lz4 boot.img.lz4
./libmagiskboot.so repack boot.img ${name}.img 
echo "boot.img output to $(realpath $name).img"
cd ..
cd ..
echo "AnyKernel3 package output to $(realpath $name).zip"
