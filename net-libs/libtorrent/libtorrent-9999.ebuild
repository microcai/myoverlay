# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libtorrent/libtorrent-0.13.2.ebuild,v 1.1 2012/06/09 15:57:43 jlec Exp $

EAPI=4

inherit eutils autotools subversion

ESVN_REPO_URI="https://libtorrent.svn.sourceforge.net/svnroot/libtorrent/trunk/"

DESCRIPTION="BitTorrent library written in C++ for *nix"
HOMEPAGE="www.libtorrent.org/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="debug +ssl +dht"

RDEPEND=">=dev-libs/boost-1.51
	ssl? ( dev-libs/openssl )"
DEPEND="${RDEPEND}"

src_prepare(){
	eautoreconf
}

src_configure(){
	econf \
		$(use_enable debug) \
		$(use_enable ssl encryption) \
		$(use_enable dht) \
		${myconf}
}
