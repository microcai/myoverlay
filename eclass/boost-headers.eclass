# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Install boost headers
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

EAPI="4"

inherit alternatives base multilib versionator

EXPORT_FUNCTIONS pkg_pretend src_unpack src_configure src_compile src_install

SLOT="$(get_version_component_range 1-2)"
BOOST_SLOT="$(replace_all_version_separators _ ${SLOT})"

BOOST_P="boost_$(replace_all_version_separators _)"
BOOST_PATCHDIR="${BOOST_PATCHDIR:="${WORKDIR}/patches"}"

DESCRIPTION="boost.org c++ header libraries"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2"
[ "${BOOST_PATCHSET}" ] && \
	SRC_URI+=" http://gekis-playground.googlecode.com/files/${BOOST_PATCHSET}"

LICENSE="Boost-1.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE=""

RDEPEND="!app-admin/eselect-boost"
DEPEND="${RDEPEND}"
PDEPEND="~dev-libs/boost-${PV}"

S="${WORKDIR}/${BOOST_P}"

# alternatives
SOURCE="/usr/include/boost"
ALTERNATIVES="/usr/include/boost-[0-9]_[0-9][0-9]/boost"

boost-headers_pkg_pretend() {
	local err=

	# old libraries
	ls -1 "${EPREFIX}"/usr/$(get_libdir)/libboost_* | grep -v boost_*_*
	[ -z ${?} ] && err=1

	# old includes
	ls -1 "${EPREFIX}"/usr/include/boost_* >/dev/null 2>&1
	[ -z ${?} ] && err=1

	# unslotted boost-headers
	[ -e "${EPREFIX}${SOURCE}" ] && [ ! -L "${EPREFIX}${SOURCE}" ] && err=1

	if [ ${err} ] ; then
		eerror
		eerror "Files from old dev-libs/boost package found."
		eerror "Please clean your system following the howto at:"
		eerror
		eerror "	http://code.google.com/p/gekis-playground/wiki/Boost"
		eerror
		die "keep cool and clean! ;)"
	fi
}

boost-headers_src_unpack() {
	tar xjpf "${DISTDIR}/${BOOST_P}.tar.bz2" "${BOOST_P}/boost" \
		|| tar xjpf "${DISTDIR}/${BOOST_P}.tar.bz2" "./${BOOST_P}/boost" \
		|| die

	[ "${BOOST_PATCHSET}" ] && unpack "${BOOST_PATCHSET}"
}

boost-headers_src_configure() { :; }

boost-headers_src_compile() { :; }

boost-headers_src_install() {
	dir="/usr/include/boost-${BOOST_SLOT}"

	dodir "${dir}"
	insinto "${dir}"
	doins -r boost
}

