# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow
# Purpose: Serve paths to boost libraries & headers
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

inherit flag-o-matic multilib

boost-utils_get_include_path() {
	[ ${#} -ne 1 ] && die "${FUNCNAME}: need boost slot as parameter"

	local slot="${1}"
	local path="${EPREFIX}/usr/include/boost-${slot/./_}"

	if [ -d "${path}" ] ; then
		echo -n "${path}"
	else
		die "${FUNCNAME}: path not found! (${path})"
	fi
}

boost-utils_get_library_path() {
	[ ${#} -gt 1 ] && die "${FUNCNAME}: need boost slot as parameter"

	local slot

	if [ ${#} -eq 1 ] ; then
		slot="${1}"
	else
		slot="$(boost-utils_get_slot)"
	fi

	local path="${EPREFIX}/usr/$(get_libdir)/boost-${slot/./_}"

	if [ -d "${path}" ] ; then
		echo -n "${path}"
	else
		die "${FUNCNAME}: path not found! (${path})"
	fi
}

boost-utils_get_slot() {
	local header="${EPREFIX}/usr/include/boost/version.hpp"
	local slot="$(grep -o -e "[0-9]_[0-9][0-9]" ${header})"

	if [ "${slot}" ] ; then
		echo -n "${slot/_/.}"
	else
		die "${FUNCNAME}: could not find boost slot"
	fi
}

# convenience wrapper
boost-utils_add_library_path() {
	local path="$(boost-utils_get_library_path)"

	append-ldflags "-L${path}"
}

boost-utils_add_paths() {
	boost-utils_add_library_path
}

