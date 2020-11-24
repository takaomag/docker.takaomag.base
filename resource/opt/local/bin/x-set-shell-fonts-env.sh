#!/bin/bash

# set font types
FONT_DEFAULT=${FONT_DEFAULT:-"\e[0m"}
FONT_SUCCESS=${FONT_SUCCESS:-"\e[1;32m"}
FONT_INFO=${FONT_INFO:-"\e[1;37m"}
FONT_NOTICE=${FONT_NOTICE:-"\e[1;35m"}
FONT_WARNING=${FONT_WARNING:-"\e[1;33m"}
FONT_ERROR=${FONT_ERROR:-"\e[1;31m"}

msg_info() {
  local msg=$1
  shift
  if [[ "${COLOR_OUTPUT}" = 'true' ]]; then
    printf "${FONT_INFO}${msg}${FONT_DEFAULT}\n" "$@"
  else
    printf "${msg}\n" "$@"
  fi
}
msg_success() {
  local msg=$1
  shift
  if [[ "${COLOR_OUTPUT}" = 'true' ]]; then
    printf "${FONT_SUCCESS}${msg}${FONT_DEFAULT}\n" "$@"
  else
    printf "${msg}\n" "$@"
  fi
}
msg_notice() {
  local msg=$1
  shift
  if [[ "${COLOR_OUTPUT}" = 'true' ]]; then
    printf "${FONT_NOTICE}${msg}${FONT_DEFAULT}\n" "$@"
  else
    printf "${msg}\n" "$@"
  fi
}
msg_warning() {
  local msg=$1
  shift
  if [[ "${COLOR_OUTPUT}" = 'true' ]]; then
    printf "${FONT_WARNING}${msg}${FONT_DEFAULT}\n" "$@"
  else
    printf "${msg}\n" "$@"
  fi
}
msg_error() {
  local msg=$1
  shift
  if [[ "${COLOR_OUTPUT}" = 'true' ]]; then
    printf "${FONT_ERROR}${msg}${FONT_DEFAULT}\n" "$@" 1>&2
  else
    printf "${msg}\n" "$@" 1>&2
  fi
}

COLOR_OUTPUT=${COLOR_OUTPUT:-"yes"}
COLOR_OUTPUT=${COLOR_OUTPUT,,}
if [[ "${COLOR_OUTPUT}" = 'false' ]] || [[ "${COLOR_OUTPUT}" = 'no' ]] || [[ "${COLOR_OUTPUT}" = 0 ]]; then
  COLOR_OUTPUT='false'
else
  COLOR_OUTPUT='true'
fi
