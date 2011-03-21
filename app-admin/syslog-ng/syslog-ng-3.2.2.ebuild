# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/syslog-ng/syslog-ng-3.2.2.ebuild,v 1.1 2011/01/18 17:44:14 mr_bones_ Exp $

EAPI=2
inherit autotools fixheadtails eutils

IUSE="+systemd caps hardened ipv6 +pcre selinux spoof-source sql ssl static -tcpd"

MY_PV=${PV/_/}
DESCRIPTION="syslog replacement with advanced filtering features"
HOMEPAGE="http://www.balabit.com/products/syslog_ng/"
SRC_URI="http://www.balabit.com/downloads/files/syslog-ng/sources/${PV}/source/syslog-ng_${PV}.tar.gz
	   systemd? (
		http://cgit.freedesktop.org/systemd/plain/src/sd-daemon.c
		http://cgit.freedesktop.org/systemd/plain/src/sd-daemon.h
	    )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

RESTRICT="test"

LIBS_DEPEND="
	spoof-source? ( net-libs/libnet )
	ssl? ( dev-libs/openssl )
	tcpd? ( >=sys-apps/tcp-wrappers-7.6 )
	!static? ( >=dev-libs/eventlog-0.2 )
	>=dev-libs/glib-2.10.1:2
	caps? ( sys-libs/libcap )
	sql? ( >=dev-db/libdbi-0.8.3 )"
RDEPEND="
	!static? (
		pcre? ( dev-libs/libpcre )
		${LIBS_DEPEND}
	)"
DEPEND="${RDEPEND}
	${LIBS_DEPEND}
	static? ( >=dev-libs/eventlog-0.2[static-libs] )
	dev-util/pkgconfig
	sys-devel/flex"
PROVIDE="virtual/logger"

src_prepare() {
	if use systemd ; then 
		cp "${DISTDIR}/sd-daemon.h" modules/afsocket/ || die
		cp "${DISTDIR}/sd-daemon.c" modules/afsocket/ || die
		
		epatch "${FILESDIR}/${PN}-systemd.patch"
	fi

	sed -i -e 's/mkdir /mkdir $(DESTDIR)/' scripts/Makefile.am || die
	ht_fix_file configure.in
	eautoreconf
}

src_configure() {
	local myconf

	if use static ; then
		myconf="${myconf} --enable-static-linking"
		if use pcre ; then
			ewarn "USE=pcre is incompatible with static linking"
			myconf="${myconf} --disable-pcre"
		fi
	else
			myconf="${myconf} --enable-dynamic-linking"
	fi
	econf \
		--disable-dependency-tracking \
		--sysconfdir=/etc/syslog-ng \
		--with-pidfile-dir=/var/run \
		$(use_enable caps linux-caps) \
		$(use_enable ipv6) \
		$(use_enable pcre) \
		$(use_enable spoof-source) \
		$(use_enable sql) \
		$(use_enable ssl) \
		$(use_enable tcpd tcp-wrapper) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc AUTHORS ChangeLog NEWS README \
		doc/examples/{syslog-ng.conf.sample,syslog-ng.conf.solaris} \
		contrib/syslog-ng.conf* \
		contrib/syslog2ng "${FILESDIR}/syslog-ng.conf."*

	# Install default configuration
	insinto /etc/syslog-ng
	if use hardened || use selinux ; then
		newins "${FILESDIR}/syslog-ng.conf.gentoo.hardened.${PV%.*}" syslog-ng.conf || die
	elif use userland_BSD ; then
		newins "${FILESDIR}/syslog-ng.conf.gentoo.fbsd.${PV%.*}" syslog-ng.conf || die
	else
		newins "${FILESDIR}/syslog-ng.conf.gentoo.${PV%.*}" syslog-ng.conf || die
	fi

	insinto /etc/logrotate.d
	# Install snippet for logrotate, which may or may not be installed
	if use hardened || use selinux ; then
		newins "${FILESDIR}/syslog-ng.logrotate.hardened" syslog-ng || die
	else
		newins "${FILESDIR}/syslog-ng.logrotate" syslog-ng || die
	fi

	newinitd "${FILESDIR}/syslog-ng.rc6.${PV%%.*}" syslog-ng || die
	newconfd "${FILESDIR}/syslog-ng.confd" syslog-ng || die
	keepdir /etc/syslog-ng/patterndb.d
	find "${D}" -type f -name '*.la' -exec rm {} + || die
}

pkg_postinst() {
	echo
	elog "It is highly recommended that app-admin/logrotate be emerged to"
	elog "manage the log files.  ${PN} installs a file in /etc/logrotate.d"
	elog "for logrotate to use."
	echo
}
