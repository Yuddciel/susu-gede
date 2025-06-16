#!/bin/sh
# Compile script for Compiling kernel
# Copyright (c) Mahiro X Rapli

# Setup
PHONE="Surya"
DEFCONFIG=surya_defconfig
COMPILERDIR="$(pwd)/../zyc-clang"
CLANG="ZYC Clang"
CODENAME="[A15]"
ZIPNAME="Lucifer-KSUNEXT-$(date '+%Y%m%d-%H%M').zip"
BOT_TOKEN="7485743487:AAEKPw9ubSKZKit9BDHfNJSTWcWax4STUZs"
CHAT_ID="-1002354747626"
kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dtb.img"
dtbo="out/arch/arm64/boot/dtbo.img"
export KBUILD_BUILD_USER=Mahiroo
export KBUILD_BUILD_HOST=HiraTeam

# Color Codes
cyan="\033[96m"
green="\033[92m"
red="\033[91m"
reset="\033[0m"

# Start timer
SECONDS=0

# Escape function for MarkdownV2 Telegram messages
escape_markdownv2() {
  echo "$1" | sed -e 's/\\/\\\\/g' \
                  -e 's/`/\\`/g' \
                  -e 's/\*/\\*/g' \
                  -e 's/_/\\_/g' \
                  -e 's/{/\\{/g' \
                  -e 's/}/\\}/g' \
                  -e 's/\[/\\[/g' \
                  -e 's/\]/\\]/g' \
                  -e 's/\(/\\(/g' \
                  -e 's/\)/\\)/g' \
                  -e 's/#/\\#/g' \
                  -e 's/\+/\\+/g' \
                  -e 's/-/\\-/g' \
                  -e 's/!/\\!/g' \
                  -e 's/\./\\./g' \
                  -e 's/&/\\&/g'
}

# Telegram send message function with MarkdownV2 parsing
send_telegram_message() {
  local text="$1"
  local escaped_text
  escaped_text=$(escape_markdownv2 "$text")

  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$escaped_text" \
    -d parse_mode="MarkdownV2" > /dev/null
}

# Telegram send document function with caption in MarkdownV2
send_telegram_document() {
  local file_path="$1"
  local caption="$2"
  local escaped_caption
  escaped_caption=$(escape_markdownv2 "$caption")

  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F document=@"$file_path" \
    -F caption="$escaped_caption" > /dev/null
}

# Print start message
echo -e "${cyan}===========================$reset"
echo -e "${cyan}=  START COMPILING KERNEL  =$reset"
echo -e "${cyan}===========================$reset"

# Setup compiler function
clang() {
  if [ -d "$COMPILERDIR" ]; then
    echo -e "\n${green}[!] Let's Build UwU...${reset}\n"
  else
    echo -e "\n${red}[!] AOSP-clang directory not found!!!${reset}\n"
    echo -e "${green}[+] Cloning AOSP-clang...${reset}\n"
    wget "$(curl -s https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt)" -O "zyc-clang.tar.gz"
    rm -rf "$COMPILERDIR"
    mkdir "$COMPILERDIR"
    tar -xf zyc-clang.tar.gz -C "$COMPILERDIR"
    rm -f zyc-clang.tar.gz
    echo -e "\n${green}[!] Let's Build UwU...${reset}\n"
  fi
}

# Cleanup function
clean() {
  echo -e "\n${red}[!] CLEANING UP ${reset}\n"
  rm -rf log.txt out
  make mrproper
}

# Build kernel function
build_kernel() {
  export PATH="$COMPILERDIR/bin:$PATH"
  make -j$(nproc) O=out ARCH=arm64 $DEFCONFIG

  if [ $? -ne 0 ]; then
    echo -e "\n${red}[!] BUILD FAILED${reset}\n"
    send_telegram_message "❌ *Build Failed* for device: $PHONE"
    exit 1
  fi

  echo -e "\n${green}==================================${reset}"
  echo -e "${green}= [!] START BUILD $DEFCONFIG${reset}"
  echo -e "==================================${reset}\n"

  make -j$(nproc) \
    O=out \
    ARCH=arm64 \
    LLVM=1 LLVM_IAS=1 \
    AR=llvm-ar NM=llvm-nm LD=ld.lld \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CC=clang \
    DTC_EXT=dtc \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee log.txt

  if [ ! -f "$kernel" ]; then
    echo -e "${red}[!] Kernel Image not found, build failed!${reset}"
    send_telegram_message "❌ Kernel build failed. Check logs."
    exit 1
  fi

  echo -e "${green}=============================================${reset}"
  echo -e "${green}= [+] Zipping up ...${reset}"
  echo -e "=============================================${reset}"

  # Clone or copy AnyKernel3 (example)
  if [ ! -d AnyKernel3 ]; then
    if ! git clone -q https://github.com/rinnsakaguchi/AnyKernel3.git -b FSociety AnyKernel3; then
      echo -e "${red}AnyKernel3 repo not found and clone failed! Aborting...${reset}"
      send_telegram_message "❌ AnyKernel3 repo not found & clone failed."
      exit 1
    fi
  fi

  cp "$kernel" "$dtb" "$dtbo" AnyKernel3/
  cd AnyKernel3 || exit
  git checkout FSociety &> /dev/null
  zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
  cd ..

  if [ -f "$ZIPNAME" ]; then
    duration="$((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
    CPU_INFO=${RUNNER_CPU:-$(nproc)}

    CAPTION="\
*===== KERNEL BUILD COMPLETE =====*\n\
\n\
*Device*      : $PHONE\n\
*Defconfig*   : $DEFCONFIG\n\
*Toolchain*   : $CLANG\n\
*Codename*    : $CODENAME\n\
*Zipname*     : $ZIPNAME\n\
*CPU*         : $CPU_INFO cores\n\
*Duration*    : $duration\n\
*Features*    : Latest SUSFS \& KSU | Spoof Uname 6\.6 GKI | Bypass Charging\n\
\n\
_Build by Mahiroo @ HiraTeam_"

    send_telegram_message "$CAPTION"
    send_telegram_document "$ZIPNAME" "$CAPTION"

    echo -e "${green}=============================${reset}"
    echo -e "${green}= SUCCESS COMPILE KERNEL  =${reset}"
    echo -e "${green}= Device     : $PHONE       =${reset}"
    echo -e "${green}= Defconfig  : $DEFCONFIG  =${reset}"
    echo -e "${green}= Toolchain  : $CLANG      =${reset}"
    echo -e "${green}= Codename   : $CODENAME   =${reset}"
    echo -e "${green}= Zipname    : $ZIPNAME    =${reset}"
    echo -e "${green}= CPU        : $CPU_INFO cores =${reset}"
    echo -e "${green}= Duration   : $duration   =${reset}"
    echo -e "${green}=============================${reset}"

  else
    echo -e "${red}[!] ZIP NOT FOUND! BUILD FAILED${reset}"
    send_telegram_message "❌ ZIP file not found. Build failed."
    exit 1
  fi
}

clang
clean
build_kernel
