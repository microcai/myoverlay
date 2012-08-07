# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-boot/gnu-efi/gnu-efi-3.0i.ebuild,v 1.3 2010/08/28 22:43:29 vapier Exp $

EAPT="4"

inherit eutils

MY_P="${PN}_${PV}"
DESCRIPTION="Library for build EFI Applications"
HOMEPAGE="http://developer.intel.com/technology/efi"
SRC_URI="mirror://sourceforge/gnu-efi/${MY_P}.orig.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ia64 ~x86"
IUSE=""

DEPEND="sys-apps/pciutils"

S="${WORKDIR}/${PN}-3.0"

src_compile() {
	local iarch
	case $ARCH in
		ia64)  iarch=ia64 ;;
		x86)   iarch=ia32 ;;
		amd64) iarch=x86_64 ;;
		*)     die "unknown architecture: $ARCH" ;;
	esac
	# The lib subdir uses unsafe archive targets, and
	# the apps subdir needs gnuefi subdir
	emake prefix=${CHOST}- ARCH=${iarch} -j1 || die
}

src_install() {
	emake install INSTALLROOT="${D}"/usr || die
	dodoc README* ChangeLog
}
