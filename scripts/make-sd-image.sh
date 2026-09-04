#!/bin/bash
set -euo pipefail

MULTITOOL_IMG="${1:?missing multitool image}"
ROOTFS_TAR="${2:?missing rootfs.tar}"
KERNEL="${3:?missing kernel zImage}"
OUTPUT="${4:?missing output image}"

IMAGE_MB=256

ROOT_START=32768
ROOT_SIZE=137408

BOOT_START=170176
BOOT_SIZE=131072

echo "=== Criando imagem ${IMAGE_MB} MiB ==="

rm -f "$OUTPUT"

dd if=/dev/zero of="$OUTPUT" bs=1M count="$IMAGE_MB" status=progress

echo "=== Copiando bootloader funcional do Multitool ==="

dd if="$MULTITOOL_IMG" \
   of="$OUTPUT" \
   bs=512 \
   count=32768 \
   conv=notrunc \
   status=none

echo "=== Criando tabela de partições ==="

sfdisk "$OUTPUT" <<EOF
label: dos
unit: sectors

start=${ROOT_START}, size=${ROOT_SIZE}, type=83
start=${BOOT_START}, size=${BOOT_SIZE}, type=0c, bootable
EOF

LOOP=$(losetup --find --show --partscan "$OUTPUT")

cleanup() {
    set +e
    umount /mnt/rk-root 2>/dev/null
    umount /mnt/rk-boot 2>/dev/null
    losetup -d "$LOOP" 2>/dev/null
}
trap cleanup EXIT

sleep 2

echo "=== Formatando partições ==="

mkfs.ext4 -F -L ROOTFS "${LOOP}p1"
mkfs.vfat -F 16 -n BOOT "${LOOP}p2"

mkdir -p /mnt/rk-root /mnt/rk-boot

mount "${LOOP}p1" /mnt/rk-root
mount "${LOOP}p2" /mnt/rk-boot

echo "=== Instalando rootfs Buildroot ==="

tar -xf "$ROOTFS_TAR" -C /mnt/rk-root

echo "=== Extraindo boot do Multitool ==="

MT_LOOP=$(losetup --find --show --partscan "$MULTITOOL_IMG")
sleep 2

mkdir -p /mnt/mt-boot
mount "${MT_LOOP}p2" /mnt/mt-boot

cp "$KERNEL" /mnt/rk-boot/zImage
cp /mnt/mt-boot/rk322x-box.dtb /mnt/rk-boot/

mkdir -p /mnt/rk-boot/extlinux

ROOT_PARTUUID=$(blkid -s PARTUUID -o value "${LOOP}p1")

cat > /mnt/rk-boot/extlinux/extlinux.conf <<EOF
LABEL RK322x Server
  LINUX /zImage
  FDT /rk322x-box.dtb
  APPEND root=PARTUUID=${ROOT_PARTUUID} rootwait console=ttyS2,115200 consoleblank=0
EOF

echo "=== Finalizando ==="

sync

umount /mnt/mt-boot
losetup -d "$MT_LOOP"

umount /mnt/rk-boot
umount /mnt/rk-root

sync

echo
echo "Imagem criada:"
ls -lh "$OUTPUT"
