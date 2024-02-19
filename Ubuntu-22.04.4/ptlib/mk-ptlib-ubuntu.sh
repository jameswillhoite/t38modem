#!/usr/bin/bash

# Sat 17 Feb 2024 08:33:06 PM EST
# Desktop install of Ubuntu 22.04.3 LTS
# How to build ptlib 2.18.8
# Based on https://aur.archlinux.org/packages/ptlib PKGBUILD

#$ gcc --version
#gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0

set -e
set -u

umask 022

_srcdir='ptlib-2.18.8'
source="${_srcdir}.tar.bz2" # https://sourceforge.net/projects/opalvoip/files/v3.18%20Cygni/Stable%208/
startdir="${PWD}"
srcdir="${startdir}/src"
_pkgnam="${startdir}/${_srcdir}.ubuntu.pkg.tar.gz"

base() {
  # https://www.awsmonster.com/how-to-install-development-tools-on
  apt-get update
  apt-get upgrade
  apt-get install openssh-server sshfs mc libarchive-tools
  # Not needrestart, halts with dialog
  apt-get install build-essential
  apt-get install autoconf automake libtool
  apt-get install flex bison gcc-doc
  #apt-get install gdb git

  # base ptlib build
  apt-get install libpcap-dev

  # full ptlib build
  apt-get install libssl-dev libexpat1-dev libncurses-dev

  # Most of these probably aren't needed for opal and t38modem
  apt-get install libjpeg-dev
  apt-get install libldap-dev liblua5.4-dev libsasl2-dev unixodbc-dev
  apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev # libgstreamer-plugins-bad1.0-dev libgstreamer-plugins-good1.0-dev
  apt-get install libavcodec-dev libswscale-dev libavformat-dev # libavutil-dev libswresample-dev # FFMPEG
  apt-get install libasound2-dev libsdl2-dev # ALSA
  apt-get install libavc1394-dev libdv4-dev libmagick++-dev
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
  local _f
  for _f in "${startdir}"/*.patch; do
    patch -Nup1 -i "${_f}"
  done
  # Based on https://build.opensuse.org/package/view_file/openSUSE:Factory/ptlib/libpt2-fix-avc-plugin.patch?expand=1
  # Needed for at least 2.18.8 to 2.21.0, possibly more
  local _seds=()
  for _f in frameWidth frameHeight colourFormat deviceName channelNumber videoFormat converter nativeVerticalFlip; do
    _seds+=(-e "s:\b${_f}\b:m_&:g")
  done
  sed -E "${_seds[@]}" -i 'plugins/vidinput_avc/vidinput_avc.cxx'
  touch 'Prepare.Ubuntu'
fi
}

build() {
  cd "${srcdir}/${_srcdir}"
  if [ ! -s 'config.log' ]; then
    local _conf=(
      --prefix='/usr'
      --enable-cpp17      # 2.18.8 defaults to -std=c++03
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
  find "${pkgdir}" -type 'f' -exec chmod 'u+w' '{}' '+'
  find "${pkgdir}/usr/lib" -type 'f' -name '*.a' -exec chmod 644 '{}' '+'
  rmdir "${pkgdir}/usr/bin"

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
base
rm -rf "${srcdir}"
unpack
prepare
build
package
#_inst
