# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DESCRIPTION="Simple UEFI Boot Manager"
HOMEPAGE="http://freedesktop.org/wiki/Software/gummiboot"
EGIT_REPO_URI="git://anongit.freedesktop.org/gummiboot"
inherit toolchain-funcs git-2 


LICENSE="LGPL"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""


RDEPEND=">=sys-boot/gnu-efi-3.0q"

DEPEND=""

src_configure(){
	local iarch
	case $ARCH in
		ia64)  iarch=ia64 ;;
		x86)   iarch=ia32 ;;
		amd64) iarch=x86_64 ;;
		*)     die "unknown architecture: $ARCH" ;;
	esac

	echo "ARCH=${iarch}" >> Makefile
	echo "LIBDIR=/usr/$(get_libdir)"  >> Makefile
	echo "LIBEFIDIR=/usr/$(get_libdir)" >> Makefile

	echo "CFLAGS += ${CFLAGS} -g0" >> Makefile
}

src_compile(){
	emake CC="$(tc-getCC)"
# CXX="$(tc-getCXX)" LD="$(tc-getLD)" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

src_install(){
	dodir /usr/$(get_libdir)/${PN}
	insinto /usr/$(get_libdir)/${PN}
	doins	${PN}.efi
}

pkg_postinst(){
	einfo	"To use ${PN}, copy /usr/$(get_libdir)/${PN}/${PN}.efi"
	einfo "to ESP(Efi System Partion) "
	einfo "and call efbootimgr to add that"
}
