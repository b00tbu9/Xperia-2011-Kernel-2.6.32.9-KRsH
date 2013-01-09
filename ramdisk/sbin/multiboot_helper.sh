#!/sbin/busybox sh

#set -x
#exec >>multiboot.log 2>&1

checkfresh()
{
    if [ ! -e /turbo/version ]; then
        # delete old settings
        busybox rm -rf /turbo/*
        busybox uname -r > /turbo/version;
        busybox echo "icon=@slot1" > /turbo/slot1.prop
        busybox echo "text=Slot 1" >> /turbo/slot1.prop
        busybox echo "mode=JB-AOSP" > /turbo/slot1mode.prop
        busybox echo "icon=@slot2" > /turbo/slot2.prop
        busybox echo "text=Slot 2" >> /turbo/slot2.prop
        busybox echo "mode=JB-AOSP" > /turbo/slot2mode.prop
        busybox echo "icon=@slot3" > /turbo/slot3.prop
        busybox echo "text=Slot 3" >> /turbo/slot3.prop
        busybox echo "mode=JB-AOSP" > /turbo/slot3mode.prop
        busybox echo "icon=@slot4" > /turbo/slot4.prop
        busybox echo "text=Slot 4" >> /turbo/slot4.prop
        busybox echo "mode=JB-AOSP" > /turbo/slot4mode.prop
        busybox echo "1";
    else
        busybox echo "0";
    fi     
}

clearslot()
{
    busybox echo "icon=@slot$2" > /turbo/slot$2.prop
    busybox echo "text=Slot $2" >> /turbo/slot$2.prop
    busybox echo "custom=true" >> /turbo/slot$2.prop
    busybox echo "mode=JB-AOSP" >> /turbo/slot$2.prop
}

checkslot()
{
    if [ ! -e /turbo/system$2.ext2.img ] && [ ! -e /turbo/userdata$2.ext2.img ]; then 
        busybox echo "1";
    else
        busybox echo "0";
    fi
}

checkdefault()
{
    if   [ -e /cache/defaultboot_2 ]; then
        busybox rm /cache/defaultboot_1
        busybox rm /cache/defaultboot_3
        busybox rm /cache/defaultboot_4
        busybox echo "2";
    elif [ -e /cache/defaultboot_3 ]; then
        busybox rm /cache/defaultboot_1
        busybox rm /cache/defaultboot_4
        busybox echo "3";
    elif [ -e /cache/defaultboot_4 ]; then
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
        busybox rm /turbo/system$2.ext2.img
        busybox dd if=/dev/zero of=/turbo/system$2.ext2.img bs=1K count=$IMGSIZE
        busybox mke2fs -b 1024 -I 128 -m 0 -F -E resize=$(( IMGSIZE * 2 )) /turbo/system$2.ext2.img
        busybox tune2fs -C 1 -m 0 -f /turbo/system$2.ext2.img
    elif [ "$3" == "userdata" ]; then
        if [ "$4" == "1" ]; then
            IMGSIZE=`cat /proc/partitions | grep mtdblock1 | awk '{print $3}'`
        else
            IMGSIZE=$4
        fi
        busybox rm /turbo/userdata$2.ext2.img
        busybox dd if=/dev/zero of=/turbo/userdata$2.ext2.img bs=1K count=$IMGSIZE
        busybox mke2fs -b 1024 -I 128 -m 0 -F -E resize=$(( IMGSIZE * 2 )) /turbo/userdata$2.ext2.img
        busybox tune2fs -C 1 -m 0 -f /turbo/userdata$2.ext2.img
    fi
}

copyimage()
{
    if   [ "$3" == "system" ]; then
        busybox mkdir /dest
        busybox mount -t yaffs2 -o ro /dev/block/mtdblock0 /system
        busybox mount -t ext2 -o rw,loop /turbo/system$2.ext2.img /dest
        #tar -c -f - -p /system/* |(cd /dest; tar -x -f - -p)
        busybox cp -a /system/* /dest
        busybox umount /system
        busybox umount /dest
        busybox rm -f -R /dest
    elif [ "$3" == "userdata" ]; then
        busybox mkdir /dest
        busybox mount -t yaffs2 -o ro /dev/block/mtdblock1 /data
        busybox mount -t ext2 -o rw,loop /turbo/userdata$2.ext2.img /dest
        #tar -c -f - -p /system/* |(cd /dest; tar -x -f - -p)
        busybox cp -a /data/* /dest
        busybox umount /data
        busybox umount /dest
        busybox rm -f -R /dest
    fi
}

mounter()
{
    echo "About to mount Slot $1..."
    if  [ "$1" == "1" ]; then
        mount -t yaffs2 -o ro,remount                       /dev/block/mtdblock0        /system
        mount -t yaffs2 -o rw,remount,noatime,nosuid,nodev  /dev/block/mtdblock1        /data
        mount
    else
        mount -t ext2   -o rw                        /turbo/system$1.ext2.img    /system
        mount -t ext2   -o ro,remount                /turbo/system$1.ext2.img    /system
        mount -t ext2   -o rw,noatime,nosuid,nodev   /turbo/userdata$1.ext2.img  /data
    fi
}

mountproc()
{
    echo "Mountproc started..."
    if   [ -e /cache/multiboot1 ]; then
        rm /cache/multiboot1
        mounter 1
    elif [ -e /cache/multiboot2 ]; then
        rm /cache/multiboot2
        mounter 2
    elif [ -e /cache/multiboot3 ]; then
        rm /cache/multiboot3
        mounter 3
    elif [ -e /cache/multiboot4 ]; then
        rm /cache/multiboot4
        mounter 4
    elif [ -e /turbo/defaultboot_2 ]; then
        mounter 2
    elif [ -e /turbo/defaultboot_3 ]; then
        mounter 3
    elif [ -e /turbo/defaultboot_4 ]; then
        mounter 4
    else
        mounter 1
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

checkrecovery()
{
    if [ -e /turbo/cwm ]; then 
        busybox echo "cwm";
    else
        busybox echo "twrp";
    fi
}

$1 $1 $2 $3 $4
