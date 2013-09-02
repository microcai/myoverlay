# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/dropbox/dropbox-1.4.7.ebuild,v 1.1 2012/05/29 08:33:02 naota Exp $

EAPI="4"

inherit gnome2-utils pax-utils

DESCRIPTION="Dropbox daemon (pretends to be GUI-less)"
HOMEPAGE="http://dropbox.com/"
SRC_URI=" amd64? ( https://dl-web.dropbox.com/u/17/dropbox-lnx.x86_64-${PV}.tar.gz )"

LICENSE="CCPL-Attribution-NoDerivs-3.0 FTL MIT LGPL-2 openssl dropbox"
SLOT="0"
KEYWORDS="~amd64 "
IUSE="+librsync-bundled"
RESTRICT="mirror strip"

QA_DT_HASH="opt/${PN}/.*"
QA_EXECSTACK_x86="opt/dropbox/_ctypes.so"
QA_EXECSTACK_amd64="opt/dropbox/_ctypes.so"

DEPEND="x11-themes/hicolor-icon-theme"
# Be sure to have GLIBCXX_3.4.9, #393125
RDEPEND="
	app-arch/bzip2
	dev-libs/popt
	media-libs/libpng:1.2
	!librsync-bundled? ( net-libs/librsync )
	net-misc/wget
	>=sys-devel/gcc-4.2.0
	sys-libs/zlib
"

src_unpack() {
	unpack ${A}
	mkdir -p "${S}"
	mv "${WORKDIR}/.dropbox-dist" "${S}"/src || die
	cd "${S}"/src
	rm -vf libstdc++.so.6 libz* libbz2* libpopt.so.0 libpng12.so.0 || die
	if ! use librsync-bundled; then
		rm -vf librsync.so.1 || die
	fi
	pax-mark cm "${S}/src/dropbox"
	cd "${WORKDIR}"
}

src_install() {
	cd src || die
	dodoc README ACKNOWLEDGEMENTS
	rm README ACKNOWLEDGEMENTS || die

	local targetdir="/opt/dropbox"
	insinto "${targetdir}"
	doins -r *
	fperms a+x "${targetdir}/dropbox"
	fperms a+x "${targetdir}/dropboxd"
	dosym "${targetdir}/dropboxd" "/opt/bin/dropbox"

	insinto /usr/share
	doins -r icons

	newinitd "${FILESDIR}"/dropbox.initd dropbox
	newconfd "${FILESDIR}"/dropbox.conf dropbox
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
