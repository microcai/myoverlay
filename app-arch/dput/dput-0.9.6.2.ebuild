# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-arch/deb2targz/deb2targz-1.ebuild,v 1.10 2008/02/17 12:37:50 armin76 Exp $

DESCRIPTION="Convert a .deb file to a .tar.gz archive"
HOMEPAGE="http://www.miketaylor.org.uk/tech/deb/"
SRC_URI="http://ftp.de.debian.org/debian/pool/main/d/dput/dput_${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc sparc x86"
IUSE=""

DEPEND=""
RDEPEND="dev-lang/python"

MY_P=dput

inherit eutils

S=${WORKDIR}/${MY_P}

src_install(){

	cd ${P}

	epatch "${FILESDIR}/rules.patch" || die

	export PATH="${WORKDIR}:${PATH}"
	export TMPDIR="${D}"

	make -f debian/rules binary || die

	#dobin ${PN}
}

