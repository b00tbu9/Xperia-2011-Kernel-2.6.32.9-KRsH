#!/sbin/sh
# App2SD Fix (thanks to LSS4181)

if [ $(/sbin/ics-or-jb) == "jb" ]
then
    mount -o remount,rw /
    rm -r /mnt/secure/asec
    mkdir /mnt/secure/asec
    mount -o bind /storage/sdcard0/.android_secure /mnt/secure/asec
    mv /mnt/secure/.android_secure /mnt/secure/asec
    mount -o remount,ro /
fi
