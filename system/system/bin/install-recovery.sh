#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/platform/bootdevice/by-name/recovery:39285648:7ad46eb451e453281b1ffb05432fb163ae68611e; then
  applypatch  EMMC:/dev/block/platform/bootdevice/by-name/boot:39285648:5c2d870c435123e0bd851966f7755ab9c30912b3 EMMC:/dev/block/platform/bootdevice/by-name/recovery 7ad46eb451e453281b1ffb05432fb163ae68611e 39285648 5c2d870c435123e0bd851966f7755ab9c30912b3:/system/recovery-from-boot.p && log -t recovery "Installing new recovery image: succeeded" || log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
