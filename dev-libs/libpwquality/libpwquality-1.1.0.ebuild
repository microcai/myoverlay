# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
PYTHON_DEPEND="2:2.7"

inherit python

DESCRIPTION="Library for password quality checking and generating random passwords"
HOMEPAGE="https://fedorahosted.org/libpwquality/"
SRC_URI="https://fedorahosted.org/releases/l/i/${PN}/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=sys-libs/cracklib-2.8
	virtual/pam"
DEPEND="${RDEPEND}
	sys-devel/gettext"

