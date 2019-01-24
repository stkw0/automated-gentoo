#!/bin/bash

function update() {
	eix-sync -q || return 1
	emerge -quUDN --with-bdeps=y @world || return 1
	emerge -q @preserved-rebuild || return 1
}

function clean() {
	emerge -qc || return 1
	eclean-kernel -n 3 || return 1
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

send "All OK"
