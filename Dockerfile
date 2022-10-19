# syntax=docker/dockerfile-upstream:master-labs
## syntax=docker/dockerfile:1.3-labs

# takaomag/base
# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md
# https://hub.docker.com/_/archlinux/
# https://github.com/archlinux/archlinux-docker/
# https://mirrors.edge.kernel.org/archlinux/iso/latest/

ARG A_FROM_IMAGE=quay.io/takaomag/archlinux:latest

FROM ${A_FROM_IMAGE}

## platform of the build result. Eg linux/amd64, linux/arm/v7, windows/amd64.
# ARG TARGETPLATFORM
## OS component of TARGETPLATFORM
# ARG TARGETOS
## architecture component of TARGETPLATFORM
ARG TARGETARCH
## variant component of TARGETPLATFORM
# ARG TARGETVARIANT
##platform of the node performing the build.
# ARG BUILDPLATFORM
## OS component of BUILDPLATFORM
# ARG BUILDOS
## architecture component of BUILDPLATFORM
# ARG BUILDARCH
## variant component of BUILDPLATFORM
# ARG BUILDVARIANT

ARG A_AMD64_PACMAN_MIRRORLIST_URL="https://www.archlinux.org/mirrorlist/?country=US&country=JP&protocol=https&use_mirror_status=on"
ARG A_INSTALL_BASE_PACKAGES_CMD="pacman -S --needed --noprogressbar --noconfirm base base-devel pacman-contrib sudo openssh vi which --ignore linux,man-db,man-pages"
ARG A_EXTRA_PACKAGES="vi git"

LABEL maintainer "takaomag <takaomag@users.noreply.github.com>"

ENV \
  container=docker

RUN --mount=type=bind,source=resource/,target=/mnt/x-dockerbuild-resource <<EODF
echo "2016-03-03-0" > /dev/null
set -eo pipefail
source /mnt/x-dockerbuild-resource/opt/local/bin/x-set-shell-fonts-env.sh
export TERM=dumb
export LANG='en_US.UTF-8'

if [[ -z "${TARGETARCH}" ]]; then
  msg_error "[ERROR] `TARGETARCH` is not set. Enable buildkit."
  echo
  exit 1
fi

update_alarm_pacman_mirrorlist() {
  ## `tw.mirror.archlinuxarm.org`がよくアクセス不能になる。
  ## https://archlinuxarm.org/about/mirrors
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/.org.mirrorlist
  cat <<-'HEND' >/etc/pacman.d/mirrorlist
#
# Arch Linux ARM repository mirrorlist
#
HEND
  echo -e '\n### United States' >>/etc/pacman.d/mirrorlist
  awk '/^#+\s+[Uu]nited [Ss]tates\s*/{f=1; next}f==0{next}/^$/{exit}{print substr($0, 1);}' /etc/pacman.d/.org.mirrorlist >>/etc/pacman.d/mirrorlist
  echo -e '\n### Japan' >>/etc/pacman.d/mirrorlist
  awk '/^#+\s+[Jj]apan\s*/{f=1; next}f==0{next}/^$/{exit}{print substr($0, 1);}' /etc/pacman.d/.org.mirrorlist >>/etc/pacman.d/mirrorlist
  echo -e '\n### Australia' >>/etc/pacman.d/mirrorlist
  awk '/^#+\s+[Aa]ustralia\s*/{f=1; next}f==0{next}/^$/{exit}{print substr($0, 1);}' /etc/pacman.d/.org.mirrorlist >>/etc/pacman.d/mirrorlist
  echo -e '\n### United Kingdom' >>/etc/pacman.d/mirrorlist
  awk '/^#+\s+[Uu]nited [Kk]ingdom\s*/{f=1; next}f==0{next}/^$/{exit}{print substr($0, 1);}' /etc/pacman.d/.org.mirrorlist >>/etc/pacman.d/mirrorlist
  sed --in-place -E 's/^#+\s*Server\s*=/Server =/g' /etc/pacman.d/mirrorlist
}

msg_info "[INFO] Change DNS resolver configurations"
sed --in-place -E 's/^hosts:.+/hosts: files myhostname dns/g' /etc/nsswitch.conf
# if ! grep -q -E '^options\s+.*' /etc/resolv.conf;then
# cat <<-'HEND' >> /etc/resolv.conf
#
# options use-vc
# HEND
# elif ! grep -q -E '^options\s+.*use-vc.*' /etc/resolv.conf;then
#   sed --in-place -E 's/^(options\s+.*)/\1 use-vc\n/g' /etc/resolv.conf
# fi
msg_success "[SUCCESS] Change DNS resolver configurations"


msg_info "[INFO] Customize shell"
cat /mnt/x-dockerbuild-resource/etc/bash.bashrc >> /etc/bash.bashrc
chmod 0644 /etc/bash.bashrc

cat /mnt/x-dockerbuild-resource/etc/bash.bash_logout >> /etc/bash.bash_logout
chmod 0644 /etc/bash.bash_logout

cat /mnt/x-dockerbuild-resource/etc/skel/.bash_completion > /etc/skel/.bash_completion
chmod 0644 /etc/skel/.bash_completion
mkdir -p --mode=0700 /etc/skel/.bash_completion.d

cat /mnt/x-dockerbuild-resource/etc/skel/.bash_profile >> /etc/skel/.bash_profile
chmod 0644 /etc/skel/.bash_profile

cat /mnt/x-dockerbuild-resource/etc/skel/.profile > /etc/skel/.profile
chmod 0644 /etc/skel/.profile
mkdir -p --mode=0700 /etc/skel/.profile.d

cat /mnt/x-dockerbuild-resource/etc/skel/.lesskey > /etc/skel/.lesskey
chmod 0644 /etc/skel/.lesskey

lesskey -o /etc/skel/.less /etc/skel/.lesskey
chmod 0644 /etc/skel/.less*

for u in 'root'; do
  d="$(getent passwd ${u} | cut -d: -f6)"
  ! ls -A /etc/skel/.bash* >/dev/null 2>&1 || cp -apr /etc/skel/.bash* "${d}/."
  ! ls -A /etc/skel/.profile* >/dev/null 2>&1 || cp -apr /etc/skel/.profile* "${d}/."
  ! ls -A /etc/skel/.less* >/dev/null 2>&1 || cp -apr /etc/skel/.less* ${d}/.
  ! ls -A /etc/skel/.xprofile >/dev/null 2>&1 || cp -apr /etc/skel/.xprofile "${d}/."
  chown -R "${u}":"${u}" "${d}"
done
mkdir -p --mode=0700 \
  /etc/skel/.config \
  /etc/skel/.config/gcloud \
  /etc/skel/.aws

cat /mnt/x-dockerbuild-resource/etc/locale.gen > /etc/locale.gen
chmod 644 /etc/locale.gen
locale-gen
locale > /etc/locale.conf
chmod 644 /etc/locale.conf
msg_success "[SUCCESS] Customize shell"


msg_info "[INFO] Configure system users"
gpg --list-keys
cat <<-'HEND' >> /root/.gnupg/gpg.conf

# custom
keyserver-options auto-key-retrieve
HEND
chmod 600 /root/.gnupg/gpg.conf
# sed --in-place -e "s/^\(UID_MIN\s\+1000\s*\)$/# custom #\1\nUID_MIN\t\t\t10000/g" /etc/login.defs
# sed --in-place -e "s/^\(UID_MAX\s\+60000\s*\)$/# custom #\1\nUID_MAX\t\t\t19999/g" /etc/login.defs
# sed --in-place -e "s/^\(GID_MIN\s\+1000\s*\)$/# custom #\1\nGID_MIN\t\t\t10000/g" /etc/login.defs
# sed --in-place -e "s/^\(GID_MAX\s\+60000\s*\)$/# custom #\1\nGID_MAX\t\t\t19999/g" /etc/login.defs
systemd-sysusers /mnt/x-dockerbuild-resource/etc/sysusers.d/60-x-base.conf
mkdir --mode=700 /var/lib/x-aur-helper
chown -R x-aur-helper:x-aur-helper /var/lib/x-aur-helper
su - x-aur-helper --shell=/bin/bash -c 'gpg --list-keys'
su - x-aur-helper --shell=/bin/bash -c 'echo -e "\n# custom\nkeyserver-options auto-key-retrieve" >> /var/lib/x-aur-helper/.gnupg/gpg.conf' >/dev/null
chmod 600 /var/lib/x-aur-helper/.gnupg/gpg.conf
msg_success "[SUCCESS] Configure system users"


msg_info "[INFO] Ensure directories and files"
systemd-tmpfiles --create --clean --remove /mnt/x-dockerbuild-resource/etc/tmpfiles.d/40-x-base.conf
cp /mnt/x-dockerbuild-resource/etc/security/x-system-remote-login.conf /etc/security/.
chmod 644 /etc/security/x-system-remote-login.conf
cp /mnt/x-dockerbuild-resource/etc/systemd/coredump.conf.d/60-x-base.conf /etc/systemd/coredump.conf.d/.
chmod 644 /etc/systemd/coredump.conf.d/60-x-base.conf
cp /mnt/x-dockerbuild-resource/etc/systemd/journald.conf.d/60-x-base.conf /etc/systemd/journald.conf.d/.
chmod 644 /etc/systemd/journald.conf.d/60-x-base.conf
cp /mnt/x-dockerbuild-resource/etc/sysusers.d/60-x-base.conf /etc/sysusers.d/.
chmod 644 /etc/sysusers.d/60-x-base.conf
cp /mnt/x-dockerbuild-resource/etc/tmpfiles.d/40-x-base.conf /etc/tmpfiles.d/.
chmod 644 /etc/tmpfiles.d/40-x-base.conf
cp /mnt/x-dockerbuild-resource/opt/local/bin/x-set-shell-fonts-env.sh /opt/local/bin/.
chmod 755 /opt/local/bin/x-set-shell-fonts-env.sh
cp /mnt/x-dockerbuild-resource/opt/local/bin/x-archlinux-remove-unnecessary-files.sh /opt/local/bin/.
chmod 744 /opt/local/bin/x-archlinux-remove-unnecessary-files.sh
msg_success "[SUCCESS] Ensure directories and files"


# msg_info "[INFO] Initialize pacman key"
# rm -rf /etc/pacman.d/gnupg
# pacman-key --init
# pacman-key --populate archlinux
# msg_success "[SUCCESS] Initialize pacman key"

msg_info "[INFO] Update certificates"
update-ca-trust
msg_success "[SUCCESS] Update certificates"

msg_info "[INFO] Install base packages and configure pacman"
if [[ "${TARGETARCH}" == 'amd64' ]];then
  curl --fail --silent --location -o /etc/pacman.d/mirrorlist "${A_AMD64_PACMAN_MIRRORLIST_URL}"
  sed --in-place -E 's/^#+\s*Server\s*=/Server =/g' /etc/pacman.d/mirrorlist
elif [[ "${TARGETARCH}" == 'arm64' ]];then
  update_alarm_pacman_mirrorlist
fi

chmod 644 /etc/pacman.d/mirrorlist
sed --in-place -E 's/^#\s*NoProgressBar\s*/NoProgressBar/g' /etc/pacman.conf
# sed --in-place -E 's/^#\s*CheckSpace\s*/CheckSpace/g' /etc/pacman.conf
sed --in-place -E 's/^CheckSpace\s*/#CheckSpace/g' /etc/pacman.conf
sed --in-place -E 's/^#\s*VerbosePkgLists\s*/VerbosePkgLists/g' /etc/pacman.conf
sed --in-place -E 's/^#\s*(ParallelDownloads\s*=.+)/\1/g' /etc/pacman.conf
if ! grep -E '^NoExtract\s*=' /etc/pacman.conf;then
  cat /mnt/x-dockerbuild-resource/etc/pacman.conf >> /etc/pacman.conf
fi
chmod 644 /etc/pacman.conf
# [[ -e /etc/mtab ]] || ln -sf /proc/mounts /etc/mtab
pacman -Syyu --noprogressbar --noconfirm

if [[ "${TARGETARCH}" == 'arm64' ]] && [[ -e /etc/pacman.d/mirrorlist.pacnew ]]; then
  mv /etc/pacman.d/mirrorlist.pacnew /etc/pacman.d/mirrorlist
  update_alarm_pacman_mirrorlist
fi
${A_INSTALL_BASE_PACKAGES_CMD}

cp /mnt/x-dockerbuild-resource/etc/pacman.d/hooks/x-remove-cache.hook /etc/pacman.d/hooks/.
chmod 644 /etc/pacman.d/hooks/x-remove-cache.hook
mkdir -p --mode=0755 /etc/systemd/system/timers.target.wants
ln -sf /usr/lib/systemd/system/paccache.timer /etc/systemd/system/timers.target.wants/paccache.timer

if [[ "${TARGETARCH}" == 'amd64' ]];then
  pacman -S --needed --noprogressbar --noconfirm reflector
  reflector --latest 20 --age 240 --country 'United States',Japan --protocol https --sort score --verbose --save /etc/pacman.d/mirrorlist
fi
msg_success "[SUCCESS] Install base packages and configure pacman"


msg_info "[INFO] Configure pam"
if ! grep -q -E '^auth\s+required\s+pam_wheel\.so\s+use_uid\s*.*' /etc/pam.d/su;then
  sed --in-place -E "s/^#(auth\s+required\s+pam_wheel\.so\s+use_uid\s*.*)/\1/g" /etc/pam.d/su
fi
if ! grep -q -E '^account\s+required\s+pam_access\.so\s+.*' /etc/pam.d/system-remote-login;then
  sed --in-place -E "/^account\s+include\s+system-login\s*$/i# custom >>>\naccount   required  pam_access.so nodefgroup accessfile=/etc/security/x-system-remote-login.conf\n# custom <<<" /etc/pam.d/system-remote-login
fi
msg_success "[SUCCESS] Configure pam"


msg_info "[INFO] Configure sudoers"
if ! grep -q --recursive --files-with-matches -m 1 -E '^%wheel\s+ALL=\(ALL\)\s+NOPASSWD:\s*ALL\s*$' /etc/sudoers.d;then
  if grep -q --recursive --files-with-matches -m 1 -E '^%wheel\s+ALL=\(ALL\)\s+ALL\s*.*' /etc/sudoers.d;then
    sed --in-place -E "s/^%wheel\s+ALL=\(ALL\)\s+ALL\s*.*/%wheel ALL=(ALL) NOPASSWD: ALL/g" $(grep --recursive --files-with-matches -m 1 -E '^%wheel\s+ALL=\(ALL\)\s+ALL\s*.*' /etc/sudoers.d)
  else
    cat <<-'HEND' > /etc/sudoers.d/wheel
# custom >>>
%wheel ALL=(ALL) NOPASSWD: ALL
# custom <<<
HEND
    chmod 640 /etc/sudoers.d/wheel
  fi
fi
cat <<-'HEND' > /etc/sudoers.d/x-aur-helper
# custom >>>
x-aur-helper ALL=(ALL) NOPASSWD: ALL
# custom <<<
HEND
chmod 640 /etc/sudoers.d/x-aur-helper
msg_success "[SUCCESS] Configure sudoers"


msg_info "[INFO] Configure sshd"
cat <<-'HEND' >> /etc/ssh/sshd_config

# custom >>>
Include /etc/ssh/sshd_config.d/*.conf
# custom <<<
HEND
mkdir -p /etc/ssh/sshd_config.d
cp /mnt/x-dockerbuild-resource/etc/ssh/sshd_config.d/60-x-base.conf /etc/ssh/sshd_config.d/.
chmod 644 /etc/ssh/sshd_config.d/60-x-base.conf
msg_success "[SUCCESS] Configure sshd"


msg_info "[INFO] Configure /root/.ssh"
for u in 'root'; do
  d="$(getent passwd ${u} | cut -d: -f6)"
  mkdir -p "${d}/.ssh/conf.d"
  cp /mnt/x-dockerbuild-resource/root/.ssh/config "${d}/.ssh/."
  cp /mnt/x-dockerbuild-resource/root/.ssh/conf.d/zz-default.conf "${d}/.ssh/conf.d/."
  find "${d}/.ssh" -type d -print0 | xargs -0 --no-run-if-empty chmod 0700
  find "${d}/.ssh" -type f -print0 | xargs -0 --no-run-if-empty chmod 0600
  chown -R "${u}":"${u}" "${d}/.ssh"
done
cp -apr /root/.ssh /etc/skel/.
msg_success "[SUCCESS] Configure /root/.ssh"


msg_info "[INFO] Install [yay]"
if [[ "${TARGETARCH}" == 'amd64' ]];then
  cd /var/tmp
  curl --fail --silent --location --retry 5 https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz | tar xz
  chown -R x-aur-helper:x-aur-helper yay-bin
  cd yay-bin
  sudo -u x-aur-helper makepkg --syncdeps --install --clean --rmdeps --needed --noprogressbar --noconfirm
  cd .. && rm -rf yay-bin
elif [[ "${TARGETARCH}" == 'arm64' ]];then
  # sudo -u x-aur-helper git clone https://aur.archlinux.org/yay.git /var/tmp/yay
  # cd /var/tmp/yay
  cd /var/tmp
  curl --fail --silent --location --retry 5 https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz | tar xz
  chown -R x-aur-helper:x-aur-helper yay
  cd yay
  sudo -u x-aur-helper makepkg --syncdeps --install --clean --rmdeps --needed --noprogressbar --noconfirm
  cd .. && rm -rf yay
fi
rm -rf /var/lib/x-aur-helper/.cache/go-build
for u in 'root' 'x-aur-helper'; do
  d="$(getent passwd ${u} | cut -d: -f6)"
  mkdir -p --mode=0700 "${d}/.config" "${d}/.config/yay"
  tee "${d}/.config/yay/config.json" <<-'HEND' >/dev/null
{"cleanAfter": true}
HEND
  chmod 0644 "${d}/.config/yay/config.json"
  chown -R "${u}":"${u}" "${d}/.config"
done
cp -apr /root/.config/yay /etc/skel/.config/.
msg_success "[SUCCESS] Install [yay]"


msg_info "[INFO] Install [${A_EXTRA_PACKAGES}]"
sudo -u x-aur-helper yay -S --needed --removemake --cleanafter --noprogressbar --noconfirm ${A_EXTRA_PACKAGES}
msg_success "[SUCCESS] Install [${A_EXTRA_PACKAGES}]"


# msg_info "[INFO] Get wait-for-it"
# curl --fail --silent --location -o /opt/local/bin/wait-for-it.sh https://raw.githubusercontent.com/takaomag/wait-for-it/master/wait-for-it.sh
# chmod 755 /opt/local/bin/wait-for-it.sh
# msg_success "[SUCCESS] Get wait-for-it"


msg_info "[INFO] Configure project directory"
setfacl -R --remove-all /opt/project
setfacl -R -m default:group::rwx,default:other:rx /opt/project
chown -R root:developer /opt/project
find /opt/project -type d -print0 | xargs -0 --no-run-if-empty chmod g+rwxs
# find /opt/project -type f -print0 | xargs -0 --no-run-if-empty chmod g+rw
msg_success "[SUCCESS] Configure project directory"

msg_info "[INFO] Finalize"
for u in 'root' 'x-aur-helper'; do
  d="$(getent passwd ${u} | cut -d: -f6)"
  rm -rf "${d}/.cache/go-build"
  rm -f "${d}/.pip/pip.log"
  rm -rf "${d}/.cache/pip"
  rm -f "${d}/.*_history"
  rm -f "${d}/.*hist"
  rm -rf "${d}/.m2/repository"
  # rm -rf "${d}/.m2"
  rm -rf "${d}/.ivy2/cache"
  # rm -rf "${d}/.ivy2"
  rm -rf "${d}/.gradle/caches"
  rm -rf "${d}/.gradle"
done

/opt/local/bin/x-archlinux-remove-unnecessary-files.sh --paccache-keep-num 0 --remove-tmp
# pacman-optimize
find / -type f -name "*.pacsave" -delete || true
# rm -f /.dockerenv
# rm -f /.dockerinit
rm -f /etc/hostname
rm -f /etc/machine-id
## https://github.com/archlinux/archlinux-docker/blob/master/Makefile
rm -rf /etc/pacman.d/gnupg/{openpgp-revocs.d/,private-keys-v1.d/,pubring.gpg~,gnupg.S.}*
rm -rf /etc/pacman.d/gnupg/S.gpg-agent*
rm -f /etc/ssh/ssh_host_*
# find /usr/share/man -mindepth 1 -delete || true
find /var/cache/pacman/pkg -mindepth 1 -delete || true
find /var/lib/pacman/sync -mindepth 1 -delete || true
msg_success "[SUCCESS] Finalize"
EODF

# WORKDIR /var/tmp
