#!/bin/bash

set -eu

ROOTFS=$1

# configure autologin inside chroot
chroot "$ROOTFS" /bin/bash <<'EOF'
set -eu
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOC > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noclear --autologin macmind %I $TERM
Type=idle
EOC
EOF