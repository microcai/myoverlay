# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-plugins/pidgin-encryption/pidgin-encryption-3.0-r1.ebuild,v 1.6 2010/10/26 14:33:40 jer Exp $

EAPI="2"

inherit autotools base subversion flag-o-matic eutils

DESCRIPTION="Pidgin QQ2010 PlugIn"
HOMEPAGE="http://code.google.com/p/libqq-pidgin/"
SRC_URI=""
ESVN_REPO_URI="http://libqq-pidgin.googlecode.com/svn/trunk/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 hppa ppc ~ppc64 sparc x86 ~x86-fbsd"
IUSE="nls debug"

RDEPEND="net-im/pidgin[-qq]
	>=x11-libs/gtk+-2
	>=dev-libs/nss-3.11"

DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	mkdir -p m4
	eautoreconf
}

src_configure() {
	strip-flags
	replace-flags -O? -O2
	if use debug ; then 
		replace-flags -O? -O0
		replace-flags -g? -g3
	fi
	econf $(use_enable nls)
}

src_install() {
	make install DESTDIR="${D}" || die "Install failed"
	dodoc CHANGELOG INSTALL NOTES README TODO VERSION WISHLIST
}
