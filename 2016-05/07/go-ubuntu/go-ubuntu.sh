SDCARD=/data
ROOT=$SDCARD/ubuntu
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
HOME=/root
USER=samg

maybe_mount() {
    test -d $1 && \
        grep -q " $1 " /proc/mounts && \
            grep -q " $2 " /proc/mounts || \
                mount -o bind $1 $2
}

mount -o remount,exec,dev,suid $SDCARD
for f in dev dev/pts proc sys ; do maybe_mount /$f $ROOT/$f ; done
mkdir -p $ROOT/mnt/data
maybe_mount /data $ROOT/mnt/data
mkdir -p $ROOT/mnt/sdcard
maybe_mount /sdcard $ROOT/mnt/sdcard

grep -q " $ROOT/media " /proc/mounts || busybox mount --rbind /storage $ROOT/media

chroot $ROOT login -p -f $USER

