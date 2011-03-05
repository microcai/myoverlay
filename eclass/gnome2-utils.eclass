# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/gnome2-utils.eclass,v 1.13 2008/10/22 21:04:53 eva Exp $

#
# gnome2-utils.eclass
#
# Set of auxiliary functions used to perform actions commonly needed by packages
# using the GNOME framework.
#
# Maintained by Gentoo's GNOME herd <gnome@gentoo.org>
#

case "${EAPI:-0}" in
	0|1|2|3) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

# Path to gconftool-2
: ${GCONFTOOL_BIN:="/usr/bin/gconftool-2"}

# Directory where scrollkeeper-update should do its work
: ${SCROLLKEEPER_DIR:="/var/lib/scrollkeeper"}

# Path to scrollkeeper-update
: ${SCROLLKEEPER_UPDATE_BIN:="/usr/bin/scrollkeeper-update"}

# Path to gtk-update-icon-cache
: ${GTK_UPDATE_ICON_CACHE:="/usr/bin/gtk-update-icon-cache"}

# Path to glib-compile-schemas
: ${GLIB_COMPILE_SCHEMAS:="/usr/bin/glib-compile-schemas"}



DEPEND=">=sys-apps/sed-4"



# Find the GConf schemas that are about to be installed and save their location
# in the GNOME2_ECLASS_SCHEMAS environment variable
gnome2_gconf_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" &> /dev/null
	export GNOME2_ECLASS_SCHEMAS=$(find 'etc/gconf/schemas/' -name '*.schemas' 2> /dev/null)
	popd &> /dev/null
}


# Applies any schema files installed by the current ebuild to Gconf's database
# using gconftool-2
gnome2_gconf_install() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${GCONFTOOL_BIN}"

	if [[ ! -x "${updater}" ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	if [[ -z "${GNOME2_ECLASS_SCHEMAS}" ]]; then
		debug-print "No GNOME 2 GConf schemas found"
		return
	fi

	# We are ready to install the GCONF Scheme now
	unset GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL
	export GCONF_CONFIG_SOURCE="$("${updater}" --get-default-source | sed "s;:/;:${EROOT};")"

	einfo "Installing GNOME 2 GConf schemas"

	local F
	for F in ${GNOME2_ECLASS_SCHEMAS}; do
		if [[ -e "${EROOT}${F}" ]]; then
			debug-print "Installing schema: ${F}"
			"${updater}" --makefile-install-rule "${EROOT}${F}" 1>/dev/null
		fi
	done

	# have gconf reload the new schemas
	pids=$(pgrep -x gconfd-2)
	if [[ $? == 0 ]] ; then
		ebegin "Reloading GConf schemas"
		kill -HUP ${pids}
		eend $?
	fi
}


# Removes schema files previously installed by the current ebuild from Gconf's
# database.
gnome2_gconf_uninstall() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${GCONFTOOL_BIN}"

	if [[ ! -x "${updater}" ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	if [[ -z "${GNOME2_ECLASS_SCHEMAS}" ]]; then
		debug-print "No GNOME 2 GConf schemas found"
		return
	fi

	unset GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL
	export GCONF_CONFIG_SOURCE="$("${updater}" --get-default-source | sed "s;:/;:${EROOT};")"

	einfo "Uninstalling GNOME 2 GConf schemas"

	local F
	for F in ${GNOME2_ECLASS_SCHEMAS}; do
		if [[ -e "${EROOT}${F}" ]]; then
			debug-print "Uninstalling gconf schema: ${F}"
			"${updater}" --makefile-uninstall-rule "${EROOT}${F}" 1>/dev/null
		fi
	done

	# have gconf reload the new schemas
	pids=$(pgrep -x gconfd-2)
	if [[ $? == 0 ]] ; then
		ebegin "Reloading GConf schemas"
		kill -HUP ${pids}
		eend $?
	fi
}


# Find the icons that are about to be installed and save their location
# in the GNOME2_ECLASS_ICONS environment variable
# That function should be called from pkg_preinst
gnome2_icon_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" &> /dev/null
	export GNOME2_ECLASS_ICONS=$(find 'usr/share/icons' -maxdepth 1 -mindepth 1 -type d 2> /dev/null)
	popd &> /dev/null
}


# Updates Gtk+ icon cache files under /usr/share/icons if the current ebuild
# have installed anything under that location.
gnome2_icon_cache_update() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${GTK_UPDATE_ICON_CACHE}"

	if [[ ! -x "${updater}" ]] ; then
		debug-print "${updater} is not executable"
		return
	fi

	if [[ -z "${GNOME2_ECLASS_ICONS}" ]]; then
		debug-print "No icon cache to update"
		return
	fi

	ebegin "Updating icons cache"

	local retval=0
	local fails=( )

	for dir in ${GNOME2_ECLASS_ICONS}
	do
		if [[ -f "${ROOT}${dir}/index.theme" ]] ; then
			local rv=0

			"${updater}" -qf "${EROOT}${dir}"
			rv=$?

			if [[ ! $rv -eq 0 ]] ; then
				debug-print "Updating cache failed on ${EROOT}${dir}"

				# Add to the list of failures
				fails[$(( ${#fails[@]} + 1 ))]="${EROOT}${dir}"

				retval=2
			fi
		fi
	done

	eend ${retval}

	for f in "${fails[@]}" ; do
		eerror "Failed to update cache with icon $f"
	done
}


# Workaround applied to Makefile rules in order to remove redundant
# calls to scrollkeeper-update and sandbox violations.
gnome2_omf_fix() {
	local omf_makefiles filename

	omf_makefiles="$@"

	if [[ -f ${S}/omf.make ]] ; then
		omf_makefiles="${omf_makefiles} ${S}/omf.make"
	fi

	# testing fixing of all makefiles found
	# The sort is important to ensure .am is listed before the respective .in for
	# maintainer mode regeneration not kicking in due to .am being newer than .in
	for filename in $(find ./ -name "Makefile.in" -o -name "Makefile.am" |sort) ; do
		omf_makefiles="${omf_makefiles} ${filename}"
	done

	ebegin "Fixing OMF Makefiles"

	local retval=0
	local fails=( )

	for omf in ${omf_makefiles} ; do
		local rv=0

		sed -i -e 's:scrollkeeper-update:true:' "${omf}"
		retval=$?

		if [[ ! $rv -eq 0 ]] ; then
			debug-print "updating of ${omf} failed"

			# Add to the list of failures
			fails[$(( ${#fails[@]} + 1 ))]=$omf

			retval=2
		fi
	done

	eend $retval

	for f in "${fails[@]}" ; do
		eerror "Failed to update OMF Makefile $f"
	done
}


# Updates the global scrollkeeper database.
gnome2_scrollkeeper_update() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	if [[ -x "${EROOT}${SCROLLKEEPER_UPDATE_BIN}" ]]; then
		einfo "Updating scrollkeeper database ..."
		"${EROOT}${SCROLLKEEPER_UPDATE_BIN}" -q -p "${EROOT}${SCROLLKEEPER_DIR}"
	fi
}

gnome2_schemas_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" &>/dev/null
	export GNOME2_ECLASS_GLIB_SCHEMAS=$(find 'usr/share/glib-2.0/schemas' -name '*.gschema.xml' 2>/dev/null)
	popd &>/dev/null
}

gnome2_schemas_update() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${GLIB_COMPILE_SCHEMAS}"

	if [[ ! -x ${updater} ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	if [[ -z ${GNOME2_ECLASS_GLIB_SCHEMAS} ]]; then
		debug-print "No GSettings schemas to update"
		return
	fi

	ebegin "Updating GSettings schemas"
	${updater} --allow-any-name "$@" "${EROOT%/}/usr/share/glib-2.0/schemas" &>/dev/null
	eend $?
}
