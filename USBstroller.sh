#!/usr/bin/bash

# INSTALL THIS ON YOUR COMPUTER
# RUN THIS AFTER BOOT

$checkpt=~/chckpt;
$mountpt=~/mount_inst;

# CREATE INIT CHECKPOINT FILE IF DOESN'T EXIST
if [ ! -f $checkpt ]; then
  echo "" > $checkpt;
fi

dflt_devs=($(lsblk -d -r -o path | awk 'NR>=2'));

# MAIN LOOP
while true; do
  tget_devs=($(lsblk -d -r -o path | awk 'NR>=2'));
  # LOOP ALL UNMOUNTED USB DRIVES
  for tget_dev in "${tget_devs[@]}"; do
    # IF DEVICE HASN'T BEEN HERE BEFORE
    if ! [[ " ${dflt_devs[*]} " == *" $tget_dev "* ]]; then
      # MOUNT UNMOUNTED USB DRIVE
      mkdir $mountpt;
      mount $tget_dev $mountpt;
      
      # SCAN FOR INSTRUCTION FILES (*.poppy)
      for f_instrtn in "$mountpt/*.poppy"; do
        [ -f $f_instrtn ] || break
        
        # GENERATE UNIQUE SIGNATURE
        hash_sig=$(sha256sum $f_instrtn | cut -c -64);
        
        # IF INSTRUCTION IS UNIQUE
        if ! grep -Fxq $hash_sig $checkpt; then
          # EXECUTE ALL INSTRUCTIONS
          while IFS= read -r cmd_ln do
            eval $cmd_ln;
          done < $tget_fl
          
          # SAVE INSTRUCTION SIGNATURE
          $hash_sig >> $checkpt;
        fi
      done
      
      # UNMOUNT MOUNTED USB DRIVE
      umount $mountpt;
      rm -rf $mountpt;
    fi
  done
  sleep 1;
done

