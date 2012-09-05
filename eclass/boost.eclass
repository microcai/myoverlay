# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost libraries
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

EAPI="4"

_boost_python="*:2.6"
PYTHON_DEPEND="python? ${_boost_python}"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="*-jython *-pypy-*"

inherit base check-reqs flag-o-matic multilib python toolchain-funcs versionator

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_prepare src_configure src_compile src_install src_test

SLOT="$(get_version_component_range 1-2)"
BOOST_SLOT="$(replace_all_version_separators _ ${SLOT})"
BOOST_JAM="bjam-${BOOST_SLOT}"

BOOST_PV="$(replace_all_version_separators _)"
BOOST_P="${PN}_${BOOST_PV}"
PATCHES=( "${BOOST_PATCHDIR:="${WORKDIR}/patches"}" )

DESCRIPTION="boost.org c++ libraries"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2"
[ "${BOOST_PATCHSET}" ] && \
	SRC_URI+=" http://gekis-playground.googlecode.com/files/${BOOST_PATCHSET}"

LICENSE="Boost-1.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE="debug doc icu static test +threads tools"
# add available libraries of boost version 
IUSE+=" ${BOOST_LIBRARIES}"

RDEPEND="sys-libs/zlib
	regex? ( icu? ( dev-libs/icu ) )
	tools? ( dev-libs/icu )"
DEPEND="${RDEPEND}
	~dev-libs/boost-headers-${PV}
	~dev-util/boost-build-${PV}"

REQUIRED_USE="graph_parallel? ( mpi )"

S="${WORKDIR}/${BOOST_P}"

boost_pkg_pretend() {
	einfo "Enable useflag[test] to run tests!"

	if use test ; then
		CHECKREQS_DISK_BUILD="15G"
		check-reqs_pkg_pretend
	fi
}

boost_pkg_setup() {
	# use regular expression to read last job count or default to 1 :D
	jobs="$(sed -r -e "s:.*[-]{1,2}j(obs)?[ =]?([0-9]*).*:\2:" <<< "${MAKEOPTS}")"
	jobs="-j${jobs:=1}"

	if use test ; then
		ewarn "The tests may take several hours on a recent machine"
		ewarn "but they will not fail (unless something weird happens ;-)"
		ewarn "This is because the tests depend on the used compiler/-version"
		ewarn "and the platform and upstream says that this is normal."
		ewarn "If you are interested in the results, please take a look at the"
		ewarn "generated results page:"
		ewarn "  ${ROOT}usr/share/doc/${PF}/status/cs-$(uname).html"
	fi

	if use debug ; then
		ewarn "The debug USE-flag means that a second set of the boost libraries"
		ewarn "will be built containing debug-symbols. But even though the optimization"
		ewarn "flags you might have set are not stripped, there will be a performance"
		ewarn "penalty and linking other packages against the debug version of boost"
		ewarn "is _not_ recommended."
	fi

	use python && python_pkg_setup
}

boost_src_prepare() {
	[ "${BOOST_PATCHSET}" ] && EPATCH_SUFFIX="diff" base_src_prepare

	# boost.random library: /dev/urandom support
	if [[ ${SLOT} < 1.48 ]] && use random && [[ -e /dev/urandom ]] ; then
		local lib_random="${S}/libs/random"

		mkdir -p "${lib_random}"/build
		cp -v "${FILESDIR}"/random-Jamfile "${lib_random}"/build

		sed -e 's/#ifdef __linux__/#if 1/' \
			-i "${lib_random}"/src/random_device.cpp \
			|| die
	fi

	# fix tests
	use test && _boost_fix_jamtest
}

boost_src_configure() {
	# -fno-strict-aliasing: prevent invalid code
	append-flags -fno-strict-aliasing

	# we need to add the prefix, and in two cases this exceeds, so prepare
	# for the largest possible space allocation
	[[ ${CHOST} == *-darwin* ]] && append-ldflags -Wl,-headerpad_max_install_names

	# bug 298489
	if use ppc || use ppc64 ; then
		[[ $(gcc-version) > 4.3 ]] && append-flags -mno-altivec
	fi

	local cmd="_boost_config"
	_boost_execute "${cmd} default" || die "configuration file not written"

	use python && _boost_execute "python_execute_function ${cmd}"
}

boost_src_compile() {
	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	local cmd="${BOOST_JAM} ${jobs} -q -d+1 gentoorelease"
	cmd+=" threading=${threading} ${link_opts} runtime-link=shared ${options}"
	_boost_execute "${cmd}" || die "build failed for options: ${options}"

	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "build failed for options: ${options}"
	fi

	# feature: python abi
	if use python ; then
		# FIXME: global?!
		_boost_python_dir=""
		_boost_library_mpi=""

		cmd="_boost_python_compile"
		_boost_execute "python_execute_function ${cmd}"
	fi

	if use tools ; then
		cd "${S}/tools"

		cmd="${BOOST_JAM} ${jobs} -q -d+1 gentoorelease ${options}"
		_boost_execute "${cmd}" || die "build of tools failed"
	fi
}

boost_src_install() {
	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local library_targets="$(_boost_library_targets)"
	local threading="$(_boost_threading)"

	local cmd="${BOOST_JAM} -q -d+1 gentoorelease threading=${threading}"
	cmd+=" ${link_opts} runtime-link=shared --includedir=${ED}/usr/include"
	cmd+=" --libdir=${ED}/usr/$(get_libdir) ${options} install"
	_boost_execute "${cmd}" || die "install failed for options: ${options}"

	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "install failed for options: ${options}"
	fi

	# feature: python abi
	if use python ; then
		cmd="_boost_python_install"
		_boost_execute "python_execute_function ${cmd}"
	fi

	# install tools
	if use tools ; then
		cd "${S}/dist/bin" || die

		for b in * ; do
			newbin "${b}" "${b}-${BOOST_SLOT}"
		done

		cd "${S}/dist" || die

		# install boostbook
		insinto /usr/share
		doins -r share/boostbook

		# slotting
		mv "${ED}/usr/share/boostbook" "${ED}/usr/share/boostbook-${BOOST_SLOT}" || die
	fi

	cd "${S}/status" || die

	# install tests
	if [ -f regress.log ] ; then
		docinto status
		dohtml *.html "${S}"/boost.png
		dodoc regress.log
	fi

	cd "${S}"

	# install docs
	if use doc ; then
		local docdir="/usr/share/doc/${PF}/html"

		find libs/*/* -type d -iname "test" -or -iname "src" | xargs rm -rf

		insinto ${docdir}
		doins -r libs
		# avoid broken links
		doins LICENSE_1_0.txt
	fi

	cd "${ED}/usr/$(get_libdir)" || die

	# debug version
	local libver="${BOOST_PV/_0}"
	local dbgver="${libver}-debug"

	# The threading libs obviously always gets the "-mt" (multithreading) tag
	# some packages seem to have a problem with it. Creating symlinks ...
	# The same goes for the mpi libs
	for library in mpi thread ; do
		if use ${library} ; then
			libs="lib${PN}_${library}-mt-${libver}$(get_libname)"
			use static && libs+=" lib${PN}_${library}-mt-${libver}.a"

			if use debug ; then
				libs+=" lib${PN}_${library}-mt-${dbgver}$(get_libname)"
				use static && libs+=" lib${PN}_${library}-mt-${dbgver}.a"
			fi

			for lib in ${libs} ; do
				ln -s ${lib} \
					"${ED}"/usr/$(get_libdir)/"$(sed -e 's/-mt//' <<< ${lib})" \
					|| die
			done
		fi
	done

	# subdirectory with unversioned symlinks
	local path="/usr/$(get_libdir)/${PN}-${BOOST_SLOT}"

	dodir ${path}
	for f in $(ls -1 ${library_targets} | grep -v debug) ; do
		ln -s ../${f} "${ED}"/${path}/${f/-${libver}} || die
	done

	if use debug ; then
		path+="-debug"

		dodir ${path}
		for f in $(ls -1 ${library_targets} | grep debug) ; do
			ln -s ../${f} "${ED}"/${path}/${f/-${dbgver}} || die
		done
	fi

	# boost's build system truely sucks for not having a destdir.  Because of
	# this we are forced to build with a prefix that includes the
	# DESTROOT, dynamic libraries on Darwin end messed up, referencing the
	# DESTROOT instead of the actual EPREFIX.  There is no way out of here
	# but to do it the dirty way of manually setting the right install_names.
	[[ -z ${ED+set} ]] && local ED=${D%/}${EPREFIX}/

	if [[ ${CHOST} == *-darwin* ]] ; then
		einfo "Working around completely broken build-system(tm)"
		for d in "${ED}"usr/lib/*.dylib ; do
			if [[ -f ${d} ]] ; then
				# fix the "soname"
				ebegin "  correcting install_name of ${d#${ED}}"
					install_name_tool -id "/${d#${ED}}" "${d}"
				eend $?

				# fix references to other libs
				refs=$(otool -XL "${d}" | \
					sed -e '1d' -e 's/^\t//' | \
					grep "^libboost_" | \
					cut -f1 -d' ')

				for r in ${refs} ; do
					ebegin "    correcting reference to ${r}"
						install_name_tool -change "${r}" \
							"${EPREFIX}/usr/lib/${r}" "${d}"
					eend $?
				done
			fi
		done
	fi
}

boost_src_test() {
	# FIXME: python tests disabled by design
	if use test ; then
		local options="$(_boost_options)"

		cd "${S}/tools/regression/build" || die
		local cmd="${BOOST_JAM} -q -d+1 gentoorelease ${options} process_jam_log compiler_status"
		_boost_execute "${cmd}" || die "build of regression test helpers failed"

		cd "${S}/status" || die

		# The following is largely taken from tools/regression/run_tests.sh,
		# but adapted to our needs.

		# Run the tests & write them into a file for postprocessing
		# Some of the test-checks seem to rely on regexps
		cmd="${BOOST_JAM} ${options} --dump-tests"
		echo ${cmd}; LC_ALL="C" ${cmd} 2>&1 | tee regress.log || die

		# postprocessing
		"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/process_jam_log" --v2 <regress.log

		[[ -n $? ]] && ewarn "Postprocessing the build log failed"

		cat > comment.html <<- __EOF__
<p>Tests are run on a <a href="http://www.gentoo.org/">Gentoo</a> system.</p>
__EOF__

		# generate the build log html summary page
		"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/compiler_status" \
			--v2 --comment comment.html "${S}" cs-$(uname).html cs-$(uname)-links.html

		[[ -n $? ]] && ewarn "Generating the build log html summary page failed"

		# do some cosmetic fixes :)
		sed -e 's|http://www.boost.org/boost.png|boost.png|' -i *.html || die
	fi
}

_boost_config() {
	[[ "${#}" -gt "1" ]] && die "${FUNCNAME}: wrong parameter"

	local python_abi="${1}"

	local compiler="gcc"
	local compilerVersion="$(gcc-version)"
	local compilerExecutable="$(tc-getCXX)"

	if [[ ${CHOST} == *-darwin* ]] ; then
		compiler="darwin"
		compilerVersion=$(gcc-fullversion)
	fi

	local jam_options=""
	use mpi && jam_options+="using mpi ;"
	[[ "${python_abi}" != "default" ]] \
		&& jam_options+="using python : $(python_get_version) : /usr : $(python_get_includedir) : $(python_get_libdir) ;"

	local config="user"
	[[ "${python_abi}" != "default" ]] && config="${PYTHON_ABI}"

	einfo "Writing new Jamfile: ${config}-config.jam"
	cat > "${S}/${config}-config.jam" << __EOF__

variant gentoorelease : release : <optimization>none <debug-symbols>none ;
variant gentoodebug : debug : <optimization>none ;

using ${compiler} : ${compilerVersion} : ${compilerExecutable} : <cxxflags>"${CXXFLAGS}" <linkflags>"${LDFLAGS}" ;

$(sed -e "s:;:;\n:g" <<< ${jam_options})
__EOF__

	# Maintainer information:
	# The debug-symbols=none and optimization=none are not official upstream
	# flags but a Gentoo specific patch to make sure that all our CXXFLAGS
	# and LDFLAGS are being respected. Using optimization=off would for example
	# add "-O0" and override "-O2" set by the user.
}

_boost_python_compile() {
	local options="$(_boost_basic_options ${PYTHON_ABI})"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	# feature: python abi
	options+=" --with-python --python-buildid=${PYTHON_ABI}"
	use mpi && options+=" --with-mpi"

	local cmd="${BOOST_JAM} ${jobs} -q -d+1 gentoorelease"
	cmd+=" threading=${threading} ${link_opts} runtime-link=shared ${options}"
	_boost_execute "${cmd}" || die "build failed for options: ${options}"

	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "build failed for options: ${options}"
	fi

	local python_dir="$(find bin.v2/libs -type d -name python | sort)"

	if [ -z "${_boost_python_dir}" ] ; then
		_boost_python_dir="${python_dir}"
	elif [[ "${python_dir}" != "${_boost_python_dir}" ]] ; then
		die "python path changed"
	fi

	for directory in ${_boost_python_dir} ; do
		_boost_execute "mv ${directory} ${directory}-${PYTHON_ABI}" \
			|| die "move '${directory}' -> '${directory}-${PYTHON_ABI}' failed"
	done

	if use mpi ; then
		local library_mpi="$(find bin.v2/libs/mpi/build/*/gentoorelease -type f -name mpi.so)"

		if [ -z "${_boost_library_mpi}" ] ; then
			local count="$(echo "${library_mpi}" | wc -l)"
			[[ "${count}" -ne 1 ]] && die "multiple mpi.so files found"

			_boost_library_mpi="${library_mpi}"
		elif [[ "${library_mpi}" != "${_boost_library_mpi}" ]] ; then
			die "python/mpi library path changed"
		fi

		_boost_execute "mv stage/lib/mpi.so stage/lib/mpi.so-${PYTHON_ABI}" \
			|| die "move 'stage/lib/mpi.so' -> 'stage/lib/mpi.so-${PYTHON_ABI}' failed"
	fi
}

_boost_python_install() {
	for directory in ${_boost_python_dir} ; do
		_boost_execute "mv ${directory}-${PYTHON_ABI} ${directory}" \
			|| die "move '${directory}-${PYTHON_ABI}' -> '${directory}' failed"
	done

	if use mpi ; then
		_boost_execute "mv stage/lib/mpi.so-${PYTHON_ABI} stage/lib/mpi.so" \
			|| die "move 'stage/lib/mpi.so-${PYTHON_ABI}' -> 'stage/lib/mpi.so' failed"
		_boost_execute "mv stage/lib/mpi.so-${PYTHON_ABI} ${_boost_library_mpi}" \
			|| die "move 'stage/lib/mpi.so-${PYTHON_ABI}' -> '${_boost_library_mpi}' failed"
	fi

	local options="$(_boost_basic_options ${PYTHON_ABI})"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	# feature: python abi
	options+=" --with-python --python-buildid=${PYTHON_ABI}"
	use mpi && options+=" --with-mpi"

	local cmd="${BOOST_JAM} -q -d+1 gentoorelease threading=${threading}"
	cmd+=" ${link_opts} runtime-link=shared --includedir=${ED}/usr/include"
	cmd+=" --libdir=${ED}/usr/$(get_libdir) ${options} install"
	_boost_execute "${cmd}" || die "install failed for options: ${options}"

	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "install failed for options: ${options}"
	fi

	rm -rf ${_boost_python_dir} || die "clean python paths"

	# move mpi.so to python sitedir
	if use mpi ; then
		exeinto "$(python_get_sitedir)/boost_${BOOST_SLOT}"
		doexe "${ED}/usr/$(get_libdir)/mpi.so"
		doexe "${S}"/libs/mpi/build/__init__.py

		rm -f "${ED}/usr/$(get_libdir)/mpi.so" || die
	fi
}

_boost_execute() {
	if [ -n "${@}" ] ; then
		# pretty print
		einfo "${@//--/\n\t--}"
		${@}

		return ${?}
	else
		return -1
	fi
}

_boost_basic_options() {
	[[ "${#}" -gt "1" ]] && die "${FUNCNAME}: too many parameters"

	local config="${1:-"user"}"

	local options=""
	options+=" pch=off --user-config=${S}/${config}-config.jam --prefix=${ED}/usr"
	options+=" --boost-build=/usr/share/boost-build-${BOOST_SLOT} --layout=versioned"

	# https://svn.boost.org/trac/boost/attachment/ticket/2597/add-disable-long-double.patch
	if use sparc || { use mips && [[ ${ABI} == o32 ]]; } || use hppa || use arm || use x86-fbsd || use sh; then
		options+=" --disable-long-double"
	fi

	echo -n ${options}
}

_boost_options() {
	local options="$(_boost_basic_options)"

	# feature: python abi
	for library in ${BOOST_LIBRARIES/python} ; do
		use ${library} && options+=" --with-${library}"
	done

	local use_icu="disable"
	use regex && use icu && use_icu="enable"
	options+=" --${use_icu}-icu"

	echo -n ${options}
}

_boost_link_options() {
	local link_opts="link=shared"
	use static && link_opts+=",static"

	echo -n ${link_opts}
}

_boost_library_targets() {
	local library_targets="*$(get_libname)"
	use static && library_targets+=" *.a"
	# there is no dynamically linked version of libboost_test_exec_monitor
	use test && library_targets+=" libboost_test_exec_monitor*.a"

	echo -n ${library_targets}
}

_boost_threading() {
	local threading="single"
	use threads && threading+=",multi"

	echo -n ${threading}
}

_boost_fix_jamtest() {
	local jam libraries="$(find "${S}"/libs/ -type d -name test)"

	for library in ${libraries} ; do
		jam="${library}/Jamfile.v2"

		if [ -f ${jam} ] ; then
			if grep -s -q ^project "${jam}" ; then
				if ! grep -s -q "import testing" "${jam}" ; then
					eerror "Jamfile broken for testing: 'import testing' missing."
					eerror "Report upstream broken file: ${jam}"

					sed -e "s:^project:import testing ;\n\0:" -i "${jam}"
				fi
			fi
		fi
	done
}

