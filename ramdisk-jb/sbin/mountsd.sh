#!/sbin/sh


    mount -o remount,rw /
    umount -l /dev/block/mmcblk0p1
    umount -l /system
    rm -rf /sdcard
    rm -rf /mnt/sdcard
    # for backwards compatibility
    ln -s /storage/sdcard0 /sdcard
    ln -s /storage/sdcard0 /mnt/sdcard
    mount -o fmask=0000,dmask=0000,rw,flush,noatime,nodiratime /dev/block/mmcblk0p1 /storage/sdcard0
    mount -o remount,ro /

