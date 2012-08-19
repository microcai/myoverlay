# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gnome-desktop/gnome-desktop-3.4.2.ebuild,v 1.1 2012/05/20 09:59:57 tetromino Exp $

EAPI="4"
GCONF_DEBUG="yes"
GNOME2_LA_PUNT="yes"

inherit eutils gnome2

DESCRIPTION="Libraries for the gnome desktop that are not part of the UI"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2 FDL-1.1 LGPL-2"
SLOT="3"
IUSE="doc +introspection"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~x86-solaris"

# TODO: Add RDEPEND on pciutils (requires support for reading gzipped pnp.ids)
# Latest schemas needed due to commit 7f3e3d52
# cairo[X] needed for gnome-bg
RDEPEND="
	>=dev-libs/glib-2.19.1:2
	x11-libs/cairo[X]
	>=x11-libs/gdk-pixbuf-2.21.3:2[introspection?]
	>=x11-libs/gtk+-3.3.6:3[introspection?]
	>=x11-libs/libXext-1.1
	>=x11-libs/libXrandr-1.3
	x11-libs/libX11
	>=gnome-base/gsettings-desktop-schemas-2.91.92
	doc? ( !<gnome-base/gnome-desktop-2.32.1-r1:2[doc] )
	introspection? ( >=dev-libs/gobject-introspection-0.9.7 )"
DEPEND="${RDEPEND}
	app-text/docbook-xml-dtd:4.1.2
	>=app-text/gnome-doc-utils-0.3.2
	>=dev-util/intltool-0.40.6
	sys-devel/gettext
	x11-proto/xproto
	>=x11-proto/randrproto-1.2
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.4 )"

# Includes X11/Xatom.h in libgnome-desktop/gnome-bg.c which comes from xproto
# Includes X11/extensions/Xrandr.h that includes randr.h from randrproto (and
# eventually libXrandr shouldn't RDEPEND on randrproto)

pkg_setup() {
	DOCS="AUTHORS ChangeLog HACKING NEWS README"
	# Note: do *not* use "--with-pnp-ids-path" argument. Otherwise, the pnp.ids
	# file (needed by other packages such as >=gnome-settings-daemon-3.1.2)
	# will not get installed in ${pnpdatadir} (/usr/share/libgnome-desktop-3.0).
	G2CONF="${G2CONF}
		--disable-scrollkeeper
		--disable-static
		--with-gnome-distributor=Gentoo
		$(use_enable doc desktop-docs)
		$(use_enable introspection)"
}
