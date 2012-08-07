# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/util-linux/util-linux-9999.ebuild,v 1.33 2012/06/02 18:55:37 vapier Exp $

EAPI="4"

AUTOTOOLS_IN_SOURCE_BUILD=1

EGIT_REPO_URI="git://git.kernel.org/pub/scm/utils/util-linux/util-linux.git"
inherit eutils toolchain-funcs flag-o-matic systemd
inherit autotools-utils git-2

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux"
KEYWORDS=""


MY_PV=${PV/_/-}
MY_P=${PN}-${MY_PV}
S=${WORKDIR}/${MY_P}

DESCRIPTION="Various useful Linux utilities"
HOMEPAGE="http://www.kernel.org/pub/linux/utils/util-linux/"

SRC_URI=""


LICENSE="GPL-2 GPL-3 LGPL-2.1 BSD-4 MIT public-domain"
SLOT="0"
IUSE="+cramfs crypt ddate loop-aes ncurses nls old-linux perl selinux slang static-libs udev unicode systemd"

RDEPEND="!sys-process/schedutils
	!sys-apps/setarch
	systemd? ( >=sys-apps/systemd-186 )
	!sys-block/eject
	!<sys-libs/e2fsprogs-libs-1.41.8
	!<sys-fs/e2fsprogs-1.41.8
	cramfs? ( sys-libs/zlib )
	ncurses? ( >=sys-libs/ncurses-5.2-r2 )
	perl? ( dev-lang/perl )
	selinux? ( sys-libs/libselinux )
	slang? ( sys-libs/slang )
	udev? ( sys-fs/udev )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )
	virtual/os-headers"

src_prepare() {
	po/update-potfiles
	eautoreconf
	elibtoolize

	echo "localstatedir=/run"  >> configure.ac
}

lfs_fallocate_test() {
	# Make sure we can use fallocate with LFS #300307
	cat <<-EOF > "${T}"/fallocate.c
	#define _GNU_SOURCE
	#include <fcntl.h>
	main() { return fallocate(0, 0, 0, 0); }
	EOF
	append-lfs-flags
	$(tc-getCC) ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} "${T}"/fallocate.c -o /dev/null >/dev/null 2>&1 \
		|| export ac_cv_func_fallocate=no
	rm -f "${T}"/fallocate.c
}

src_configure() {
	lfs_fallocate_test

	local myeconfargs=(
		--enable-fs-paths-extra=/usr/sbin
		$(use_enable nls)
		--enable-agetty
		$(use_enable cramfs)
		$(use_enable ddate)
		$(use_enable old-linux elvtune)
		--with-ncurses=$(usex ncurses $(usex unicode auto yes) no)
		--disable-kill
		--enable-last
		--enable-mesg
		--enable-partx
		--enable-raw
		--enable-rename
		--disable-reset
		--enable-schedutils
		--enable-wall
		--enable-write
		#enable for systemd
		$(use_enable systemd socket-activation)
		$(systemd_with_unitdir)
		$(use_with selinux)
		$(use_with slang)
		$(use_with udev)
		$(tc-has-tls || echo --disable-tls)
		#enable for eliminate compile errors
		--enable-static
		# conflict with shadow
		--disable-su
		--disable-login
	)
	#econf ${myeconfargs[*]}
	autotools-utils_src_configure
}

src_compile(){
	sed -i 's/\/usr\/\/var\/lib/\/run/g' config.status
	touch	configure
	find -name Makefile -exec touch '{}' +
	rm misc-utils/uuidd.socket
	emake localstatedir=/run misc-utils/uuidd.socket
	emake	localstatedir=/run
	sed -i 's/\/usr\/\/var\/lib/\/run/g' misc-utils/uuidd.socket
	sed -i 's/\/sbin\/uuidd/\/usr\/sbin\/uuidd/g' misc-utils/uuidd.service
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc AUTHORS NEWS README* Documentation/{TODO,*.txt}

	if ! use perl ; then #284093
		rm "${ED}"/usr/bin/chkdupexe 
		rm "${ED}"/usr/share/man/man1/chkdupexe.1 
	fi
	if ! use static-libs ; then
		find "${ED}" -name 'lib*.a' -delete
	fi

	# need the libs in /
	gen_usr_ldscript -a blkid mount uuid
	# e2fsprogs-libs didnt install .la files, and .pc work fine
	find "${ED}" -name '*.la' -delete

	if use crypt ; then
		newinitd "${FILESDIR}"/crypto-loop.initd crypto-loop || die
		newconfd "${FILESDIR}"/crypto-loop.confd crypto-loop || die
	fi
}

