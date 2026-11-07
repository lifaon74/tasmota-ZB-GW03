# ZB-GW03 Tasmota firmware, built from official Upstream releases

Unofficial Tasmota firmware for the [ZB-GW03](https://zigbee.blakadder.com/Sonoff_ZB-GW03.html) ESP32 Zigbee gateway (Ethernet PHY + EZSP coordinator). Upstream — [`arendst/Tasmota`](https://github.com/arendst/Tasmota) — ships no firmware for this board, so this repository maintains the Override files plus the Pipeline that turns every Upstream release into ready-to-flash images, published here.

## Downloads

Grab the images from [Releases](https://github.com/lifaon74/tasmota-ZB-GW03/releases/latest). Release tags carry the exact Upstream release name (a Mirrored tag, e.g. `v16.0.0`); each Release's notes record the Pipeline run that produced it plus the `sha256` of both images.

| Asset | Use for |
| --- | --- |
| `tasmota32-ZB-GW03-EN.bin` — the **OTA image** | upgrades, flashed over the air via Tasmota's upgrade flow |
| `tasmota32-ZB-GW03-EN.factory.bin` — the **Factory image** | first install, flashed over serial (bootloader + app) |

- The language matrix is **EN only**; no `.map.gz` is published.
- Releases here are the only distribution point (the Pipeline does not host images anywhere else).

## How it works (the Pipeline)

1. **Resolve** — `tasmota/build.sh` resolves the latest stable Upstream release (newest `vX.Y.Z` tag; Upstream never publishes `prerelease`-flagged releases in-repo).
2. **Build** — it shallow-clones exactly that official tag, copies in the two **Override files** maintained under `tasmota/` (`user_config_override.h`, `platformio_override.ini`), applies Upstream's release-footer sed, and builds with the toolchain Upstream's own release flow pins (Python 3.13 + `pioarduino==6.2.0`, installed via `uv`). The Factory image additionally bakes in Upstream's safeboot binary, fetched from ota.tasmota.com at build time. No fork is maintained; native Linux only, no Docker — the Pipeline and a local session run the exact same script.
3. **Publish** — the Release carrying the Mirrored tag is upserted: created if absent, binaries replaced if present, notes with this-repo commit and the `sha256` of both images.

Triggers (`.github/workflows/pipeline.yml`):

| Trigger | Behavior |
| --- | --- |
| daily cron | resolve, then build **only when the (Upstream release, recipe digest) pair is not already published** — each Release's notes carry a `Recipe digest` line (hash of `tasmota/**`); a stable pair produces a green no-op run |
| push to `main` touching `tasmota/**` | full build and republish — this is how recipe fixes land |
| `workflow_dispatch` | manual run; the `force` input rebuilds regardless of the gate |
| `pull_request` touching `tasmota/**` | build only — validates recipe changes; nothing is published |

**When a build fails:** the run goes red, no Release is touched, and a self-documenting diagnostic issue is opened (failing steps, the changelog delta since the last good build, log tail, and pickup steps written for an agent). A later successful build publishes and auto-closes those issues.

## Build it locally

Linux, no Docker. The first run downloads ~2 GB of toolchain (self-provisioned by `uv`), fully cached afterwards:

```bash
git clone https://github.com/lifaon74/tasmota-ZB-GW03
cd tasmota-ZB-GW03
tasmota/build.sh                      # latest stable Upstream release
UPSTREAM_TAG=v16.0.0 tasmota/build.sh # pin a specific Upstream release
RESOLVE_ONLY=1 tasmota/build.sh       # resolve and print the tag only
```

Artifacts land in `build/` with their `sha256`; `.upstream/`, `.venv/` and `build/` are generated paths (gitignored).

## Changing the recipe

The Override files and the recipe logic live under `tasmota/`. `main` is ruleset-protected — changes land through Pull Requests from feature branches. If a Pipeline run fails, its auto diagnostic issue lists the pickup steps: fix the Override files (or `tasmota/build.sh`), open a PR, and the merge push rebuilds, republishes, and closes the issue automatically.

Domain vocabulary lives in [`GLOSSARY.md`](GLOSSARY.md).

## Credits

- Recipe adapted from [`xsp1989/ZB-GW03_firmware`](https://github.com/xsp1989/ZB-GW03_firmware) (its v14.5.0-era `tasmota/README.md` recipe, trimmed to the EN-only matrix).
- Firmware originates from the official [`arendst/Tasmota`](https://github.com/arendst/Tasmota) releases; their license applies to the binaries.
