# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils git-r3 flag-o-matic gnome2-utils

DESCRIPTION="Nintendo 3DS Emulator"
HOMEPAGE="https://citra-emu.org/"
EGIT_REPO_URI="https://github.com/citra-emu/citra.git"
EGIT_SUBMODULES=( '*' '-externals/*' )

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="doc sdl2 qt5 system-boost clang telemetry i18n"

REQUIRED_USE="|| ( sdl2 qt5 )"
RDEPEND="virtual/opengl
	media-libs/libpng:=
	sys-libs/zlib
	net-misc/curl
	system-boost? ( >=dev-libs/boost-1.63.0:= )
	sdl2? ( media-libs/libsdl2 )
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtopengl:5
		dev-qt/qtwidgets:5
		i18n? ( dev-qt/linguist-tools )
	)"
DEPEND="${DEPEND}
	>=dev-util/cmake-3.6
	doc? ( >=app-doc/doxygen-1.8.8[dot] )
	!clang? ( >=sys-devel/gcc-5 )
	clang? (
		>=sys-devel/clang-3.8
		>=sys-libs/libcxx-3.8
	)"

src_prepare() {
	eapply "${FILESDIR}/citra-system-boost.patch"
	cmake-utils_src_prepare
}

src_configure() {
	if use clang; then
		export CC=clang
		export CXX=clang++
		append-cxxflags "-stdlib=libc++" # Upstream requires libcxx when building with clang
	fi

	local mycmakeargs=(
		-DENABLE_QT="$(usex qt5)"
		-DENABLE_SDL2="$(usex sdl2)"
		-DCITRA_USE_BUNDLED_SDL2=OFF
		-DCITRA_USE_BUNDLED_QT=OFF
		-DCITRA_USE_BUNDLED_CURL=OFF
		-DUSE_SYSTEM_CURL=ON
		-DUSE_SYSTEM_BOOST="$(usex system-boost)"
		-DENABLE_WEB_SERVICE=$(usex telemetry)
		-DCMAKE_BUILD_TYPE=Release
	)
	append-cxxflags "-fno-new-ttp-matching"
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	if use doc; then
		doxygen || die
	fi
}

src_install() {
	cmake-utils_src_install
	dodoc README.md CONTRIBUTING.md
	use doc && dodoc -r doc-build/html
}

pkg_postinst() {
	if use i18n; then
		elog "Translations only work with the Qt5 interface"
	fi
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	gnome2_icon_cache_update
}
