#!/bin/bash
device=$DEVNAME

function err_exit {
  logger -p local3.error -t "NiceScale" "$1"
  exit ${2:-1}
}

if [ "$ACTION" = "add" ]; then
  if [ ! -e $device ]; then
    err_exit "Device $device not exists"
  fi
fi

echo -e `date  -I'seconds'`"\t${ACTION}\t${device}\t${ID_FS_UUID}\t${ID_FS_TYPE}" >> /var/log/volume-change.log

if [ "$ACTION" = "remove" -a "x$ID_FS_UUID" != "x" ]; then
  sed -i "/$ID_FS_UUID/d" /etc/fstab
fi
