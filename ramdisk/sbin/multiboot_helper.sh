#!/sbin/busybox sh

checkfresh()
{
    if [ ! -e /sdcard/turbo/version ]; then
        # delete old settings
        busybox rm -rf /sdcard/turbo
        busybox mkdir /sdcard/turbo
        busybox uname -r > /sdcard/turbo/version;
        busybox echo "icon=@slot1" > /sdcard/turbo/slot1.prop
        busybox echo "text=Slot 1" >> /sdcard/turbo/slot1.prop
        busybox echo "custom=true" >> /sdcard/turbo/slot1.prop
        busybox echo "mode=JB-AOSP" >> /sdcard/turbo/slot1.prop
        busybox echo "icon=@slot2" > /sdcard/turbo/slot2.prop
        busybox echo "text=Slot 2" >> /sdcard/turbo/slot2.prop
        busybox echo "custom=true" >> /sdcard/turbo/slot2.prop
        busybox echo "mode=JB-AOSP" >> /sdcard/turbo/slot2.prop
        busybox echo "icon=@slot3" > /sdcard/turbo/slot3.prop
        busybox echo "text=Slot 3" >> /sdcard/turbo/slot3.prop
        busybox echo "custom=true" >> /sdcard/turbo/slot3.prop
        busybox echo "mode=JB-AOSP" >> /sdcard/turbo/slot3.prop
        busybox echo "icon=@slot4" > /sdcard/turbo/slot4.prop
        busybox echo "text=Slot 4" >> /sdcard/turbo/slot4.prop
        busybox echo "custom=true" >> /sdcard/turbo/slot4.prop
        busybox echo "mode=JB-AOSP" >> /sdcard/turbo/slot4.prop
        busybox echo "1";
    else
        busybox echo "0";
    fi     
}

clearslot()
{
    busybox echo "icon=@slot$2" > /sdcard/turbo/slot$2.prop
    busybox echo "text=Slot $2" >> /sdcard/turbo/slot$2.prop
    busybox echo "custom=true" >> /sdcard/turbo/slot$2.prop
    busybox echo "mode=JB-AOSP" >> /sdcard/turbo/slot$2.prop
}

checkslot()
{
    if [ ! -e /sdcard/system$2.ext2.img ] && [ ! -e /sdcard/userdata$2.ext2.img ]; then 
        busybox echo "1";
    else
        busybox echo "0";
    fi
}

checkdefault()
{
    if   [ -e /cache/defaultboot_2 ]
        busybox rm /cache/defaultboot_1
        busybox rm /cache/defaultboot_3
        busybox rm /cache/defaultboot_4
        busybox echo "2";
    elif [ -e /cache/defaultboot_3 ]
        busybox rm /cache/defaultboot_1
        busybox rm /cache/defaultboot_4
        busybox echo "3";
    elif [ -e /cache/defaultboot_4 ]
        busybox rm /cache/defaultboot_1
        busybox echo "4";
    else
        busybox echo "1";
    fi
}



makeimage()
{
    if   [ "$3" == "system" ]; then
        if [ "$4" == "1" ]; then
            IMGSIZE=`cat /proc/partitions | grep mtdblock0 | awk '{print $3}'`
        else
            IMGSIZE=$4
        fi
        busybox rm /sdcard/system$2.ext2.img
        busybox dd if=/dev/zero of=/sdcard/system$2.ext2.img bs=1K count=$IMGSIZE
        busybox mke2fs -b 1024 -I 128 -m 0 -F -E resize=$(( IMGSIZE * 2 )) /sdcard/system$2.ext2.img
        busybox tune2fs -C 1 -m 0 -f /sdcard/system$2.ext2.img
    elif [ "$3" == "userdata" ]; then
        if [ "$4" == "1" ]; then
            IMGSIZE=`cat /proc/partitions | grep mtdblock1 | awk '{print $3}'`
        else
            IMGSIZE=$4
        fi
        busybox rm /sdcard/userdata$2.ext2.img
        busybox dd if=/dev/zero of=/sdcard/userdata$2.ext2.img bs=1K count=$IMGSIZE
        busybox mke2fs -b 1024 -I 128 -m 0 -F -E resize=$(( IMGSIZE * 2 )) /sdcard/userdata$2.ext2.img
        busybox tune2fs -C 1 -m 0 -f /sdcard/userdata$2.ext2.img
    fi
}

copyimage()
{
    if   [ "$3" == "system" ]; then
        busybox mkdir /dest
        busybox mount -t yaffs2 -o ro /dev/block/mtdblock0 /system
        busybox mount -t ext2 -o rw,loop /sdcard/system$2.ext2.img /dest
        #tar -c -f - -p /system/* |(cd /dest; tar -x -f - -p)
        busybox cp -a /system/* /dest
        busybox umount /system
        busybox umount /dest
        busybox rm -f -R /dest
    elif [ "$3" == "userdata" ]; then
        busybox mkdir /dest
        busybox mount -t yaffs2 -o ro /dev/block/mtdblock1 /data
        busybox mount -t ext2 -o rw,loop /sdcard/userdata$2.ext2.img /dest
        #tar -c -f - -p /system/* |(cd /dest; tar -x -f - -p)
        busybox cp -a /data/* /dest
        busybox umount /data
        busybox umount /dest
        busybox rm -f -R /dest
    fi
}

boot2()
{
    umount /system
    umount /data
    mount -t ext2   -o rw,loop                       /sdcard/system2.ext2.img    /system
    /sbin/mountsd.sh
    mount -t ext2   -o ro,loop                       /sdcard/system2.ext2.img    /system
    mount -t ext2   -o rw,loop,noatime,nosuid,nodev  /sdcard/userdata2.ext2.img  /data
}

boot3()
{
    umount /system
    umount /data
    mount -t ext2   -o rw,loop                       /sdcard/system3.ext2.img    /system
    /sbin/mountsd.sh
    mount -t ext2   -o ro,loop                       /sdcard/system3.ext2.img    /system
    mount -t ext2   -o rw,loop,noatime,nosuid,nodev  /sdcard/userdata3.ext2.img  /data
}

mountproc()
{
    mount -o fmask=0000,dmask=0000,rw,flush,noatime,nodiratime /dev/block/mmcblk0p1 /sdcard
    #mount -t vfat -o fmask=0000,dmask=0000,rw,flush,noatime,nodiratime /dev/block/mmcblk0p1 /sdcard
    if   [ -e /cache/multiboot1 ]
    then
        rm /cache/multiboot1
        /sbin/mountsd.sh
        mount -t yaffs2 -o ro /dev/block/mtdblock0 /system
    elif [ -e /cache/multiboot2 ]
    then
        rm /cache/multiboot2
        boot2
        multifix
    elif [ -e /cache/multiboot3 ]
    then
        rm /cache/multiboot3
        boot3
        multifix
    elif [ -e /sdcard/turbo/defaultboot_2 ]
    then
        boot2
        multifix
    elif [ -e /sdcard/turbo/defaultboot_3 ]
    then
        boot3
        multifix
    else
        /sbin/mountsd.sh
        mount -t yaffs2 -o ro /dev/block/mtdblock0 /system
    fi
    
    sync
    
    mkdir /data/dalvik-cache
        chown system:system /data/dalvik-cache
        chmod 0771 /data/dalvik-cache
    mkdir /cache/dalvik-cache
        chown system:system /cache/dalvik-cache
        chmod 0771 /cache/dalvik-cache
    mount -o bind /data/dalvik-cache /cache/dalvik-cache
    
    sync
}

multifix()
{
    # Helper function to replicate on post-fs-data init commands,
    # because the mmc driver is loaded later
    
    # We chown/chmod /data again so because mount is run as root + defaults
    chown system:system /data
    chmod 0771 /data

    # Create dump dir and collect dumps.
    # Do this before we mount cache so eventually we can use cache for
    # storing dumps on platforms which do not have a dedicated dump partition.
    mkdir -p -m 0750 /data/dontpanic
    chown root:log /data/dontpanic

    # Collect apanic data, free resources and re-arm trigger
    cp -f /proc/apanic_console /data/dontpanic/apanic_console
    chown root:log /data/dontpanic/apanic_console
    chmod 0640 /data/dontpanic/apanic_console

    cp -f /proc/apanic_threads /data/dontpanic/apanic_threads
    chown root:log /data/dontpanic/apanic_threads
    chmod 0640 /data/dontpanic/apanic_threads

    #write /proc/apanic_console 1
    echo "1" > /proc/apanic_console

    # create basic filesystem structure
    #mkdir /data/misc 01771 system misc
    mkdir -p -m 0771 /data/misc
    chown system:misc /data/misc
    mkdir -p -m 0770 /data/misc/bluetoothd
    chown bluetooth:bluetooth /data/misc/bluetoothd
    mkdir -p -m 0770 /data/misc/bluetooth
    chown system:system /data/misc/bluetooth
    mkdir -p -m 0700 /data/misc/keystore
    chown keystore:keystore /data/misc/keystore
    mkdir -p -m 0771 /data/misc/keychain
    chown system:system /data/misc/keychain
    mkdir -p -m 0770 /data/misc/vpn
    chown system:vpn /data/misc/vpn
    mkdir -p -m 0770 /data/misc/systemkeys
    chown system:system /data/misc/systemkeys
    
    mkdir -p -m 0770 /data/misc/wifi 
    mkdir -p -m 0770 /data/misc/wifi/sockets
    chmod 0660 /data/misc/wifi/wpa_supplicant.conf
    # give system access to wpa_supplicant.conf for backup and restore
    ln -s /data/misc/wifi/wlan0 /data/system/wpa_supplicant
    chown -R wifi:wifi /data/misc/wifi 
    
    mkdir -p -m 0770 /data/misc/dhcp
    chown -R dhcp:dhcp /data/misc/dhcp
    
    mkdir -p -m 0751 /data/local
    chown root:root /data/local

    # For security reasons, /data/local/tmp should always be empty.
    # Do not place files or directories in /data/local/tmp
    mkdir -p -m 0771 /data/local/tmp
    chown shell:shell /data/local/tmp
    
    mkdir -p -m 0771 /data/data
    chown system:system /data/data
    mkdir -p -m 0771 /data/app-private
    chown system:system /data/app-private
    mkdir -p -m 0700 /data/app-asec
    chown root:root /data/app-asec
    mkdir -p -m 0771 /data/app
    chown system:system /data/app
    mkdir -p -m 0700 /data/property
    chown root:root /data/property
    mkdir -p -m 0750 /data/ssh
    chown root:shell /data/ssh
    mkdir -p -m 0700 /data/ssh/empty
    chown root:root /data/ssh/empty
    mkdir -p -m 0770 /data/radio
    chown radio:radio /data/radio
    
    # create dalvik-cache and double-check the perms, so as to enforce our permissions
    mkdir -p -m 0771 /data/dalvik-cache
	chown system:system /data/dalvik-cache
	chmod -R 0771 /data/dalvik-cache
	chown system:system /cache/dalvik-cache
	chmod -R 0771 /cache/dalvik-cache

    # create resource-cache and double-check the perms
    mkdir -p -m 0771 /data/resource-cache
    chown system:system /data/resource-cache
    chmod -R 0771 /data/resource-cache

    # create the lost+found directories, so as to enforce our permissions
    mkdir -p -m 0770 /data/lost+found
    chown root:root /data/lost+found

    # create directory for DRM plug-ins - give drm the read/write access to
    # the following directory.
    mkdir -p -m 0770 /data/drm
    chown drm:drm /data/drm
    
    setprop vold.post_fs_data_done 1
    
}

$1 $1 $2 $3 $4
