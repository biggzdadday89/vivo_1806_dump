#!/system/bin/sh
#
#


if [ -f "/cache/flag_after_ota" ]; then
  log -t clear_tpoxed "this is the first boot since the upgrade."

  prepare_tpoxed=$(getprop persist.vivo.prepare_tpoxed)
  log -t clear_tpoxed "prepare_tpoxed is ${prepare_tpoxed}"

  # restore file status even if prepare_tpoxed.sh not prepared
  restorecon /data/.dex2oat_cache && log -t clear_tpoxed "succeeded to restore tpoxed dir SELinux status." || log -t clear_tpoxed "failed to restore tpoxed dir SELinux status."
  chmod 0777 /data/.dex2oat_cache && log -t clear_tpoxed "succeeded to restore tpoxed dir RWX status." || log -t clear_tpoxed "failed to restore tpoxed dir RWX status."
  restorecon /data/.dex2oat_cache/* && log -t clear_tpoxed "succeeded to restore tpoxed file SELinux status." || log -t clear_tpoxed "failed to restore tpoxed file SELinux status."
  chmod 0777 /data/.dex2oat_cache/* && log -t clear_tpoxed "succeeded to restore tpoxed file RWX status." || log -t clear_tpoxed "failed to restore tpoxed file RWX status."

  setprop persist.vivo.prepare_tpoxed last
else
  DEX2OAT_CACHE_DIR="/data/.dex2oat_cache"
  if [ -d "${DEX2OAT_CACHE_DIR}" ]; then
    rm -rf ${DEX2OAT_CACHE_DIR} && log -t clear_tpoxed "succeeded to clear tpoxed." || log -t clear_tpoxed "failed to clear tpoxed."
  else
    log -t clear_tpoxed "tpoxed does not exist."
  fi
fi
