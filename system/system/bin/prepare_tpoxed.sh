#!/system/bin/sh
#
#


DEX2OAT_CACHE_DIR="/data/.dex2oat_cache"


setprop persist.vivo.prepare_tpoxed running

rm -rf ${DEX2OAT_CACHE_DIR}
mkdir -p ${DEX2OAT_CACHE_DIR}

data_remain=$(df | grep /dev/block/ | grep /data | awk '{print $4}')
if [ $data_remain -ge 5242880 ]; then
  log -t prepare_tpoxed "going to prepare."

  # prepare user-0
  src_files=$(find /data/user/0/com.tencent.mm -type f -name "*.dex" -or -name "*.jar" -or -name "*.apk" -or -name "*.odex" -or -name "*.vdex" | grep -v /data/user/0/com.tencent.mm/tinker/ | grep -v /data/user/0/com.tencent.mm/app_tbs/)
  for src_file in ${src_files}
  do
    dst_file=${src_file#*/data/}
    mkdir -p $(dirname ${DEX2OAT_CACHE_DIR}/${dst_file})
    cp -a ${src_file} ${DEX2OAT_CACHE_DIR}/${dst_file}
  done
  src_dirs="/data/user/0/com.tencent.mm/tinker /data/user/0/com.tencent.mm/app_tbs"
  mkdir -p ${DEX2OAT_CACHE_DIR}/user/0/com.tencent.mm
  cp -a ${src_dirs} ${DEX2OAT_CACHE_DIR}/user/0/com.tencent.mm

  # prepare user-999
  src_files=$(find /data/user/999/com.tencent.mm -type f -name "*.dex" -or -name "*.jar" -or -name "*.apk" -or -name "*.odex" -or -name "*.vdex" | grep -v /data/user/999/com.tencent.mm/tinker/ | grep -v /data/user/999/com.tencent.mm/app_tbs/)
  for src_file in ${src_files}
  do
    dst_file=${src_file#*/data/}
    mkdir -p $(dirname ${DEX2OAT_CACHE_DIR}/${dst_file})
    cp -a ${src_file} ${DEX2OAT_CACHE_DIR}/${dst_file}
  done
  src_dirs="/data/user/999/com.tencent.mm/tinker /data/user/999/com.tencent.mm/app_tbs"
  mkdir -p ${DEX2OAT_CACHE_DIR}/user/999/com.tencent.mm
  cp -a ${src_dirs} ${DEX2OAT_CACHE_DIR}/user/999/com.tencent.mm

  setprop persist.vivo.prepare_tpoxed prepared

  extra_files=$(find ${DEX2OAT_CACHE_DIR} -type f ! -name "*.dex" -and ! -name "*.jar" -and ! -name "*.apk" -and ! -name "*.odex" -and ! -name "*.vdex" | tr '\n' ' ')
  rm -f ${extra_files} && log -t prepare_tpoxed "succeeded to remove extra files." || log -t prepare_tpoxed "failed to remove extra files."
else
  log -t prepare_tpoxed "skipped for not enough space on /data: current $data_remain."
  setprop persist.vivo.prepare_tpoxed skipped
fi
