#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2019-2023 Tianling Shen <cnsztl@immortalwrt.org>

NAME="unblockneteasemusic"
UNM_DIR="/usr/share/$NAME"
RUN_DIR="/var/run/$NAME"
mkdir -p "$RUN_DIR"

LOCK="$RUN_DIR/update_core.lock"
LOG="$RUN_DIR/run.log"

clean_log() {
	echo "" >"$LOG"
}

check_core_latest_version() {
	exec 200>"$LOCK"
	if ! flock -n 200 >/dev/null 2>&1; then
		echo -e "\nA task is already running." >>"$LOG"
		return 2
	fi

	core_latest_ver=$(wget --timeout=10 --tries=3 -qO- 'https://api.github.com/repos/UnblockNeteaseMusic/server/commits?sha=enhanced&path=precompiled' | jsonfilter -e '@[0].sha' 2>/dev/null)
	if [ -z "$core_latest_ver" ]; then
		echo -e "\nFailed to check latest core version, please try again later." >>"$LOG"
		return 1
	fi

	local core_local_ver="NOT FOUND"
	if [ -f "$UNM_DIR/core_local_ver" ]; then
		core_local_ver=$(cat "$UNM_DIR/core_local_ver")
	fi
	if [ "$core_local_ver" != "$core_latest_ver" ]; then
		clean_log
		echo -e "Local version: $core_local_ver, latest version: $core_latest_ver." >>"$LOG"
		update_core
	else
		echo -e "\nLocal version: $core_local_ver, latest version: $core_latest_ver." >>"$LOG"
		echo -e "You're already using the latest version." >>"$LOG"
		return 3
	fi
}

update_core() {
	echo -e "Updating core..." >>"$LOG"

	mkdir -p "$UNM_DIR/core"
	rm -rf "$UNM_DIR/core"/*

	file_list=$(wget --timeout=10 --tries=3 -qO- "https://api.github.com/repos/UnblockNeteaseMusic/server/contents/precompiled" | jsonfilter -e '@[*].path' 2>/dev/null)
	if [ -z "$file_list" ]; then
		echo "Failed to fetch file list from GitHub." >>"$LOG"
		return 1
	fi

	for file in $file_list; do
		wget --timeout=10 --tries=3 "https://gh-proxy.org/https://raw.githubusercontent.com/UnblockNeteaseMusic/server/$core_latest_ver/$file" -qO "$UNM_DIR/core/${file##*/}"
		[ -s "$UNM_DIR/core/${file##*/}" ] || {
			echo -e "Failed to download ${file##*/}." >>"$LOG"
			return 1
		}
	done

	for cert in "ca.crt" "server.crt" "server.key"; do
		wget --timeout=10 --tries=3 "https://gh-proxy.org/https://raw.githubusercontent.com/UnblockNeteaseMusic/server/$core_latest_ver/$cert" -qO "$UNM_DIR/core/$cert"
		[ -s "$UNM_DIR/core/${cert}" ] || {
			echo -e "Failed to download ${cert}." >>"$LOG"
			return 1
		}
	done

	echo -e "$core_latest_ver" >"$UNM_DIR/core_local_ver"
	[ -n "$non_restart" ] || /etc/init.d/"$NAME" restart

	echo -e "Succeeded in updating core." >"$LOG"
	echo -e "Current core version: $core_latest_ver.\n" >>"$LOG"
}

case "$1" in
"check_version")
	if [ ! -s "$UNM_DIR/core_local_ver" ] || [ ! -f "$UNM_DIR/core/app.js" ]; then
		echo -e "Not installed."
		exit 2
	else
		version="$(node "$UNM_DIR/core/app.js" -v)"
		commit="$(cat "$UNM_DIR/core_local_ver" | head -c7)"
		echo "$version ($commit)"
		exit 0
	fi
	;;
"update_core")
	check_core_latest_version
	exit $?
	;;
"update_core_non_restart")
	non_restart=1
	check_core_latest_version
	exit $?
	;;
"remove_core")
	echo "Removing core files..."
	/etc/init.d/"$NAME" stop >/dev/null 2>&1
	rm -rf "$UNM_DIR/core" "$UNM_DIR/core_local_ver"
	echo "Done."
	;;
*)
	echo -e "Usage: $0 {check_version|update_core|update_core_non_restart|remove_core}"
	exit 1
	;;
esac
