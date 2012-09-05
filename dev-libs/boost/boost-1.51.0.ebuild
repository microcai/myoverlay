# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

BOOST_LIBRARIES="chrono date_time filesystem graph graph_parallel iostreams
locale math mpi program_options python random regex serialization signals system
test thread timer wave"

BOOST_PATCHSET="gentoo-boost-1.51.0.tar.xz"

inherit boost

