#!/sbin/busybox sh
set +x
_PATH="$PATH"
export PATH=/sbin

busybox cd /
busybox date >>boot.txt
exec >>boot.txt 2>&1
busybox rm /init

# include device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /cache
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# create device nodes
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 ${BOOTREC_CACHE_NODE}
busybox mknod -m 600 ${BOOTREC_EVENT_NODE}
busybox mknod -m 666 /dev/null c 1 3

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t yaffs2 ${BOOTREC_CACHE} /cache

# fixing CPU clocks to avoid issues in recovery
busybox echo 1024000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
busybox echo 122000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq


# trigger blue LED
busybox echo 0 > ${BOOTREC_LED_RED}
busybox echo 0 > ${BOOTREC_LED_GREEN}
busybox echo 255 > ${BOOTREC_LED_BLUE}

# keycheck
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 2

# LED off
busybox echo 0 > ${BOOTREC_LED_RED}
busybox echo 0 > ${BOOTREC_LED_GREEN}
busybox echo 0 > ${BOOTREC_LED_BLUE}

# android ramdisk (jb is default)
load_image=/sbin/ramdisk-jb.cpio

# bind-mount turbo data then unmount sdcard
busybox mkdir /sdcard
busybox mount /dev/block/mmcblk0p1 /sdcard
busybox mkdir /turbo
busybox mount -o bind /turbo /turbo
busybox umount -l /dev/block/mmcblk0p1
busybox rm -rf /sdcard

# boot decision
if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox echo 'BOOTMENU' >>boot.txt
	busybox rm /cache/recovery/boot
    # start aroma bootmenu
    busybox mkdir /sdcard
    busybox mkdir /tmp
    busybox mount /dev/block/mmcblk0p1 /sdcard
    /sbin/adbd&/sbin/aroma 1 0 "/sbin/aroma-res.zip"
    # copy repair log to sdcard if requested
    if [ -e /tmp/turbo_repair.ready2copy ]
    then
        busybox rm /tmp/turbo_repair.ready2copy
        busybox mv /tmp/turbo_repair.log /sdcard/turbo_repair.log
    fi
    busybox sync
    busybox umount -l /dev/block/mmcblk0p1
    busybox rm -rf /sdcard
    #if [ ! -e /tmp/bootrec ]
    #then
    #    reboot
    #fi
fi

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

if [ -e /tmp/bootrec ]
then
    # twrp-recovery ramdisk
    busybox rm /tmp/bootrec
    busybox rm /tmp/bootrec-cwm
    busybox rm -rf /tmp
	load_image=/sbin/recovery-twrp.cpio
    busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
elif [ -e /tmp/bootrec-cwm ]
then
    # cwm-recovery ramdisk
    busybox rm /tmp/bootrec-cwm
    busybox rm -rf /tmp
	load_image=/sbin/recovery-cwm.cpio
    busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
else
    # Prepare for normal boot
    busybox rm -rf /tmp
	busybox echo 'ANDROID BOOT' >>boot.txt
    # Slot select
    if   [ -e /cache/multiboot1 ]
    then
        # Slot 1 (one time only)
        #rm /cache/multiboot1
        mode=$(busybox grep -F "mode=" /turbo/slot1.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Internal/Slot 1 (One-time only); Mode is ${mode}' >>boot.txt
    elif [ -e /cache/multiboot2 ]
    then
        # Slot 2 (one time only)
        #rm /cache/multiboot2
        mode=$(busybox grep -F "mode=" /turbo/slot2.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 2 (One-time only); Mode is ${mode}' >>boot.txt
    elif [ -e /cache/multiboot3 ]
    then
        # Slot 3 (one time only)
        #rm /cache/multiboot3
        mode=$(busybox grep -F "mode=" /turbo/slot3.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 3 (One-time only); Mode is ${mode}' >>boot.txt
    elif [ -e /cache/multiboot4 ]
        # Slot 4 (one time only)
        #rm /cache/multiboot4
        mode=$(busybox grep -F "mode=" /turbo/slot4.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 4 (One-time only); Mode is ${mode}' >>boot.txt
    elif [ -e /turbo/defaultboot_2 ]
    then
        # Slot 2 (default)
        mode=$(busybox grep -F "mode=" /turbo/slot2.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 2 (Default); Mode is ${mode}' >>boot.txt
    elif [ -e /turbo/defaultboot_3 ]
    then
        # Slot 3 (default)
        mode=$(busybox grep -F "mode=" /turbo/slot3.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 3 (Default); Mode is ${mode}' >>boot.txt
    elif [ -e /turbo/defaultboot_4 ]
    then
        # Slot 4 (default)
        mode=$(busybox grep -F "mode=" /turbo/slot4.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 4 (Default); Mode is ${mode}' >>boot.txt
    else
        # Internal/Slot 1 (default)
        mode=$(busybox grep -F "mode=" /turbo/slot1.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Internal/Slot 1 (Default); Mode is ${mode}' >>boot.txt
    fi
    if   [ ${mode}=="JB-AOSP" ]
    then
        busybox echo 1 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-jb.cpio
    elif [ ${mode}=="ICS-AOSP" ]
    then
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-ics.cpio
    elif [ ${mode}=="ICS-Stock" ]
    then
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-ics-stock.cpio
    else
        # TODO: Handle mode error (Aroma prompt?)
        busybox echo '[TURBO] Error - mode "${mode}" is not valid' >>boot.txt
    fi
fi

# unpack the ramdisk image
busybox cpio -i < ${load_image}

busybox umount -l /cache
busybox umount -l /proc
busybox umount -l /sys

busybox rm -fr /dev/*
busybox date >>boot.txt
export PATH="${_PATH}"
exec /init
