# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wpa_supplicant/wpa_supplicant-0.7.3-r2.ebuild,v 1.1 2011/01/12 19:51:44 alexxy Exp $

EAPI="2"

inherit eutils 

DESCRIPTION="GUI Front fot gnupg"
HOMEPAGE="http://www.tech-faq.com/gnupg-shell.shtml"
SRC_URI="http://www.tech-faq.com/gnupg-shell/gnupgshell-1.0.0.tar.gz"
LICENSE="|| ( GPL-2 BSD )"

SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86 ~x86-fbsd"

RDEPEND=" app-crypt/gnupg 
	"

DEPEND="x11-libs/wxGTK 
	dev-util/pkgconfig"

src_configure(){
	cd ${PN}
	epatch "${FILESDIR}/fix-install.patch"

}

src_compile() {
	einfo "Building gnupg shell"

	(	cd ${PN}/build && emake  CC=$CC CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS)
}

src_install() {
	einfo "Installing gnupg shell"
	dodir "/usr/bin"

	cd ${PN}/build && emake install DESTDIR=${D}

}

