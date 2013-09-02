# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit git-2 cmake-utils

DESCRIPTION="Tool that creates dependency graph of C++ code"
HOMEPAGE="http://gitorious.org/cpp-dependency-analyzer/"
EGIT_REPO_URI="git://gitorious.org/${PN}/${PN}.git"

LICENSE="LGPL-3"
KEYWORDS=""
SLOT="0"
IUSE="debug"

RDEPEND="
	media-gfx/graphviz
	dev-qt/qtcore:4
	dev-qt/qtgui:4
	dev-qt/qtsvg:4
"
DEPEND="${RDEPEND}
	>=dev-libs/boost-1.35.0
"
