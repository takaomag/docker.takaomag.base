#!/bin/bash

SCRIPT_NAME=$(basename ${0})
SCRIPT_VERSION='1.0.0'

# set font types
source /opt/local/bin/x-set-shell-fonts-env.sh

# default args
PACCACHE_KEEP_NUM=${PACCACHE_KEEP_NUM:-2}

function show_usage() {
  msg_info "${SCRIPT_NAME} options:"
  msg_info "  [ -h, --help ]"
  msg_info "  [ -v, --version ]"
  msg_info "  [ --paccache-keep-num \${PACCACHE_KEEP_NUM} ]"
  msg_info "  [ --remove-tmp ]"
  echo
}

set -e

for OPT in "$@"; do
  case "$OPT" in
  '-h' | '--help')
    show_usage
    exit 0
    ;;
  '-v' | '--version')
    msg_info "${SCRIPT_VERSION}"
    exit 0
    ;;
  '--paccache-keep-num')
    if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
      msg_error "[ERROR] ${SCRIPT_NAME}: option requires an argument -- ${1}"
      echo
      show_usage
      exit 1
    fi
    PACCACHE_KEEP_NUM=$2
    shift 2
    ;;
  '--remove-tmp')
    RREMOVE_TMP='true'
    shift
    ;;
  -*)
    msg_error "[ERROR] ${SCRIPT_NAME}: invalid option -- $(echo ${1} | sed 's/^-*//')'"
    echo
    show_usage
    exit 1
    ;;
  *)
    if [[ ! -z "${1}" ]] && [[ ! "${1}" =~ ^-+ ]]; then
      #param=( ${param[@]} "${1}" )
      param+=("${1}")
      shift
    fi
    ;;
  esac
done

if [[ "${RREMOVE_TMP}" ]]; then
  RREMOVE_TMP='true'
else
  RREMOVE_TMP='false'
fi

echo
msg_notice "Remove unnecessary files ..."
msg_notice "  --paccache-keep-num: ${PACCACHE_KEEP_NUM}"
msg_notice "  --remove-tmp: ${RREMOVE_TMP}"
echo

if type ccache >/dev/null 2>&1; then
  ccache --clear
  ccache --zero-stats
fi

_pkg_orphans=$(yay -Qtdq || true)
if [[ ! -z "${_pkg_orphans}" ]]; then
  msg_warning "[WARNING] ######## Orphan packages #######\n${_pkg_orphans}"
fi

_pkg_file_updates=$(find / -type f -regextype posix-extended -regex ".+\.pac(new|save|orig)" || true)
if [[ ! -z "${_pkg_file_updates}" ]]; then
  msg_warning "[WARNING] ######## Files updated by pacman #######\n${_pkg_file_updates}"
fi

# pacman -Scc --noconfirm
# rm -rf /var/cache/pacman/pkg/*
find /var/cache/pacman/pkg -iname "*.part" -delete
# paccache --remove --uninstalled --keep ${PACCACHE_KEEP_NUM} >/dev/null 2>&1 || true
paccache --remove --keep ${PACCACHE_KEEP_NUM}
paccache --remove --uninstalled --keep ${PACCACHE_KEEP_NUM}
# rm -f /etc/pacman.d/mirrorlist.pacnew
rm -f /var/log/pacman.log
rm -f ~/.pip/pip.log
rm -rf ~/.cache/pip
rm -f ~/.*_history
rm -f ~/.*hist
# rm -rf /root/.m2/repository
rm -rf /root/.m2
# rm -rf /root/.ivy2/cache
rm -rf /root/.ivy2
# rm -rf /root/.gradle/caches
rm -rf /root/.gradle

if [ ${RREMOVE_TMP} == "true" ]; then
  find /tmp -mindepth 1 -delete || true
  find /var/tmp -mindepth 1 -delete || true
fi

if [[ -n "${HISTFILE}" ]]; then
  history -c && history -w
fi

msg_success "[SUCCESS] Remove unnecessary files"
