# Anycubic Kobra S1 – MCU Socat Bridge Services

This project provides a simple installer to create two `systemd` services that bridge virtual serial devices to an Anycubic Kobra S1 over TCP using `socat`.

---

## 📦 Features

* Creates two virtual serial devices:

  * `/dev/ttyMCU1` → Printer Port `7003`
  * `/dev/ttyMCU2` → Printer Port `7005`
* Automatically installs `socat` if missing
* Prompts for printer IP during installation
* Runs as persistent `systemd` services
* Automatically restarts on failure

---

## ⚙️ Requirements

* Linux system with `systemd`
* Root access (`sudo`)
* Network access to the printer
* Anycubic Kobra S1 with accessible TCP ports:

  * `7003`
  * `7005`

---

## 🚀 Installation Raspberry or other Klipper Device (Recommended)

Download and run the installer with one command:

```bash
wget https://raw.githubusercontent.com/moosbewohner/Kobra-S1-Lan-Tunnel/main/mcu_service_install.sh -O install_mcu_services.sh && chmod +x install_mcu_services.sh && sudo ./install_mcu_services.sh
```

---

## 🔧 Alternative Installation (Step-by-step)

```bash
wget https://raw.githubusercontent.com/moosbewohner/Kobra-S1-Lan-Tunnel/main/mcu_service_install.sh
chmod +x mcu_service_install.sh
sudo ./mcu_service_install.sh
```

---

## 🔧 Services

### mcu1.service

* Device: `/dev/ttyMCU1`
* Port: `7003`

### mcu2.service

* Device: `/dev/ttyMCU2`
* Port: `7005`

---

## 📂 Service Location

```bash
/etc/systemd/system/mcu1.service
/etc/systemd/system/mcu2.service
```

---

## ▶️ Service Management

Check status:

```bash
systemctl status mcu1
systemctl status mcu2
```

Restart services:

```bash
systemctl restart mcu1
systemctl restart mcu2
```

Stop services:

```bash
systemctl stop mcu1
systemctl stop mcu2
```

Disable autostart:

```bash
systemctl disable mcu1
systemctl disable mcu2
```

---

## 🔍 Logs

```bash
journalctl -u mcu1 -f
journalctl -u mcu2 -f
```

---

## 🧪 Testing

```bash
ls -l /dev/ttyMCU*
```

Expected:

* `/dev/ttyMCU1`
* `/dev/ttyMCU2`

---

## ⚠️ Troubleshooting

### Device not created

* Check service status
* Verify IP address
* Ensure `socat` is installed

### Connection refused

* Printer offline or wrong IP
* Ports `7003` / `7005` not reachable

### Permission issues

```bash
sudo usermod -aG dialout $USER
```

---

## 🧹 Uninstall

```bash
sudo systemctl stop mcu1 mcu2
sudo systemctl disable mcu1 mcu2
sudo rm /etc/systemd/system/mcu1.service
sudo rm /etc/systemd/system/mcu2.service
sudo systemctl daemon-reload
```

---

## 📜 License

MIT License

---

## 💡 Notes

* Services automatically recreate devices on restart
* Symlinks are cleaned on stop
* Designed for stable long-term operation

---
