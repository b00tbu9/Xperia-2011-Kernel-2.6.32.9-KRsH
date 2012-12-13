#!/sbin/sh

checkslot()
{
    if [ ! -e /sdcard/system$2.ext2.img -o ! -e /sdcard/userdata$2.ext2.img ]; then 
        echo "1";
    else
        echo "0";
    fi
}

makeimage()
{
    if   [ "$3" == "system" ]; then
        IMGSIZE=`cat /proc/partitions | grep mtdblock0 | awk '{print $3}'`
        dd if=/dev/zero of=/sdcard/system$2.ext2.img bs=1K count=$IMGSIZE > /cache/multiboot.log
        mke2fs -b 1024 -I 128 -m 0 -F -E resize=$(( IMGSIZE * 2 )) /sdcard/system$2.ext2.img > /cache/multiboot.log
        tune2fs -C 1 -m 0 -f /sdcard/system$2.ext2.img > /cache/multiboot.log
    elif [ "$3" == "userdata" ]; then
        IMGSIZE=`cat /proc/partitions | grep mtdblock1 | awk '{print $3}'`
        dd if=/dev/zero of=/sdcard/userdata$2.ext2.img bs=1K count=$IMGSIZE > /cache/multiboot.log
        mke2fs -b 1024 -I 128 -m 0 -F -E resize=$(( IMGSIZE * 2 )) /sdcard/userdata$2.ext2.img > /cache/multiboot.log
        tune2fs -C 1 -m 0 -f /sdcard/userdata$2.ext2.img > /cache/multiboot.log
    fi
}

copyimage()
{
    if   [ "$3" == "system" ]; then
        mkdir /dest > /cache/multiboot.log
        mount -t yaffs2 -o ro /dev/block/mtdblock0 /system > /cache/multiboot.log
        mount -t ext2 -o rw,loop /sdcard/system$2.ext2.img /dest > /cache/multiboot.log
        #tar -c -f - -p /system/* |(cd /dest; tar -x -f - -p)
        cp -a /system/* /dest > /cache/multiboot.log
        umount /system > /cache/multiboot.log
        umount /dest > /cache/multiboot.log
        rm -f -R /dest > /cache/multiboot.log
    elif [ "$3" == "userdata" ]; then
        mkdir /dest > /cache/multiboot.log
        mount -t yaffs2 -o ro /dev/block/mtdblock1 /data > /cache/multiboot.log
        mount -t ext2 -o rw,loop /sdcard/userdata$2.ext2.img /dest > /cache/multiboot.log
        #tar -c -f - -p /system/* |(cd /dest; tar -x -f - -p)
        cp -a /data/* /dest > /cache/multiboot.log
        umount /data > /cache/multiboot.log
        umount /dest > /cache/multiboot.log
        rm -f -R /dest > /cache/multiboot.log
    fi
}

boot1()
{
    mount -t yaffs2 -o rw                            /dev/block/mtdblock0        /system
    mount -t yaffs2 -o ro,remount                    /dev/block/mtdblock0        /system
    mount -t yaffs2 -o rw,noatime,nosuid,nodev       /dev/block/mtdblock1        /data
}

boot2()
{
    umount /system
    umount /data
    mount -t ext2   -o rw,loop                       /sdcard/system2.ext2.img    /system
    mount -t ext2   -o ro,loop,remount               /sdcard/system2.ext2.img    /system
    mount -t ext2   -o rw,loop,noatime,nosuid,nodev  /sdcard/userdata2.ext2.img  /data
}

boot3()
{
    umount /system
    umount /data
    mount -t ext2   -o rw,loop                       /sdcard/system3.ext2.img    /system
    mount -t ext2   -o ro,loop,remount               /sdcard/system3.ext2.img    /system
    mount -t ext2   -o rw,loop,noatime,nosuid,nodev  /sdcard/userdata3.ext2.img  /data
}

mountproc()
{
    mount /dev/block/mmcblk0p1 /sdcard
    if   [ -e /cache/multiboot1 ]
        then
            rm /cache/multiboot1
            boot1
        elif [ -e /cache/multiboot2 ]
        then
            rm /cache/multiboot2
            boot2
        elif [ -e /cache/multiboot3 ]
        then
            rm /cache/multiboot3
            boot3
        elif [ -e /cache/defaultboot_2 ]
        then
            boot2
        elif [ -e /cache/defaultboot_3 ]
        then
            boot3
        else
            boot1
    fi
}

$1 $1 $2 $3
