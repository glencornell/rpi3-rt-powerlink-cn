#!/bin/bash

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

case "${2}" in
	--add-pi3-miniuart-bt-overlay)
	if ! grep -qE '^dtoverlay=' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
		echo "Adding 'dtoverlay=pi3-miniuart-bt' to config.txt (fixes ttyAMA0 serial console)."
		cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# fixes rpi3 ttyAMA0 serial console
dtoverlay=pi3-miniuart-bt
__EOF__
	fi
	;;
esac

# Because we're linking the root file system with the kernel, remove
# the "root=" Linux command line parameter:
sed -i -e 's/root=[^ 	]+//g' ${BINARIES_DIR}/rpi-firmware/cmdline.txt

rm -rf "${GENIMAGE_TMP}"

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

status=$?
if [ $status -ne 0 ]
then
    echo "Error: genimage" >&2
    exit $status
fi

# create the swupdate image:
CONTAINER_VER="1.0"
PRODUCT_NAME="rpi-rt"
FILES="sw-description sdcard.img"
rm -f ${BINARIES_DIR}/sw-description
rm -f ${BINARIES_DIR}/${PRODUCT_NAME}_${CONTAINER_VER}.swu
cp ${BOARD_DIR}/sw-description ${BINARIES_DIR}
pushd ${BINARIES_DIR}
for i in $FILES;do
	echo $i;done | cpio -ov -H crc >  ${PRODUCT_NAME}_${CONTAINER_VER}.swu
popd

exit $?
