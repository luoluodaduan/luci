# Copyright (C) 2020 Lienol <lawlienol@gmail.com>
# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-socat
PKG_DATE:=2026-01-01
PKG_RELEASE:=1

LUCI_TITLE:=LuCI support for Socat
LUCI_DEPENDS:=+socat +luci +luci-compat
LUCI_PKGARCH:=all

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
