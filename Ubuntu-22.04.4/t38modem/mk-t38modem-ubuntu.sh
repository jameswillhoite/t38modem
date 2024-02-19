#!/usr/bin/bash

# Sat 17 Feb 2024 08:33:06 PM EST
# Desktop install of Ubuntu 22.04.3 LTS
# How to build t38modem against opal 3.18.8 and ptlib 2.18.8
# Based on https://aur.archlinux.org/packages/t38modem PKGBUILD

# t38modem is not tested. May need more packages from PKBUILD.

#$ gcc --version
#gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0

set -e
set -u

umask 022

_srcdir='t38modem-4.6.2'
source="${_srcdir}.tar.gz" # https://github.com/hehol/t38modem/releases
startdir="${PWD}"
srcdir="${startdir}/src"
_pkgnam="${startdir}/${_srcdir}.ubuntu.pkg.tar.gz"

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
  CFLAGS=' -Wno-narrowing'
  CFLAGS+=' -Wno-deprecated-declarations' # Need this until auto_ptr fixed in opal
  CXXFLAGS=' -std=c++17'
CFLAGS="$CFLAGS -march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection" \
CXXFLAGS="$CFLAGS $CXXFLAGS -Wp,-D_GLIBCXX_ASSERTIONS" \
LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now" \
  nice make USE_UNIX98_PTY=1 -j "$(nproc)"
}

package() {
  cd "${srcdir}/${_srcdir}"
  local pkgdir="${startdir}/pkg"
  rm -rf "${pkgdir}"
  mkdir -p "${pkgdir}"

  install -Dpm755 t38modem -t "${pkgdir}/usr/bin"

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
unpack
prepare
build
package
#_inst
