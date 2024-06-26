#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

set -vx

######################################################################################################################
### Setup Build System and GitHub

apt install -y autopoint

wget -qO- uny.nu/pkg | bash -s buildsys

### Installing build dependencies
unyp install python libidn2 libunistring

#pip3_bin=(/uny/pkg/python/*/bin/pip3)
#"${pip3_bin[0]}" install meson

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="libpsl"
pkggit="https://github.com/rockdaboot/libpsl.git refs/tags/*"
gitdepth="--depth=1"

### Get version info from git remote
# shellcheck disable=SC2086
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "/[0-9.]*$" | tail --lines=1)"
latest_ver="$(echo "$latest_head" | grep -o "/[0-9.].*" | sed "s|/||")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

git_clone_source_repo

#get_pkgconfig_paths
#automake_bin_path=(/uny/pkg/automake/*/bin)
#PATH="${automake_bin_path[0]}":"$PATH"
#export PATH

cd "$pkgname" || exit
git submodule init
git submodule update
rm -f gtk-doc.make 2>/dev/null
echo "EXTRA_DIST =" >gtk-doc.make
echo "CLEANFILES =" >>gtk-doc.make
cd /uny/sources || exit

archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
# shellcheck disable=SC2154
unyc <<"UNYEOF"
set -vx
source /uny/git/unypkg/fn

pkgname="libpsl"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths

####################################################
### Start of individual build script

unset LD_RUN_PATH

autoreconf --install --force --symlink

./configure --prefix=/uny/pkg/"$pkgname"/"$pkgver"

make -j"$(nproc)"
make -j"$(nproc)" check
make -j"$(nproc)" install

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
