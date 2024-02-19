#!/usr/bin/bash

# Sat 17 Feb 2024 08:33:06 PM EST
# Desktop install of Ubuntu 22.04.3 LTS
# How to build opal 3.18.8 against ptlib 2.18.8
# Based on https://aur.archlinux.org/packages/opal PKGBUILD

#$ gcc --version
#gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0

set -e
set -u

umask 022

_srcdir='opal-3.18.8'
source="${_srcdir}.tar.bz2" # https://sourceforge.net/projects/opalvoip/files/v3.18%20Cygni/Stable%208/
startdir="${PWD}"
srcdir="${startdir}/src"
_pkgnam="${startdir}/${_srcdir}.ubuntu.pkg.tar.gz"

base() {
  apt-get install libspeex-dev libopus-dev libvpx-dev libtheora-dev
  apt-get install libspandsp-dev # required for t38modem fax
  apt-get install libsrtp2-dev
  apt-get install swig
}

unpack() {
  if [ ! -d "${srcdir}" ]; then
    mkdir -p "${srcdir}"
    cd "${srcdir}"
    bsdtar -xf "${startdir}/${source}"
  fi
}

prepare() {
  cd "${srcdir}/${_srcdir}"
if [ ! -e 'Prepare.Ubuntu' ]; then
  touch 'Prepare.Ubuntu'
fi
}

build() {
  cd "${srcdir}/${_srcdir}"
  if [ ! -s 'config.log' ]; then
    local _conf=(
      --prefix='/usr'
      --enable-cpp17
      --disable-libavcodec # 3.18.8, not a trivial patch: "ffmpeg.cxx:111:3: error: ‘avcodec_register_all’ was not declared in this scope"
    )
    ./configure "${_conf[@]}"
  fi
CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection" \
CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS" \
LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now" \
  nice make -j "$(nproc)"
}

package() {
  cd "${srcdir}/${_srcdir}"
  local pkgdir="${startdir}/pkg"
  rm -rf "${pkgdir}"
  mkdir -p "${pkgdir}"

  make install DESTDIR="${pkgdir}"

  rm -f "${_pkgnam}"
  pushd "${pkgdir}" > /dev/null
  set -x
  #tar --owner='0' --group='0' -czf "${_pkgnam}" *
  bsdtar --uid=0 --gid=0 -czf "${_pkgnam}" *
  set +x
  popd > /dev/null
}

_inst() {
  set -x
  sudo bsdtar -C '/' -xf "${_pkgnam}"
  set +x
}
#rm -rf "${srcdir}"
base
unpack
prepare
build
package
#_inst
