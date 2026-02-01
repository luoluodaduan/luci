# Copyright 2018-2025 Nick Peng <pymumu@gmail.com>
# Licensed to the public under the GPL V3 License.

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-smartdns
PKG_VERSION:=20260101
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0-or-later
PKG_MAINTAINER:=Nick Peng <pymumu@gmail.com>

LUCI_TITLE:=LuCI for smartdns
LUCI_DESCRIPTION:=Provides LuCI interface for SmartDNS.
LUCI_DEPENDS:=+luci-base +smartdns
LUCI_PKGARCH:=all

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
