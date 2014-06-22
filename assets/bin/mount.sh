#!/bin/bash
# NiceScale helper script for mounting EBS volumes.
# If successfully mounted, the stdout is the mountpoint.

set -e

device="$1"
label="$2"
fstype="$3"

mountpoint=/volume

mkfs_cmd="/sbin/mkfs.$fstype"

function err_exit {
  logger -p local3.error -t "NiceScale" "$1"
  echo "$1" >&2
  exit ${2:-1}
}

function get_uuid_by_label {
  local label="$1"
  for f in `blkid|grep LABEL='"'$label'"'`; do
    if echo $f|grep -q UUID=; then
      echo $f
      break
    fi
  done
}

function mount_volume {
  local label="$1"
  local dir="$2"
  local uuid
  e2label $device "$label"
  uuid=`get_uuid_by_label "$label"`
  grep -q "$uuid" /etc/fstab || echo "$uuid $dir $fstype defaults,barrier=1 0 0" >>/etc/fstab
  df|grep -Pq "$device\s+" || mount $dir
}

[ -x "$mkfs_cmd" ] || err_exit "Unknown fstype"
[ -e "$device" ] || err_exit "Device <$device> not exists"
[ -n "$label" ] || err_exit "Must specify a valid label"

mkfs_cmd="$mkfs_cmd -F "

declare -i file_count
for ((i=0; i<128; i++)); do
  dir=$mountpoint${i}
  if [ -d $dir ]; then
    # Skip if the directory is in fstab.
    if grep -q $dir /etc/fstab; then
      continue
    fi
    # Skip if the directory is already used as a mountpoint.
    if df|grep -Pq "$dir$"; then
      continue
    fi

    # Skip if the directory is not empty.
    file_count=$(find $dir -maxdepth 1|wc -l)
    if [ $file_count -gt 1 ]; then
      continue
    fi
  fi
  [ -d $dir ] || mkdir $dir
  if test "$NS_DEBUG" = "Y"; then
    # Detect if the block device has valid file system.
    if ! blkid|grep -Pq "^$device"; then
      echo "$mkfs_cmd $device"
    fi
    echo "e2label $device $dir"
    echo "LABEL=$dir $dir $fstype defaults,barrier=1 0 0"
    echo "mount $dir"
  else
    # Detect if the block device has valid file system.
    if ! blkid|grep -Pq "^$device"; then
      $mkfs_cmd $device >/dev/null
    fi
    
    # If the label exists, the label and the device must match.
    if blkid|grep -q LABEL='"'"$label"'"'; then
      if blkid|grep -P "^$device:"|grep -q LABEL='"'$label'"'; then
        mount_volume "$label" "$dir"
        exit $?
      else
        err_exit "The label is already taken, but the device is not $device"
      fi
    fi
    mount_volume "$label", "$dir"
  fi
  echo $dir
  break
done
