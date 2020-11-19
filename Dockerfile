# syntax = docker/dockerfile:experimental

# takaomag/base
# https://hub.docker.com/_/archlinux/
# https://github.com/archlinux/archlinux-docker/
# https://mirrors.edge.kernel.org/archlinux/iso/latest/

ARG A_FROM_IMAGE=archlinux/base

FROM ${A_FROM_IMAGE}

ARG A_PACMAN_MIRRORLIST_URL="https://www.archlinux.org/mirrorlist/?country=JP&country=US&protocol=https&use_mirror_status=on"
ARG A_INSTALL_BASE_PACKAGES_CMD="pacman -S --needed --noconfirm --noprogressbar base base-devel pacman-contrib sudo openssh reflector git --ignore linux,man-db,man-pages"
ARG A_REQUIRED_PACKAGES="btrfs-progs vi git-lfs github-cli"

LABEL maintainer "takaomag <takaomag@users.noreply.github.com>"

ENV \
  container=docker \
  X_DOCKER_ID=takaomag \
  X_DOCKER_REPO_NAME=base

RUN --mount=type=bind,source=resource/,target=/mnt/x-dockerbuild-resource \
  source /mnt/x-dockerbuild-resource/opt/local/bin/x-set-shell-fonts-env.sh && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Customize shell${FONT_DEFAULT}" && \
  cat /mnt/x-dockerbuild-resource/etc/bash.bashrc >> /etc/bash.bashrc && \
  cat /mnt/x-dockerbuild-resource/etc/bash.bash_logout >> /etc/bash.bash_logout && \
  cat /mnt/x-dockerbuild-resource/etc/skel/.lesskey >> /etc/skel/.lesskey && \
  #
  lesskey -o /etc/skel/.less /etc/skel/.lesskey && \
  chmod 644 /etc/skel/.less* && \
  (! ls -A /etc/skel/.bash* >/dev/null 2>&1 || cp -apr /etc/skel/.bash* /root/.) && \
  (! ls -A /etc/skel/.profile* >/dev/null 2>&1 || cp -apr /etc/skel/.profile* /root/.) && \
  (! ls -A /etc/skel/.less* >/dev/null 2>&1 || cp -apr /etc/skel/.less* /root/.) && \
  (! ls -A /etc/skel/.xprofile >/dev/null 2>&1 || cp -apr /etc/skel/.xprofile /root/.) && \
  #
  cat /mnt/x-dockerbuild-resource/etc/locale.gen > /etc/locale.gen && \
  chmod 644 /etc/locale.gen && \
  locale-gen && \
  locale > /etc/locale.conf && \
  chmod 644 /etc/locale.conf && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Customize shell${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Configure system users${FONT_DEFAULT}" && \
  gpg --list-keys && echo -e "\n# custom\nkeyserver-options auto-key-retrieve\n" >> /root/.gnupg/gpg.conf && \
  chmod 600 /root/.gnupg/gpg.conf && \
  # sed --in-place -e "s/^\(UID_MIN\s\+1000\s*\)$/# custom #\1\nUID_MIN\t\t\t10000/g" /etc/login.defs && \
  # sed --in-place -e "s/^\(UID_MAX\s\+60000\s*\)$/# custom #\1\nUID_MAX\t\t\t19999/g" /etc/login.defs && \
  # sed --in-place -e "s/^\(GID_MIN\s\+1000\s*\)$/# custom #\1\nGID_MIN\t\t\t10000/g" /etc/login.defs && \
  # sed --in-place -e "s/^\(GID_MAX\s\+60000\s*\)$/# custom #\1\nGID_MAX\t\t\t19999/g" /etc/login.defs && \
  systemd-sysusers /mnt/x-dockerbuild-resource/etc/sysusers.d/60-x-base.conf && \
  mkdir --mode=700 /var/lib/x-aur-helper && \
  chown -R x-aur-helper:x-aur-helper /var/lib/x-aur-helper && \
  su - x-aur-helper --shell=/bin/bash -c 'gpg --list-keys' && su - x-aur-helper --shell=/bin/bash -c 'echo -e "\n# custom\nkeyserver-options auto-key-retrieve\n" >> /var/lib/x-aur-helper/.gnupg/gpg.conf' >/dev/null && \
  chmod 600 /var/lib/x-aur-helper/.gnupg/gpg.conf && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Configure system users${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Ensure directories and files${FONT_DEFAULT}" && \
  systemd-tmpfiles --create --clean --remove /mnt/x-dockerbuild-resource/etc/tmpfiles.d/40-x-base.conf && \
  cp /mnt/x-dockerbuild-resource/etc/security/x-system-remote-login.conf /etc/security/x-system-remote-login.conf && \
  chmod 644 /etc/security/x-system-remote-login.conf && \
  cp /mnt/x-dockerbuild-resource/etc/systemd/coredump.conf.d/60-x-base.conf /etc/systemd/coredump.conf.d/60-x-base.conf && \
  chmod 644 /etc/systemd/coredump.conf.d/60-x-base.conf && \
  cp /mnt/x-dockerbuild-resource/etc/systemd/journald.conf.d/60-x-base.conf /etc/systemd/journald.conf.d/60-x-base.conf && \
  chmod 644 /etc/systemd/journald.conf.d/60-x-base.conf && \
  cp /mnt/x-dockerbuild-resource/etc/sysusers.d/60-x-base.conf /etc/sysusers.d/60-x-base.conf && \
  chmod 644 /etc/sysusers.d/60-x-base.conf && \
  cp /mnt/x-dockerbuild-resource/etc/tmpfiles.d/40-x-base.conf /etc/tmpfiles.d/40-x-base.conf && \
  chmod 644 /etc/tmpfiles.d/40-x-base.conf && \
  cp /mnt/x-dockerbuild-resource/opt/local/bin/x-set-shell-fonts-env.sh /opt/local/bin/x-set-shell-fonts-env.sh && \
  chmod 755 /opt/local/bin/x-set-shell-fonts-env.sh && \
  cp /mnt/x-dockerbuild-resource/opt/local/bin/x-archlinux-remove-unnecessary-files.sh /opt/local/bin/x-archlinux-remove-unnecessary-files.sh && \
  chmod 744 /opt/local/bin/x-archlinux-remove-unnecessary-files.sh && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Ensure directories and files${FONT_DEFAULT}" && \
  #
  #
  # echo -e "${FONT_INFO}[INFO] Initialize pacman key${FONT_DEFAULT}" && \
  # rm -rf /etc/pacman.d/gnupg && \
  # pacman-key --init && \
  # pacman-key --populate archlinux && \
  # echo -e "${FONT_SUCCESS}[SUCCESS] Initialize pacman key${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Install base packages and configure pacman${FONT_DEFAULT}" && \
  curl --fail --silent --location -o /etc/pacman.d/mirrorlist "${A_PACMAN_MIRRORLIST_URL}" && \
  sed --in-place -e 's/^#Server/Server/g' /etc/pacman.d/mirrorlist && \
  chmod 644 /etc/pacman.d/mirrorlist && \
  sed --in-place -E 's/^#\s*CheckSpace\s*/CheckSpace/g' /etc/pacman.conf && \
  chmod 644 /etc/pacman.conf && \
  pacman -Syyu --noconfirm --noprogressbar && \
  ${A_INSTALL_BASE_PACKAGES_CMD} && \
  cp /mnt/x-dockerbuild-resource/etc/pacman.d/hooks/x-remove-cache.hook /etc/pacman.d/hooks/x-remove-cache.hook && \
  chmod 644 /etc/pacman.d/hooks/x-remove-cache.hook && \
  mkdir --mode=0755 /etc/systemd/system/timers.target.wants && \
  ln -sf /usr/lib/systemd/system/paccache.timer /etc/systemd/system/timers.target.wants/paccache.timer && \
  reflector --latest 20 --age 24 --country 'United States' --country Japan --protocol https --sort rate --verbose --save /etc/pacman.d/mirrorlist && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Install base packages and configure pacman${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Configure pam${FONT_DEFAULT}" && \
  if ! grep -q -E '^auth\s+required\s+pam_wheel\.so\s+use_uid\s*.*' /etc/pam.d/su;then \
  sed --in-place -E "s/^#(auth\s+required\s+pam_wheel\.so\s+use_uid\s*.*)/\1/g" /etc/pam.d/su; \
  fi && \
  if ! grep -q -E '^account\s+required\s+pam_access\.so\s+.*' /etc/pam.d/system-remote-login;then \
  sed --in-place -E "/^account\s+include\s+system-login\s*$/i# custom >>>\naccount   required  pam_access.so nodefgroup accessfile=/etc/security/x-system-remote-login.conf\n# custom <<<" /etc/pam.d/system-remote-login; \
  fi && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Configure pam${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Configure sudoers${FONT_DEFAULT}" && \
  if ! grep -q --recursive --files-with-matches -m 1 -E '^%wheel\s+ALL=\(ALL\)\s+NOPASSWD:\s*ALL\s*$' /etc/sudoers.d;then \
  if grep -q --recursive --files-with-matches -m 1 -E '^%wheel\s+ALL=\(ALL\)\s+ALL\s*.*' /etc/sudoers.d;then \
  sed --in-place -E "s/^%wheel\s+ALL=\(ALL\)\s+ALL\s*.*/%wheel ALL=(ALL) NOPASSWD: ALL/g" $(grep --recursive --files-with-matches -m 1 -E '^%wheel\s+ALL=\(ALL\)\s+ALL\s*.*' /etc/sudoers.d); \
  else \
  echo -e '# custom >>>\n%wheel ALL=(ALL) NOPASSWD: ALL\n# custom <<<' > /etc/sudoers.d/wheel && \
  chmod 640 /etc/sudoers.d/wheel; \
  fi \
  fi && \
  echo -e '# custom >>>\nx-aur-helper ALL=(ALL) NOPASSWD: ALL\n# custom <<<' > /etc/sudoers.d/x-aur-helper && \
  chmod 640 /etc/sudoers.d/x-aur-helper && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Configure sudoers${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Configure sshd${FONT_DEFAULT}" && \
  echo -e '\n# custom >>>\nInclude /etc/ssh/sshd_config.d/*.conf\n# custom <<<' >> /etc/ssh/sshd_config && \
  mkdir /etc/ssh/sshd_config.d && \
  cp /mnt/x-dockerbuild-resource/etc/ssh/sshd_config.d/60-x-base.conf /etc/ssh/sshd_config.d/60-x-base.conf && \
  chmod 644 /etc/ssh/sshd_config.d/60-x-base.conf && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Configure sshd${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Configure /root/.ssh${FONT_DEFAULT}" && \
  mkdir -p /root/.ssh/conf.d && \
  cp /mnt/x-dockerbuild-resource/root/.ssh/config /root/.ssh/config && \
  cp /mnt/x-dockerbuild-resource/root/.ssh/conf.d/zz-default.conf /root/.ssh/conf.d/zz-default.conf && \
  find /root/.ssh -type d -print0 | xargs -0 --no-run-if-empty chmod 700 && \
  find /root/.ssh -type f -print0 | xargs -0 --no-run-if-empty chmod 600 && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Configure /root/.ssh${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Install [yay]${FONT_DEFAULT}" && \
  cd /var/tmp && \
  curl --fail --silent --location --retry 5 https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz | tar xz && \
  chown -R x-aur-helper:x-aur-helper yay-bin && \
  cd yay-bin && \
  sudo -u x-aur-helper makepkg --syncdeps --install --clean --noconfirm --noprogressbar && \
  cd .. && rm -rf yay-bin && \
  mkdir -p --mode=700 /root/.config/yay && sudo -u x-aur-helper mkdir -p --mode=700 /var/lib/x-aur-helper/.config/yay && \
  chmod 700 /root/.config && chmod 700 /var/lib/x-aur-helper/.config && \
  echo '{"cleanAfter": true}' > /root/.config/yay/config.json && echo '{"cleanAfter": true}' | sudo -u x-aur-helper tee /var/lib/x-aur-helper/.config/yay/config.json >/dev/null && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Install [yay]${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Install [${A_REQUIRED_PACKAGES}]${FONT_DEFAULT}" && \
  sudo -u x-aur-helper yay -S --needed --noconfirm --noprogressbar ${A_REQUIRED_PACKAGES} && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Install [${A_REQUIRED_PACKAGES}]${FONT_DEFAULT}" && \
  #
  #
  # echo -e "${FONT_INFO}[INFO] Get wait-for-it${FONT_DEFAULT}" && \
  # curl --fail --silent --location -o /opt/local/bin/wait-for-it.sh https://raw.githubusercontent.com/takaomag/wait-for-it/master/wait-for-it.sh && \
  # chmod 755 /opt/local/bin/wait-for-it.sh && \
  # echo -e "${FONT_SUCCESS}[SUCCESS] Get wait-for-it${FONT_DEFAULT}" && \
  #
  #
  echo -e "${FONT_INFO}[INFO] Configure project directory${FONT_DEFAULT}" && \
  chown -R root:developer /opt/project && \
  find /opt/project -type d -print0 | xargs -0 --no-run-if-empty chmod g+rwxs && \
  # find /opt/project -type f -print0 | xargs -0 --no-run-if-empty chmod g+rw && \
  setfacl -R --remove-all /opt/project && \
  setfacl -R -m default:group::rwx,default:other:rx /opt/project && \
  echo -e "${FONT_SUCCESS}[SUCCESS] Configure project directory${FONT_DEFAULT}" && \
  #
  #
  /opt/local/bin/x-archlinux-remove-unnecessary-files.sh --paccache-keep-num 0 --remove-tmp && \
  (find /tmp -mindepth 1 -delete || true) && \
  (find /var/tmp -mindepth 1 -delete || true) && \
  rm -f /etc/hostname && \
  rm -f /etc/machine-id && \
  (find /etc/pacman.d/gnupg/openpgp-revocs.d -mindepth 1 -delete || true) && \
  (find /etc/pacman.d/gnupg/private-keys-v1.d -mindepth 1 -delete || true) && \
  rm -rf /etc/pacman.d/gnupg/pubring.gpg~ && \
  rm -rf /etc/pacman.d/gnupg/S.* && \
  (find /var/cache/pacman/pkg -mindepth 1 -delete || true) && \
  (find /var/lib/pacman/sync -mindepth 1 -delete || true) && \
  sync && sync && sync

# WORKDIR /var/tmp
