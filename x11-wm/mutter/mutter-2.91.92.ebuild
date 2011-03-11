# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"
GNOME2_LA_PUNT="yes"

inherit autotools gnome2

DESCRIPTION="Upcoming GNOME 3 window manager (derived from metacity)"
HOMEPAGE="http://blogs.gnome.org/metacity/"

LICENSE="GPL-2"
SLOT="0"
IUSE="debug +introspection +sound test xinerama"
inherit gnome2-live
KEYWORDS="~amd64 ~x86"


RDEPEND=">=x11-libs/pango-1.2[X,introspection?]
	>=x11-libs/cairo-1.10[X]
	>=x11-libs/gtk+-2.91.7:3[introspection?]
	>=gnome-base/gconf-2:2
	>=dev-libs/glib-2.14:2
	>=media-libs/clutter-1.2:1.0
	>=x11-libs/startup-notification-0.7
	>=x11-libs/libXcomposite-0.2

	x11-libs/libICE
	x11-libs/libSM
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXrender

	introspection? ( >=dev-libs/gobject-introspection-0.9.5 )
	sound? (  >=media-libs/libcanberra-0.26[gtk3] )
	xinerama? ( x11-libs/libXinerama )
	gnome-extra/zenity
	!x11-misc/expocity"
DEPEND="${RDEPEND}
	>=app-text/gnome-doc-utils-0.8
	sys-devel/gettext
	>=dev-util/pkgconfig-0.9
	>=dev-util/intltool-0.35
	test? ( app-text/docbook-xml-dtd:4.5 )
	xinerama? ( x11-proto/xineramaproto )
	x11-proto/xextproto
	x11-proto/xproto"

DOCS="AUTHORS ChangeLog HACKING MAINTAINERS NEWS README *.txt doc/*.txt"

src_prepare() {
	G2CONF="${G2CONF}
		--disable-static
		--enable-gconf
		--enable-shape
		--enable-sm
		--enable-startup-notification
		--enable-verbose-mode
		--enable-compile-warnings=maximum
		$(use_with sound libcanberra)
		$(use_enable introspection)
		$(use_enable xinerama)"
	gnome2_src_prepare
}
