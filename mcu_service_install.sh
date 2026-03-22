#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Anycubic Kobra S1 - MCU socat service installer
# Installs:
#   - mcu1.service (/dev/ttyMCU1 -> port 7003)
#   - mcu2.service (/dev/ttyMCU2 -> port 7005)
# =========================================================

SERVICE1="/etc/systemd/system/mcu1.service"
SERVICE2="/etc/systemd/system/mcu2.service"

# -----------------------------
# Check for root
# -----------------------------
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

# -----------------------------
# Check if socat exists
# -----------------------------
if ! command -v socat >/dev/null 2>&1; then
    echo "socat not found. Installing..."
    apt update
    apt install -y socat
fi

# -----------------------------
# Ask for IP
# -----------------------------
read -rp "Enter the IP address of the printer: " PRINTER_IP

# Validate IP
if ! [[ "${PRINTER_IP}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Invalid IP format!"
    exit 1
fi

echo "Using IP: ${PRINTER_IP}"

# -----------------------------
# Create mcu1.service
# -----------------------------
cat > "$SERVICE1" <<EOF
[Unit]
Description=Socat PTY bridge (/dev/ttyMCU1 -> ${PRINTER_IP}:7003)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/socat -d -d \\
  PTY,link=/dev/ttyMCU1,raw,echo=0,mode=660,group=dialout,wait-slave \\
  TCP:${PRINTER_IP}:7003,nodelay,keepalive,forever,interval=1
Restart=always
RestartSec=1
ExecStopPost=/bin/rm -f /dev/ttyMCU1
SyslogIdentifier=socat-ttyMCU1

[Install]
WantedBy=multi-user.target
EOF

# -----------------------------
# Create mcu2.service
# -----------------------------
cat > "$SERVICE2" <<EOF
[Unit]
Description=Socat PTY bridge (/dev/ttyMCU2 -> ${PRINTER_IP}:7005)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/socat -d -d \\
  PTY,link=/dev/ttyMCU2,raw,echo=0,mode=660,group=dialout,wait-slave \\
  TCP:${PRINTER_IP}:7005,nodelay,keepalive,forever,interval=1
Restart=always
RestartSec=1
ExecStopPost=/bin/rm -f /dev/ttyMCU2
SyslogIdentifier=socat-ttyMCU2

[Install]
WantedBy=multi-user.target
EOF

# -----------------------------
# Reload + enable services
# -----------------------------
systemctl daemon-reload
systemctl enable --now mcu1.service
systemctl enable --now mcu2.service

# -----------------------------
# Done
# -----------------------------
echo
echo "Installation completed!"
echo
echo "Check status:"
echo "  systemctl status mcu1"
echo "  systemctl status mcu2"
