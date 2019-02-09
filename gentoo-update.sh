#!/bin/bash

function update() {
	eix-sync -q || return 1
	emerge -quUDN --with-bdeps=y @world || return 1
	emerge -q @preserved-rebuild || return 1
}

function clean() {
	emerge -qc || return 1
   if stat /lib/modules &> /dev/null; then
     eclean-kernel -n 3 || return 1
   fi
}

function update_kernel() {
	[ "$(eselect --brief kernel list)" = "$(uname -s -r | tr '[A-Z]' '[a-z]' | tr ' ' '-')" ] && return 0
	# We suppose symlink USE is enabled
	cd /usr/src/linux || return 1
	cp ../linux-$(uname -r)/.config . || return 1

	# TODO: Detect initramfs-type¿?
	# TODO: Allow for different genkernel options ¿?
	genkernel --no-splash --install --oldconfig --no-xconfig --no-gconfig --no-nconfig --no-menuconfig --bootloader= --compress-initramfs-type=xz all || return 1

	/usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg || return 1
}

function send() {
	ntfy -b telegram send "$(hostname): $1"
}

if ! update; then
	send "Update FAILED"
	exit
fi

if ! clean; then
	send "Clean FAILED"
	exit
fi

if ! update_kernel; then
	send "Kernel update FAILED"
	exit
fi

send "All OK"
