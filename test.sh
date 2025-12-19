#!/usr/bin/env bash

hardware="hardware"
extra="none"

dnf install -y cmake make pkgconf-pkg-config gcc-c++ systemd-devel libbpf-devel elfutils-libelf-devel clang llvm kernel-headers bpftool
git clone --depth 1 https://gitlab.com/ananicy-cpp/ananicy-cpp.git
cd ananicy-cpp
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_SYSTEMD=ON -DUSE_BPF_PROC_IMPL=ON -DWITH_BPF=ON
cmake --build build --target ananicy-cpp
cmake --install build --component Runtime

# Setup gruvbox theme
THEME_SRC="/home/piyush/Documents/personal/default/GruvboxQT"
THEME_DEST="/usr/share/Kvantum/Gruvbox"
mkdir -p "$THEME_DEST"
cp "$THEME_SRC/gruvbox-kvantum.kvconfig" "$THEME_DEST/Gruvbox.kvconfig"
cp "$THEME_SRC/gruvbox-kvantum.svg" "$THEME_DEST/Gruvbox.svg"

THEME_SRC="/home/piyush/Documents/personal/default/GruvboxGtk"
THEME_DEST="/usr/share"
cp -r "$THEME_SRC/themes/Gruvbox-Material-Dark" "$THEME_DEST/themes"
cp -r "$THEME_SRC/icons/Gruvbox-Material-Dark" "$THEME_DEST/icons"

# Anancy-cpp rules
git clone --depth=1 https://github.com/RogueScholar/ananicy.git
git clone --depth=1 https://github.com/CachyOS/ananicy-rules.git
mkdir -p /etc/ananicy.d/roguescholar /etc/ananicy.d/zz-cachyos
cp -r ananicy/ananicy.d/* /etc/ananicy.d/roguescholar/
cp -r ananicy-rules/00-default/* /etc/ananicy.d/zz-cachyos/
cp -r ananicy-rules/00-types.types /etc/ananicy.d/zz-cachyos/
cp -r ananicy-rules/00-cgroups.cgroups /etc/ananicy.d/zz-cachyos/
tee /etc/ananicy.d/ananicy.conf >/dev/null <<'EOF'
check_freq = 15
cgroup_load = false
type_load = true
rule_load = true
apply_nice = true
apply_latnice = true
apply_ionice = true
apply_sched = true
apply_oom_score_adj = true
apply_cgroup = true
loglevel = info
log_applied_rule = false
cgroup_realtime_workaround = false
EOF

# Firefox policy
mkdir -p /etc/firefox/policies
ln -sf "/home/piyush/Documents/personal/default/dotfiles/policies.json" /etc/firefox/policies/policies.json

# zram config
# Get total memory in MiB
TOTAL_MEM=$(awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo)
ZRAM_SIZE=$((TOTAL_MEM / 2))

# Create zram config
mkdir -p /etc/systemd/zram-generator.conf.d
{
  echo "[zram0]"
  echo "zram-size = ${ZRAM_SIZE}"
  echo "compression-algorithm = zstd"
  echo "swap-priority = 100"
  echo "fs-type = swap"
} >/etc/systemd/zram-generator.conf.d/00-zram.conf

# Services
# rfkill unblock bluetooth
# modprobe btusb || true
if [[ "$hardware" == "hardware" ]]; then
  systemctl enable fstrim.timer acpid libvirtd.socket cups ipp-usb docker.socket
  systemctl disable dnsmasq
fi
if [[ "$extra" == "laptop" || "$extra" == "bluetooth" ]]; then
  systemctl enable bluetooth
fi
if [[ "$extra" == "laptop" ]]; then
  systemctl enable tlp
fi
systemctl enable NetworkManager NetworkManager-dispatcher ananicy-cpp
systemctl mask systemd-rfkill systemd-rfkill.socket
systemctl disable NetworkManager-wait-online.service

# cleanup
dnf remove plymouth
