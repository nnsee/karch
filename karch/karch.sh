#!/bin/sh
set -x
SCREENSIZE=$(eips -i | grep 'xres:' | awk '{print $2"x"$4}')

WORKDIR=$(pwd)

INITSCRIPT="#!/bin/sh
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
test -e /etc/ready || {
    pacman -S lxde xorg-server-xephyr --noconfirm;
    if [ $? -eq 0 ]; then
        touch /etc/ready;
    else
        touch /etc/failed;
        exit 1;
fi
}

export DISPLAY=:0
Xephyr :1 -title \"L:A_N:application_ID:xephyr\" -screen $SCREENSIZE -cc 4 -nocursor &
sleep 1
export DISPLAY=:1
lxsession &
sleep 3
xrandr -o right
wait \`pidof lxsession\`
killall Xephyr
"

print_bot()
{
    eips 2 2 "${1}" >/dev/null
}

check_host()
{
    test -e "$WORKDIR"/arch.img || {
        print_bot "arch.img not found!" 0;
        exit 1;
    }
}

mountall(){
    rm /dev/loop/karch;
    mknod -m0660 /dev/loop/karch b 7 250;
    mkdir "$WORKDIR"/system/;
    mount -o loop=/dev/loop/karch -t ext3 "$WORKDIR"/arch.img "$WORKDIR"/system/ ||
      mount /dev/loop/karch -t ext3 "$WORKDIR"/system/;
    mount -o bind /dev "$WORKDIR"/system/dev;
    mount -o bind /dev/pts "$WORKDIR"/system/dev/pts;
    mount -o bind /proc "$WORKDIR"/system/proc;
    mount -o bind /sys "$WORKDIR"/system/sys;
    cp /etc/hosts "$WORKDIR"/system/;
}

umountall(){
    umount "$WORKDIR"/system/sys;
    umount "$WORKDIR"/system/proc;
    umount "$WORKDIR"/system/dev/pts;
    umount "$WORKDIR"/system/dev;
    umount -lf "$WORKDIR"/system;
    losetup -d /dev/loop/karch; # TODO: Figure out why it doesn't work after quitting DE
    rm -rf "$WORKDIR"/system;
}

launch(){
    check_host;
    trap umountall INT TERM;
    mountall;
    chroot "$WORKDIR"/system/ /bin/bash;
    umountall;
}

main(){
    check_host;
    trap umountall INT TERM;
    stop framework;
    stop webreader;
    killall Xephyr;
    print_bot "Starting karch";
    mountall;
    test -e "$WORKDIR"/system/usr/sbin/init-de.sh || {
        echo "$INITSCRIPT" > "$WORKDIR"/system/usr/sbin/init-de.sh;
        print_bot "First boot may take a while";
    }
    trap "true" HUP INT TERM
    chroot "$WORKDIR"/system/ /bin/bash /usr/sbin/init-de.sh;
    killall Xephyr;
    test ! -e "$WORKDIR"/system/etc/failed || {
        print_bot "Installing UI failed";
    }
    print_bot "Restoring Kindle UI, please wait...";
    umountall;
    sleep 3;
    umountall;
    start webreader;
    start framework;
}

if [ -z "$1" ]; then
    main
else
    eval "$1"
fi;
