#!/sbin/sh

if [ $(/sbin/ics-or-jb) == "ics" ]
then
    mount -o remount,rw /
    umount -l /dev/block/mmcblk0p1
    umount -l /system
    rm -rf /sdcard
    rm -rf /mnt/sdcard
    rm -rf /storage/sdcard0
    rm -rf /storage
    mkdir /mnt/sdcard
        chmod 0000 /mnt/sdcard
        chown system:system /mnt/sdcard
    # for backwards compatibility
    ln -s /mnt/sdcard /sdcard
        chown system:system /sdcard
    mount -o fmask=0000,dmask=0000,rw,flush,noatime,nodiratime /dev/block/mmcblk0p1 /sdcard
    mount -o remount,ro /
fi

if [ $(/sbin/ics-or-jb) == "jb" ]
then
    mount -o remount,rw /
    umount -l /dev/block/mmcblk0p1
    umount -l /system
    rm -rf /sdcard
    rm -rf /mnt/sdcard
    rm -rf /storage/sdcard0
    rm -rf /storage
    mkdir /storage
        chmod 0050 /storage
        chown system:sdcard_r /storage
    mkdir /storage/sdcard0
        chmod 0000 /storage/sdcard0
        chown system:system /storage
    # for backwards compatibility
    ln -s /storage/sdcard0 /sdcard
        chown system:system /sdcard
    ln -s /storage/sdcard0 /mnt/sdcard
        chown system:system /mnt/sdcard
    mount -o fmask=0000,dmask=0000,rw,flush,noatime,nodiratime /dev/block/mmcblk0p1 /storage/sdcard0
    mount -o remount,ro /
fi