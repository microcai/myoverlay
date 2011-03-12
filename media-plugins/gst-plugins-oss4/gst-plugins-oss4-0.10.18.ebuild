# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

inherit gst-plugins-bad

KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=media-libs/gst-plugins-base-0.10.27"
DEPEND="${RDEPEND}
	virtual/os-headers"
