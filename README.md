# Anycubic Kobra S1 – USB and LAN Tunnel Setup

Configure USB gadget serial ports, LAN socat bridges, or both on the Raspberry Pi / Klipper host. Run this installer on the **Pi, not on the printer**.

## Tunnel selection

The installer asks:

```text
1) USB tunnel
2) LAN tunnel
3) All / Alle (USB + LAN)
```

| Selection | Setup | Autostart service |
| --- | --- | --- |
| USB | Original USB gadget with three ACM serial channels | `ports.service` |
| LAN | Three socat bridges in one shared service | `klipper_lan.service` |
| All | USB gadget and all three LAN bridges | Both services |

For LAN or All, enter the printer's **wired Ethernet IPv4 address**. MCU LAN tunnels must use wired LAN, not Wi-Fi. The installer validates the address format; it cannot verify which printer interface owns it. Use a stable address or router DHCP reservation.

Selecting one option does not disable previously installed services from another option. Installing both transports does not automatically switch Klipper between them: select exactly one serial path per MCU in `printer.cfg`.

## Requirements

- Debian-based Linux host with systemd, Bash, sudo/root access and Internet access for packages and Git repositories.
- A printer already prepared for external Klipper, with the matching printer-side USB or LAN tunnel enabled. This script does not install printer firmware or configure the printer side.
- For USB: a supported USB gadget controller and suitable data connection. Board choices: Raspberry Pi 4/5, CM4/CM5, Zero 2 W, BTT Pi2/CB2. Board selection is skipped for LAN-only setup.
- For LAN: printer-side TCP ports 7003 and 7005. Port 7007 is reserved for a future third MCU and requires a matching printer-side bridge before use.
- Run while the printer is idle: the selected tunnel services are restarted during setup.

## Prepare the printer first: install the matching SWU with Rinkhals

Before setting up the Pi tunnels, **install the SWU file matching your printer model on the printer running Rinkhals**. The Pi installer does not perform this step. Use the Rinkhals SWU installation procedure for your device.

| Printer model | Printer-side LAN tunnel package |
| --- | --- |
| Kobra S1 | [app-lan_tunnel-ks1.swu](app-lan_tunnel-ks1.swu) |
| Kobra 2 Pro / Kobra 3 | [app-lan_tunnel-k2p-k3.swu](app-lan_tunnel-k2p-k3.swu) |
| Kobra 3 Max | [app-lan_tunnel-k3m.swu](app-lan_tunnel-k3m.swu) |

These packages provide the printer-side **LAN tunnel**. For USB, install the corresponding printer-side USB tunnel package from the [USB tunnel project: vanilla-klipper-swu](https://github.com/Kobra-S1/vanilla-klipper-swu); selecting USB or All on the Pi does not install a printer-side SWU. Choose the package for your exact model and intended transport.

After installing and enabling the corresponding printer-side tunnel, run the Pi installer below. MCU3/port 7007 in the Pi installer is reserved; these SWU packages are not thereby guaranteed to provide a third MCU bridge.

## Installation

```bash
wget https://raw.githubusercontent.com/moosbewohner/Kobra-S1-Lan-Tunnel/main/mcu_service_install.sh
sudo bash mcu_service_install.sh
```

To skip launching the interactive KIAUH interface:

```bash
sudo SKIP_KIAUH=1 bash mcu_service_install.sh
```

This flag only skips the interactive launch. The original KIAUH setup still runs: Git/KIAUH installation, Kobra-S1 fork configuration and migration of an existing official Klipper checkout to the Kobra-S1 fork. The installer does **not** modify `klipper.service`.

USB setup retains the original `/opt/ports.sh` and `ports.service` configuration. A reboot may be needed to activate the board's USB gadget controller after boot configuration changes.

## Existing installations

Existing independent `mcu1.service`, `mcu2.service` or `mcu3.service` units are detected before setup changes, and LAN installation stops to prevent duplicate bridges. Migrate these old units before choosing LAN or All. Preserve their configurations, disable/stop the independent units and remove their active unit files only after confirming they belong to the old installer; then reload systemd and rerun setup.

The new installer creates `mcu1.service`, `mcu2.service` and `mcu3.service` as **aliases of the same `klipper_lan.service`**, not separate tunnel managers. Restarting any alias restarts all three LAN bridges. Existing LAN-manager files are backed up under `/var/backups/klipper-lan-<timestamp>-<pid>/` before replacement.

## Serial devices

| MCU | USB serial device | LAN serial device | Printer TCP port |
| --- | --- | --- | --- |
| MCU1 | `/dev/ttyGS0` | `/dev/ttyMCU1` | 7003 |
| MCU2 | `/dev/ttyGS1` | `/dev/ttyMCU2` | 7005 |
| MCU3 (reserved) | `/dev/ttyGS2` | `/dev/ttyMCU3` | 7007 |

Only add MCU3 to your Klipper configuration when the hardware and printer-side tunnel exist. LAN connections are opened when the virtual serial device is used, so the reserved third bridge can remain idle.

## Klipper configuration

Keep the MCU section names required by your existing printer configuration. For LAN, use:

```ini
[mcu]
serial: /dev/ttyMCU1
restart_method: command
baud: 576000

[mcu nozzle_mcu]
serial: /dev/ttyMCU2
restart_method: command
baud: 576000
```

For USB, use `/dev/ttyGS0` and `/dev/ttyGS1` in the corresponding sections instead. Do not define the same physical MCU twice via different transports. Apply the configuration through your normal Klipper restart procedure while idle.

## Service management

Check the services you installed:

```bash
systemctl status ports.service
systemctl status klipper_lan.service
journalctl -u klipper_lan.service -b
ls -l /dev/ttyMCU*
```

Manage all LAN bridges together:

```bash
sudo systemctl restart klipper_lan.service
sudo systemctl stop klipper_lan.service
sudo systemctl disable klipper_lan.service
```

Change the printer LAN address in `/etc/default/klipper_lan`, then restart `klipper_lan.service`. USB is managed separately by `ports.service`.

Installed LAN files:

```text
/usr/local/sbin/klipper-lan-tunnels
/etc/default/klipper_lan
/etc/systemd/system/klipper_lan.service
```

## Troubleshooting

- **Existing independent MCU service:** migrate the old service units as described above; do not run two socat managers for the same serial links.
- **LAN device missing:** check `systemctl status klipper_lan.service` and its journal. Existing `/dev/ttyMCU*` entries cause the manager to refuse overwriting them.
- **Connection refused / no MCU response:** check the configured wired printer IP and the printer-side bridge. A running service or existing serial link alone does not prove the MCU connection works.
- **USB gadget unavailable:** check the selected board, gadget-capable USB connector and data cable; reboot if requested by setup.
- **Serial permissions:** ensure the Klipper user belongs to the `dialout` group. Group changes require a new login or restarting the relevant session/service.

## Remove the LAN setup

While the printer is idle:

```bash
sudo systemctl disable --now klipper_lan.service
sudo rm /etc/systemd/system/klipper_lan.service
sudo rm /usr/local/sbin/klipper-lan-tunnels
sudo rm /etc/default/klipper_lan
sudo systemctl daemon-reload
```

Disabling the service removes its systemd-managed MCU aliases. These commands leave USB configuration and `klipper.service` unchanged.

## Resources and community

- [Kobra-S1 Klipper environment](https://github.com/Kobra-S1/klipper-kobra-s1)
- [ACEPRO](https://github.com/Kobra-S1/ACEPRO)
- [Rinkhals](https://github.com/rinkhals-community/Rinkhals)
- [USB tunnel project and printer-side USB SWU packages](https://github.com/Kobra-S1/vanilla-klipper-swu)
- [Original USB setup script](https://github.com/moosbewohner/vanilla-klipper-swu/blob/main/setup_tunnel_klipper.sh)
- [Discord community](https://discord.gg/3mrANjpNJC)

## License

MIT License. Third-party projects retain their respective licenses.

## 🙏 Acknowledgements

A special thank you goes to **Jbatonnet** — without him, the core project *Rinkhals* would not exist. This project provides the essential foundation that makes access to the printer possible.

Another big thank you goes to **Antiriad**, a *Vanilla Klipper* expert. Much of the progress in bringing Vanilla Klipper to Anycubic printers would not have been possible without his work. I am also personally very grateful for all the support, knowledge, and guidance he has shared.

---

