# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit autotools git linux-info pam

DESCRIPTION="systemd is a system and service manager for Linux"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd"
EGIT_REPO_URI="git://anongit.freedesktop.org/systemd"
EGIT_BRANCH="master"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="audit gtk pam +tcpwrap sysv selinux"

RDEPEND="
	>=sys-apps/dbus-1.4.0[systemd]
	sys-libs/libcap
	>=sys-fs/udev-163[systemd]
	audit? ( sys-process/audit )
	gtk? (	>=x11-libs/gtk+-2.20
			x11-libs/libnotify
			dev-libs/dbus-glib )
	tcpwrap? ( sys-apps/tcp-wrappers )
	pam? ( virtual/pam )
	selinux? ( sys-libs/libselinux )
	sys-apps/systemd-units
"
DEPEND="${RDEPEND}
	gtk? ( dev-lang/vala:0.10 )
	>=sys-kernel/linux-headers-2.6.32
"

CONFIG_CHECK="AUTOFS4_FS CGROUPS DEVTMPFS ~FANOTIFY"

pkg_setup() {
	linux-info_pkg_setup
	enewgroup lock # used by var-lock.mount
}

src_prepare() {
	epatch "${FILESDIR}"/0001-Revert-Revert-Revert-fsck-add-new-l-switch-to-fsck-m.patch
	eautoreconf
}

src_configure() {
	local myconf=

	if use sysv; then
		myconf="${myconf} --with-sysvinit-path=/etc/init.d --with-sysvrcd-path=/etc"
	else
		myconf="${myconf} --with-sysvinit-path= --with-sysvrcd-path="
	fi

	if use gtk; then
		export VALAC="$(type -p valac-0.10)"
	fi

	econf --with-distro=gentoo \
		--with-rootdir= \
		--localstatedir=/var \
		$(use_enable audit) \
		$(use_enable gtk) \
		$(use_enable pam) \
		$(use_enable tcpwrap) \
		$(use_enable selinux) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc "${D}/usr/share/doc/systemd"/* && \
		rm -r "${D}/usr/share/doc/systemd/"

	cd "${D}"/usr/share/man/man8/
	for i in halt poweroff reboot runlevel shutdown telinit; do
		mv ${i}.8 systemd.${i}.8
	done
}

check_mtab_is_symlink() {
	if test ! -L "${ROOT}"etc/mtab; then
		ewarn "${ROOT}etc/mtab must be a symlink to ${ROOT}proc/self/mounts!"
		ewarn "To correct that, execute"
		ewarn "  ln -sf '${ROOT}proc/self/mounts' '${ROOT}etc/mtab'"
	fi
}

pkg_postinst() {
	check_mtab_is_symlink
}
