# Upstream deltas v14.5.0 → v16.0.0 — impact on the ZB-GW03 build recipe

Research ticket: [lifaon74/tasmota-ZB-GW03#3](https://github.com/lifaon74/tasmota-ZB-GW03/issues/3) · Date: 2026-11-07 · Branch: `research/upstream-deltas` (throwaway, never merged).

**Question.** Between Upstream `arendst/Tasmota` v14.5.0 (the last build basis used by xsp1989's ZB-GW03 firmware) and the current stable v16.0.0, what plausibly breaks building the ZB-GW03 firmware from xsp1989/ZB-GW03_firmware's documented recipe — a `user_config_override.h` gated by `-DFIRMWARE_EASYIOT` plus a `platformio_override.ini` defining `env:tasmota32-ZB-GW03-EN` extending `env:tasmota32` — and which exact toolchain versions does Upstream's own CI pin?

**Method.** Every claim below was verified against primary sources fetched at the exact git tags: `raw.githubusercontent.com/arendst/Tasmota/<tag>/...` files, GitHub APIs (`releases`, `contents`, `search`), the platform fork's `platform.json` at the pinned platform releases, and xsp1989's README. Where line numbers are given, they refer to the fetched copies (kept in `/tmp/opencode/research/` during this run, e.g. `my_user_config_v16.0.0.h`).

---

## TL;DR

The recipe is **structurally intact on v16.0.0**: `env:tasmota32` / `env:tasmota32_base` still exist with the same names and shape, every `#define` / `#undef` the override touches still resolves upstream, the template's GPIO codes are unchanged, and `boards/esp32.json` (partitions/bootloader for plain ESP32) is byte-identical between the two tags. Nothing in the override files *must* change.

The real deltas are **build-infrastructure side**:

1. **Toolchain switch** (biggest delta): v16.0.0 CI no longer installs vanilla `platformio` — it pins **Python 3.13** and **`pioarduino==6.2.0`** (PlatformIO Core fork, PyPI), installed via `uv`, and runs the same-looking `platformio run -e <env>`.
2. **Platform regress**: pioarduino/tasmota platform `platformio_tasmota32.ini` `[core32.platform]` went `2025.02.30` → `2026.09.50`: Arduino-ESP32 **v3.1.1 → v3.3.12**, ESP-IDF **v5.3.2 → v5.5.5**, GCC **13.2.0 → 15.2.0**, esptool **4.8.7 → 5.4.0**. This is where any compile-flag/link fallout would come from, not from Tasmota's config-tree changes.
3. **Stale-but-harmless override content**: the override's own re-definition of `[env:tasmota32_base]` (`extra_scripts`, old `lib_ignore`, `[env]` ESP8266-era blocks) still resolves — the interpolated keys it references (`${esp32_defaults.extra_scripts}`, `${common.upload_resetmethod}`, `${library.lib_extra_dirs}`) all still exist — but it carries ESP8266/IDF4-era library names that no longer match anything in Arduino-core v3.3.x (ignored with warnings only).
4.	version-header `sed` in CI adds ` release-` to the firmware footer via `tasmota/include/tasmota_version.h`; replicate it for artifact parity (cosmetic otherwise).
5. **Pre-release policy**: in practice the `prerelease` field never discriminates anything in `arendst/Tasmota` — every published release ever (v8.4.0 … v16.0.0) has `prerelease: false`, `draft: false`; "latest stable" is simply the newest `vX.Y.Z` tag (`releases/latest` = v16.0.0). Continuous/dev artifacts are published in the separate `arendst/Tasmota-firmware` repo, not as pre-releases.

---

## 1. The recipe as documented (baseline)

Source: <https://raw.githubusercontent.com/xsp1989/ZB-GW03_firmware/master/tasmota/README.md> (fetched 2026-11-07).

The documented build recipe consists of exactly three artifacts:

- **`user_config_override.h`** (created in the `tasmota/` dir, included because of Upstream's `-DUSE_CONFIG_OVERRIDE` build flag): contents gated by `#ifdef FIRMWARE_EASYIOT`. Sets `USE_DISCOVERY`, `MDNS_ENABLED=true`, template as default module (`MODULE` / `FALLBACK_MODULE` = `USER_MODULE`, `USER_TEMPLATE` with the ZB-GW03 GPIO map), switches off a block of drivers (`USE_BERRY`, `USE_LIGHT`, WS2812 family, Tuya, Shelly, RF, etc.), then re-enables: `USE_ZIGBEE`, `USE_ZIGBEE_EZSP`, `USE_ZIGBEE_EEPROM` (T24C512A), `USE_TCP_BRIDGE`, `USE_ZIGBEE_CHANNEL 11`, `USE_UFILESYS`, `USE_ETHERNET`, `ETH_TYPE 0` (LAN8720), `ETH_CLKMODE 3` (GPIO17-out), `ETH_ADDRESS 1`.
- **`platformio_override.ini`**: py-files-style boilerplate sections `[env]` (ESP8266-era board/lib settings), `[env:tasmota32_base]` (ESP32 re-definition referencing `${esp32_defaults.extra_scripts}`, `${esp32_defaults.lib_ignore}`-style entries, `${library.lib_extra_dirs}`, `${common.upload_resetmethod}`), `[library]` (shared lib dir + enabled list), and 28 per-language ZB-GW03 envs `[env:tasmota32-ZB-GW03-XX]` where the EN variant does `extends = env:tasmota32` and `build_flags = ${env:tasmota32_base.build_flags} -DFIRMWARE_EASYIOT`.
- **Build command**: `pio run -e tasmota32-ZB-GW03-EN`.

`FIRMWARE_EASYIOT` is xsp1989's *private* gate — it is **not** a feature flag Upstream interprets anywhere (verified: no occurrence in arendst/Tasmota at v16.0.0 GitHub code search; GitHub search for `FIRMWARE_EASYIOT` returns zero source hits). It only makes the override's `#ifdef` arm compile and pins `-D` on that env.

---

## 2. (a) Do `env:tasmota32` / `env:tasmota32_base` still exist with the same structure?

**Yes — names and structure unchanged.** Compared `platformio.ini`, `platformio_tasmota_env32.ini`, `platformio_tasmota32.ini` at both tags:

| File @ v16.0.0 | Fact |
|---|---|
| `platformio.ini` `[platformio] explicit extra_configs` | `platformio_tasmota32.ini`, `platformio_tasmota_env.ini`, `platformio_tasmota_env32.ini`, `platformio_override.ini`, `platformio_tasmota_cenv.ini` (last entry new vs v14; see §6) |
| `platformio_tasmota_env32.ini` `[env:tasmota32_base]` | Present, identical key shape at both tags: `platform = ${core32.platform}`, `board = esp32`, `build_flags = ${core32.build_flags}`, `extra_scripts = ${esp32_defaults.extra_scripts}`, `upload_resetmethod = ${common.upload_resetmethod}`, `lib_extra_dirs = ${common.lib_extra_dirs} + lib/libesp32 + lib/libesp32_lvgl` |
| `platformio_tasmota_env32.ini` `[env:tasmota32]` | Present, `extends = env:tasmota32_base`, adds `-DFIRMWARE_TASMOTA32` + `OTA_URL` — same as v14.5.0 |
| `platformio_tasmota32.ini` `[core32]` | Present at both tags; this is where the platform URL lives (v14.5.0: in this file; v15+ also fine) |
| `platformio_tasmota32.ini` `[esp32_defaults]` | Present; every key the override references still exists (`extra_scripts`, `build_flags`, `build_unflags`, `lib_ignore`, `monitor_filters`) |
| `platformio.ini` `[common]` `upload_resetmethod` | `nodemcu` — unchanged |

Resolution order note (this is why the override keeps working): PlatformIO merges sections **key-wise across config files**, later files (`platformio_override.ini` is last in `extra_configs`) winning per key. The override's `[env:tasmota32_base]` only assigns `extra_scripts`, `lib_ignore`, `lib_extra_dirs`, `monitor_speed`/`upload_resetmethod` — so all other v16 base keys (`board = esp32`, `build_flags`, `build_unflags`, `custom_unpack_dir`, `custom_files_upload`, `board_build.variants_dir`, `lib_ldf_mode`, `lib_compat_mode`, `monitor_filters`) are inherited unchanged from Upstream.

Differences inside the upstream chain that the recipe inherits implicitly:

- `[esp32_defaults].extra_scripts` grew: v14.5.0 had `pre: add_c_flags.py, solidify-from-url.py, gen-berry-structures.py; post: post_esp32.py` + `${esp_defaults.extra_scripts}`; v16.0.0 adds `post: picolibc_flags.py, dump-defines.py, gen-berry-defines.py, gen-berry-structures.py`. Overridden value in the recipe (`extra_scripts = ${esp32_defaults.extra_scripts}`) is identical to Upstream's own value, so nothing breaks.
- `[esp32_defaults].monitor_filters`: `esp32_exception_decoder` (v14.5.0) → empty (v16.0.0). Monitor-only, no build impact.
- `-DFRAMEWORK_ARDUINO_ITEAD` / `-DFRAMEWORK_ARDUINO_SOLO1` flags were removed from some variant envs (`tasmota32-zbbrdgpro`, `tasmota32-nspanel`, `tasmota32-safeboot`) between the tags — envs the recipe does not touch.
- v16 variant envs gained optional keys (`custom_sdkconfig …`, `custom_component_remove`, `check_skip_packages`, `custom_unpack_dir`, `board_build.variants_dir = variants/tasmota`) — none of them set on `env:tasmota32`, all inherited verbatim.

**Platform pin per tag** (from `[core32.platform]` in `platformio_tasmota32.ini`):

| Tag | `platform` (both are Tasmota's own `platform-espressif32` fork, itself a pioarduino/IDF5 fork) |
|---|---|
| v14.5.0 | `https://github.com/tasmota/platform-espressif32/releases/download/2025.02.30/platform-espressif32.zip` |
| v16.0.0 | `https://github.com/tasmota/platform-espressif32/releases/download/2026.09.50/platform-espressif32.zip` |

(The ESP8266 side moved to `2026.09.00` — irrelevant to this build.)

---

## 3. (b) v16.0.0 CI — exact pins

Source: `https://raw.githubusercontent.com/arendst/Tasmota/v16.0.0/.github/workflows/Tasmota_build_master.yml`.

Every build job (safeboot-images / base-images / base32-images / language-images / language32-images) repeats:

```yaml
- name: Set up Python
  uses: actions/setup-python@v6
  with:
    python-version: '3.13'
- name: Install uv
  uses: astral-sh/setup-uv@v7
  with:
    version: "latest"
    enable-cache: false
- name: Install dependencies
  run: |
    uv pip install --system pioarduino==6.2.0
    cp ./platformio_override_sample.ini ./platformio_override.ini
- name: Add "release" to footer
  run: |
    sed -i -e "s/TASMOTA_SHA_SHORT/TASMOTA_SHA_SHORT release-/g" ./tasmota/include/tasmota_version.h
- name: Run PlatformIO
  env:
    PYTHONIOENCODING: utf-8
    PYTHONUTF8: '1'
  run: platformio run -e ${{ matrix.variant }}
```

Facts:

- **Python: `3.13`** (pinned), previously `3.x` floating at v14.5.0.
- **Install mechanism: `uv pip install --system pioarduino==6.2.0`** — not `pip install -U platformio`. `pioarduino` (PyPI, owner Jason2866) is "an independent fork of PlatformIO Core" that "does not require or use the PlatformIO Registry"; requires Python ≥ 3.10; version 6.2.0 published 2026-09-15 (a 6.2.0.post1 followed on 2026-10-26). The CLI it provides is still invoked as `platformio`.
- **Build command: `platformio run -e <env>`**, with `PYTHONIOENCODING=utf-8` and `PYTHONUTF8=1` exported.
- CI also copies `platformio_override_sample.ini` → `platformio_override.ini` (provides `default_envs`), before explicitly passing `-e`.
- v14.5.0-era workflow for comparison: Python `3.x`, `pip install wheel; pip install -U platformio` — the rest identical (same sed, same `platformio run`).

---

## 4. (c) Override flag audit against v16.0.0

Every token the `user_config_override.h` `#define`s or `#undef`s was checked in the v16.0.0 tree. All exist. `#undef` of an undefined macro is legal C preprocessor, so removals would never be compile errors anyway — the audit checks each token is still a real, effective knob.

### 4.1 In `tasmota/my_user_config.h` at v16.0.0

| Recipe token | v16.0.0 line(s) | Notes |
|---|---|---|
| `USE_ZIGBEE` | 1101 (commented default) | comment now says "CC2530/CC2652 flashed with ZNP or EFR32 flashed with EZSP" |
| `USE_ZIGBEE_ZNP` | 1102 (default ON) | `#undef` keeps EZSP-only build |
| `USE_ZIGBEE_EZSP` | 1103 (commented default) | still gate-employs drivers: present in `tasmota/tasmota_xdrv_driver/xdrv_23_zigbee_1_headers.ino` and `xdrv_23_zigbee_9_serial.ino` at the tag |
| `USE_ZIGBEE_EEPROM` | 1105 (commented default); also defined in `SONOFF_ZIGBEEBRIDGE` block of `tasmota/include/tasmota_configurations.h` line 688; still consumed by `xdrv_23_zigbee_4a_nano_fs.ino` etc. | no rename |
| `USE_TCP_BRIDGE` | 954 (commented default) | unchanged |
| `USE_ZIGBEE_CHANNEL` | 1106 — default already `11` | recipe sets the same value |
| `USE_ETHERNET` | 1259 (commented default) | unchanged |
| `ETH_TYPE` / `ETH_ADDRESS` / `ETH_CLKMODE` | 1261-1263 / 1265-1267 | allowed values unchanged (`0 = LAN8720 …`, `ETH_CLOCK_GPIO0_IN…GPIO17_OUT`); v16 has live defines only inside board-specific prebuilt-board blocks (Olimex/wESP32), the recipe's later `#define` wins |
| `USE_UFILESYS` | **not in `my_user_config.h` at all (neither tag)** — defined in `tasmota/include/tasmota_configurations.h` "Mandatory defines": `#ifndef ESP8266_1M → #define USE_UFILESYS` (v16 line 1057 fol.) | on any ESP32 build it is **auto-enabled**; the recipe's `#define` is redundant-but-harmless, as at v14.5.0 |
| `USE_DISCOVERY` / `MDNS_ENABLED` / `MQTT_HOST_DISCOVERY` | 556 / 275 / 558 | `MDNS_ENABLED` default `false`; override sets `true` — works |
| `MODULE`, `USER_MODULE`, `FALLBACK_MODULE`, `USER_TEMPLATE` | 53, 57, 55-60, 61 region (commented defaults); `USER_MODULE = 255` defined in `tasmota/include/tasmota_template.h` (moved from `tasmota/tasmota_template.h` to `tasmota/include/` between the tags — path shift only, symbol intact) | template-as-default still supported |
| `LIGHT_MODE`, `USE_DOMOTICZ`, `OTA_URL`, `WEB_PASSWORD`, `APP_TIMEZONE` | 355 (`true`), 478, `#ifndef OTA_URL` guard 1425, 208, 305 | `LIGHT_MODE` semantic unchanged (`[SetOption15]`) |
| Driver-off list (`ROTARY_*`, `USE_SONOFF_RF`, `USE_RF_FLASH`, `USE_SONOFF_SC`, `USE_TUYA_*`, `TUYA_DIMMER_ID`, `USE_ARMTRONIX_DIMMERS`, `USE_PS_16_DZ`, `USE_SONOFF_IFAN`, `USE_BUZZER`, `USE_ARILUX_RF`, `USE_SHUTTER`, `USE_DEEPSLEEP`, `USE_EXS_DIMMER`, `EXS_MCU_CMNDS`, `USE_HOTPLUG`, `USE_DEVICE_GROUPS`+addr/port/send, `USE_PWM_DIMMER(+_REMOTE)`, `USE_KEELOQ`, `USE_SONOFF_D1`, `USE_SHELLY_DIMMER`, `SHELLY_CMDS`, `SHELLY_FW_UPGRADE`, `SHELLY_VOLTAGE_MON`, `USE_AUTOCONF`) | 587-614 approx (561-614) | every single one still present at v16.0.0 |
| `USE_BERRY` | 1287 (`#define`; guard chain: nothing re-enables it outside `USE_AUTOCONF` post-processing) | `#undef` still effective |
| `USE_LIGHT`, WS2812 family (`USE_WS2812(+_DMA/_RMT/_I2S/_INVERTED/_HARDWARE/_CTYPE)`), `USE_MY92X1`, `USE_SM16716`, `USE_SM2135`, `USE_SM2335`, `USE_BP5758D`, `USE_SONOFF_L1`, `USE_ELECTRIQ_MOODL`, `USE_LIGHT_PALETTE`, `USE_LIGHT_VIRTUAL_CT`, `USE_DGR_LIGHT_SEQUENCE`, `USE_LSC_MCSL` | 624, 639+, 625-636 | all present (`USE_LSC_MCSL` is commented-default; `#undef` harmless) |

### 4.2 Template GPIO codes (decoded from `tasmota/include/tasmota_template.h`, `enum UserSelectablePins`; value = 0-based index × 32, +1 = second pin of a two-pin role)

| Template code | Role at v16.0.0 |
|---|---|
| `32` | `GPIO_KEY1` |
| `320` | `GPIO_LED1_INV` |
| `544` | `GPIO_LEDLNK` |
| `608` / `640` | `GPIO_I2C_SCL` / `GPIO_I2C_SDA` |
| `3552` / `3584` | `GPIO_ZIGBEE_TX` / `GPIO_ZIGBEE_RX` |
| `5536` / `5568` / `5600` | `GPIO_ETH_PHY_POWER` / `GPIO_ETH_PHY_MDC` / `GPIO_ETH_PHY_MDIO` |
| `5792` / `5793` | `GPIO_ZIGBEE_RST` / same +1 (bootloader pin) |

The enum is **append-only** between v14.5.0 (369 tokens) and v16.0.0 (393 tokens): token-level diff shows only new entries at the end (`GPIO_V9240_*`, `GPIO_LD2402_*`, `GPIO_HSDIO_*`, `GPIO_VID6608_*`, `GPIO_MKSKYBLU_*`) and one same-position rename `GPIO_OLED_RESET` → `GPIO_DISPLAY_RESET` (comment: "renamed from OLED_RESET"; numeric value unchanged). **The xsp1989 template numbers are untouched.**

Also verified: GitHub search shows `USE_UFILESYS` / `USE_ZIGBEE_EEPROM` still referenced in v16 sources (`tasmota/tasmota.ino`, `tasmota_support/settings.ino`, `support_command.ino`, zigbee drivers) — they are live feature gates, not fossils.

---

## 5. (d) Platform / chip-support shift between the v14.5.0-era and v16.0.0 platforms

From `platform.json` at each platform release tag (`raw.githubusercontent.com/tasmota/platform-espressif32/<tag>/platform.json`):

| Component | 2025.02.30 (v14.5.0 base) | 2026.09.50 (v16.0.0 base) |
|---|---|---|
| Arduino-ESP32 framework | `tasmota/arduino-esp32` v3.1.1.250203 (zip) | v3.3.12 (tar.xz) |
| ESP-IDF | v5.3.2.250120 | v5.5.5 |
| Toolchain | GCC 13.2.0 (xtensa+riscv) | **GCC 15.2.0** from `pioarduino/registry` (xtensa-esp-elf + riscv32-esp-elf, 2025-12-04 build) |
| esptool | 4.8.7 (tasmota fork) | 5.4.0 (`pioarduino` registry) + `esp_install-v5.3.5` |
| solo1/ITEAD framework packages | separate assets | framing changed (single framework package; ITEAD envs no longer take `-DFRAMEWORK_ARDUINO_ITEAD` from the ini files) |

Tasmota's own CHANGELOG traces the verbatim regression chain inside v15.x: `2025.02.30 → 2025.03.30 → 2025.04.30 (Arduino v3.1.11, IDF 5.3.4.251226) → 2026.03.30 (v3.1.10) → 2026.04.30 (v3.1.11) → 2026.04.50 (v3.3.7/3.3.8, IDF 5.5.3+/5.5.4.260407) → 2026.05.50 (v3.3.8) → 2026.09.50 (v3.3.12, IDF 5.5.5)`. The C5/C6/P4 line jumped ahead separately (not relevant to the plain `esp32` board ZB-GW03 uses).

Build-relevant conclusions for Ethernet + Zigbee-EZSP:

- **`boards/esp32.json` is byte-identical between v14.5.0 and v16.0.0** — partition table and bootloader expectations for the plain 4 MB ESP32-D0WD (ZB-GW03) did not change: no partition/CSV/bootloader break from the board definition.
- Scanning the v14.6.0 → v16.0.0 changelog (~600 lines covering v15.0-15.6 + dev runs) for Zigbee/Ethernet/build-system items: **nothing was removed or renamed** that the recipe uses. Additive examples: "ESP32 support SPI bus2 for Ethernet and SDCard (#24433)", "WT32_ETH01 ethernet initialization (#25051)", "Zigbee support for `int24` type (#24334)", Zigbee WebUI update, "Support for baudrate 74880 replacing 74700 (#24924)", Zigbee deferred-timer use-after-free fix (#24979). A defect fix matters: "Re-enable `-DUSE_SHA_ROM` flag for IDF v5.5.4 = current version and up (#24757)" — v16's `[esp32_defaults]` carries `-DUSE_SHA_ROM` with the comment "use of ROM SHA routines is automatically disabled for IDF version earlier v5.5.4" (guarded in source, harmless below 5.5.4).
- The only heavily-touched subsystem in v15.x is Berry (solidification moved into the build system, warnings flags, etc.) — the recipe `#undef`s `USE_BERRY`, so its build never runs the Berry post scripts beyond the always-installed scripts (`gen-berry-*.py` no-op without USE_BERRY).

---

## 6. (f) Anything else with direct build impact

- **`tasmota_version.h` release-marker sed**: `#define TASMOTA_SHA_SHORT` exists at v16.0.0 (`tasmota/include/tasmota_version.h` line 23, "Filled by Github sed"). CI's `sed -i -e "s/TASMOTA_SHA_SHORT/TASMOTA_SHA_SHORT release-/g"` yields a footer of the form `16.0.0 release-……` instead of `16.0.0-{commit}`. Replicating this in the pipeline gives byte-level artifact parity with Upstream releases; skipping it only changes the module-version string. It was already part of the v14.5.0 workflow — **not a new requirement**, just one the private pipeline may not have replicated.
- **`platformio_tasmota_cenv.ini`** is listed in v16.0.0's `[platformio] extra_configs` but the file does not exist in the v16.0.0 tree (only `platformio_tasmota_cenv_sample.ini`, both at tag and on master). PlatformIO tolerates a missing extra-config with a warning; existing builds prove it. Non-issue, but a pipeline should not try to fetch it.
- **CI builds languages explicitly** (`platformio run -e tasmota32-${language}`) — with the same 27-language matrix (AD…VN incl. LT). xsp1989's per-language ZB-GW03 envs mirror this same pattern and remain valid.
- **`@actions/*` bumps** (checkout@v6, setup-python@v6, setup-uv@v7, upload-artifact@v7) — pipeline-level hygiene only.
- **`PubSubClient` library renamed to `TasmotaPubSub`** (v15.6.0 changelog) — matters only if the pipeline hard-coded library names in `lib_ignore`; the xsp1989 override doesn't touch MQTT libs.

---

## 7. (e) Pre-release practice

`gh api repos/arendst/Tasmota/releases` (paginated): every release object in the repo — from v8.4.0 (2020) through v16.0.0 (published 2026-10-16, "Tasmota v16.0.0 Theo") — has `prerelease: false` and `draft: false`. **In practice the `prerelease` field never discriminates stable from pre-release**: Upstream simply doesn't publish pre-releases in `arendst/Tasmota` at all. The official dev/continuous channel is the separate `arendst/Tasmota-firmware` repo (the workflow's `Start_final_copy` job dispatches `fetch_deploy.yml` there after each master build). `releases/latest` resolves to v16.0.0.

**Pipeline rule**: "latest stable" = the newest SemVer tag `vX.Y.Z` in `arendst/Tasmota`; don't try to parse `prerelease`; don't consume dev artifacts from Tasmota-firmware for release builds. Currently v16.0.0 (2026-10-16); the v15-series ended at v15.6.0.

---

## 8. Practical recipe for the pipeline (pin list)

1. Checkout `arendst/Tasmota` at the chosen stable tag (v16.0.0 works with the xsp1989 files unchanged).
2. Python **3.13**; install **`pioarduino==6.2.0`** (`uv pip install --system pioarduino==6.2.0`, or plain `pip install pioarduino==6.2.0`).
3. Place xsp1989's `user_config_override.h` (in `tasmota/`) and `platformio_override.ini` (repo root).
4. Optional parity step: the `tasmota_version.h` sed from CI.
5. Build: `platformio run -e tasmota32-ZB-GW03-EN` (export `PYTHONIOENCODING=utf-8`, `PYTHONUTF8=1`).
6. Expected first-class fallout to watch for: **compiler-level** changes from GCC 13→15 / IDF 5.3→5.5 (warnings-as-errors, IPSmega flags handled by Upstream's `add_c_flags.py`/`picolibc_flags.py`), and possibly larger flash usage with Arduino-core v3.3.x on a 2944k-app partition — the ws2812/light/rel driver removes and Ethernet-only build are already the recipe's mitigation for that.

## 9. Not verified here (out of scope)

- Runtime behavior on actual hardware (Ethernet bring-up on IDF 5.5.x with LAN8720 @ GPIO17-clk, EZSP calibration/EEPROM persistence) — a smoke-test on device is the natural next ticket.
- Whether v16's slimmer safeboot/`custom_component_remove` machinery affects the `-safeboot` OTA slot for a 4 MB plain-ESP32 board (v16 `tasmota32-safeboot` still uses `board = esp32-solo1`, unchanged shape).
- Binary size deltas per variant (needs an actual build run).

---

## Sources

- xsp1989 recipe README: https://raw.githubusercontent.com/xsp1989/ZB-GW03_firmware/master/tasmota/README.md
- arendst/Tasmota @ v16.0.0: `platformio.ini`, `platformio_tasmota32.ini`, `platformio_tasmota_env32.ini`, `platformio_override_sample.ini`, `.github/workflows/Tasmota_build_master.yml`, `tasmota/my_user_config.h`, `tasmota/include/tasmota_template.h`, `tasmota/include/tasmota_configurations.h`, `tasmota/include/tasmota_version.h`, `boards/esp32.json`, `tasmota/tasmota_xdrv_driver/xdrv_23_zigbee_1_headers.ino`, `xdrv_23_zigbee_9_serial.ino`, `CHANGELOG.md` — all under `https://raw.githubusercontent.com/arendst/Tasmota/v16.0.0/...`
- arendst/Tasmota @ v14.5.0: same file set under `.../v14.5.0/...` for comparison
- Platform fork: `https://raw.githubusercontent.com/tasmota/platform-espressif32/{2025.02.30,2026.09.50}/platform.json`
- GitHub APIs: `repos/arendst/Tasmota/releases[?latest]`, `repos/arendst/Tasmota/contents/?ref=v16.0.0`, `repos/tasmota/platform-espressif32/releases`, code search `repo:arendst/Tasmota {USER_MODULE,USE_UFILESYS,USE_ZIGBEE_EEPROM}`
- PyPI: `https://pypi.org/pypi/pioarduino/json` (independent fork of PlatformIO Core; requires Python ≥ 3.10; 6.2.0 / 6.2.0.post1)
- GitHub code search confirms `FIRMWARE_EASYIOT` is not an Upstream flag (0 source hits in arendst/Tasmota).
