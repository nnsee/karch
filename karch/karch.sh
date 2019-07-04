#!/bin/sh
set -x
SCREENSIZE=$(eips -i | grep 'xres:' | awk '{print $2"x"$4}')
SERVICES="framework pillow webreader kb contentpackd"

WORK_DIR=$(pwd)
CHROOT_DIRECTORY="system"
FS_FILE="arch.img"

CHRPATH="${WORK_DIR}/${CHROOT_DIRECTORY}"

INITSCRIPT="#!/bin/sh

rm /etc/resolv.conf;
echo 'nameserver 8.8.8.8' > /etc/resolv.conf;
test -e /etc/ready || {
    pacman-key --init;
    pacman-key --populate archlinuxarm;
    pacman -Syu --noconfirm;
    pacman -S lxde xorg-server-xephyr --noconfirm;
    if [ \$? -eq 0 ]; then
        touch /etc/ready;
    else
        touch /etc/failed;
        exit 1;
fi
}

export DISPLAY=:0
Xephyr :1 -title \"L:A_N:application_ID:xephyr\" -screen ${SCREENSIZE} -cc 4 -nocursor &
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
    test -e "${WORK_DIR}/${FS_FILE}" || {
        print_bot "${FS_FILE} not found!";
        exit 1;
    }
}

mountall(){
    rm /dev/loop/karch;
    mknod -m0660 /dev/loop/karch b 7 250;
    mkdir "${CHRPATH}";
    mount -o loop=/dev/loop/karch -t ext4 "${WORK_DIR}/${FS_FILE}" "${CHRPATH}" ||
      mount /dev/loop/karch -t ext4 "${CHRPATH}";
    mount -o bind /dev     "${CHRPATH}/dev";
    mount -o bind /dev/pts "${CHRPATH}/dev/pts";
    mount -o bind /proc    "${CHRPATH}/proc";
    mount -o bind /sys     "${CHRPATH}/sys";
    mount -o bind /tmp     "${CHRPATH}/tmp";
    cp /etc/hosts          "${CHRPATH}/";
}

umountall(){
    umount "${CHRPATH}/tmp";
    umount "${CHRPATH}/sys";
    umount "${CHRPATH}/proc";
    umount "${CHRPATH}/dev/pts";
    umount "${CHRPATH}/dev";
    umount -lf "${CHRPATH}";
    losetup -d /dev/loop/karch; # TODO: Figure out why it doesn't work after quitting DE
    rm -rf "${CHRPATH}";
}

launch(){
    check_host;
    trap umountall INT TERM;
    mountall;
    chroot "${CHRPATH}" /bin/bash;
    umountall;
}

gui(){
    for service in ${SERVICES}; do 
        ${1} ${service}; 
    done
}

main(){
    check_host;
    trap umountall INT TERM;
    gui stop;
    killall Xephyr;
    print_bot "Starting karch";
    mountall;
    test -e "${CHRPATH}/usr/sbin/init-de.sh" || {
        echo "${INITSCRIPT}" > "${CHRPATH}/usr/sbin/init-de.sh";
        chmod +x "${CHRPATH}/usr/sbin/init-de.sh";
        print_bot "First boot may take a while";
    }
    trap "true" HUP INT TERM
    chroot "${CHRPATH}" /bin/bash /usr/sbin/init-de.sh;
    killall Xephyr;
    test ! -e "${CHRPATH}/etc/failed" || {
        print_bot "Installing UI failed";
        sleep 2;
    }
    print_bot "Restoring Kindle UI, please wait...";
    umountall;
    sleep 3;
    umountall;
    gui start;
}

if [ -z "$@" ]; then
    main
else
    eval "$@"
fi;
