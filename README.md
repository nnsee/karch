# karch

A KUAL extension to easily and automatically manage an Arch Linux chroot installation on an Amazon Kindle.

__NOTE__: This project is no longer maintained. You should probably check out the [Alpine Kindle](https://github.com/schuhumi/alpine_kindle) project instead.

### Requirements
* A newer model rooted Kindle
* [KUAL](https://www.mobileread.com/forums/showthread.php?t=203326)

### Installation
First, you need to create an Arch Linux filesystem and transfer it to your Kindle. Follow the steps detailed [in this post](https://neonsea.uk/blog/2019/04/14/chroot-shenanigans-2.html) up until you've created the filesystem and transferred it over. Everything else is suggested -- to get an understanding of how it works -- but not mandatory. 

You can then clone or download this repository and extract it to your KUAL `extensions` directory on your Kindle.

Place the filesystem (by default named `arch.img`) in the `karch` extension directory.

### Usage
Simply launch KUAL and select `karch` from the menu. You can then choose to launch the environment.

If you have the [`kterm` KUAL extension](https://www.fabiszewski.net/kindle-terminal/), you will also have an option to launch the chroot in a terminal window instead of a graphical environment.
