# ZB-GW03 Firmware Pipeline

Language for the effort that automatically rebuilds Tasmota firmware for the ZB-GW03 gateway on every upstream Tasmota release.

## Language

**ZB-GW03**:
A small ESP32 Zigbee gateway (Ethernet PHY + EZSP Zigbee coordinator) whose firmware is not built by upstream Tasmota and must be produced here.
_Avoid_: Sonoff ZB-GW-03 branding variants

**Upstream**:
The official `arendst/Tasmota` repository and its releases, from which firmware source is taken.
_Avoid_: "the Tasmota repo" (ambiguous with this repo)

**Upstream release**:
A stable, non-prerelease release tag of Upstream — the unit this pipeline reacts to.
_Avoid_: version

**Override files**:
The two files this repo maintains — `user_config_override.h` and `platformio_override.ini` — copied into an upstream checkout at build time.
_Avoid_: patch, fork

**Mirrored tag**:
A tag in this repo carrying the exact name of the Upstream release its firmware was built from.
_Avoid_: internal version scheme

**Pipeline**:
The GitHub Actions workflow in this repo that builds firmware from an Upstream release plus the Override files and publishes the result to this repo's Releases.
_Avoid_: CI

**OTA image**:
The per-language app-only binary (`tasmota32-ZB-GW03-<LANG>.bin`) flashed over the air via Tasmota's upgrade flow.
_Avoid_: "the bin" loosely

**Factory image**:
The per-language merged binary (`...factory.bin`) containing bootloader + app, flashed over serial on first install.
_Avoid_: "full flash"
