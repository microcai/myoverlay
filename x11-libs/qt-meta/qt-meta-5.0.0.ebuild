# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-meta/qt-meta-4.8.ebuild,v 1.7 2012/05/20 20:50:00 pesa Exp $

EAPI=2

DESCRIPTION="The Qt toolkit is a comprehensive C++ application development framework"
HOMEPAGE="http://qt-project.org/ http://qt.nokia.com/"

LICENSE="|| ( LGPL-2.1 GPL-3 )"
SLOT="4"
KEYWORDS="amd64 ~arm ~ia64 ~ppc ~ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="dbus kde opengl openvg webkit"

DEPEND=""
RDEPEND="
	>=x11-libs/qt-core-${PV}:5
	dbus? ( >=x11-libs/qt-dbus-${PV}:5 )
	>=x11-libs/qt-declarative-${PV}:5
	>=x11-libs/qt-gui-${PV}:5
	>=x11-libs/qt-multimedia-${PV}:5
	opengl? ( >=x11-libs/qt-opengl-${PV}:5 )
	openvg? ( >=x11-libs/qt-openvg-${PV}:5 )
	kde? ( media-libs/phonon )
	!kde? ( || ( >=x11-libs/qt-phonon-${PV}:5 media-libs/phonon ) )
	>=x11-libs/qt-script-${PV}:5
	>=x11-libs/qt-sql-${PV}:5
	>=x11-libs/qt-svg-${PV}:5
	>=x11-libs/qt-test-${PV}:5
	webkit? ( >=x11-libs/qt-webkit-${PV}:5 )
	>=x11-libs/qt-xmlpatterns-${PV}:5
"

pkg_postinst() {
	echo
	einfo "Please note that this meta package is only provided for convenience."
	einfo "No packages should depend directly on this meta package, but on the"
	einfo "specific split Qt packages needed."
	echo
}
