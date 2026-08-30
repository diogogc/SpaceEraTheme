# Space Era

Space Era is an Omarchy theme that turns your desktop into a compact mission-control console: deep black surfaces, phosphor-green telemetry, NASA red alerts, blue tracking overlays, and a real Apollo-era Mission Control wallpaper anchoring the whole thing.

It is not a landing page. It is the cockpit.

## Features

- Space Era Omarchy theme with matched Mission Control palette.
- Opaque black menu bar for a clean instrument-panel feel.
- Apollo-inspired system telemetry plugin with console-style needle gauges (CPU, MEM, VRAM, TMP).
- Apollo DSKY AGC Calculator (`spaceera.dsky`) with math evaluation, register displays, and multi-unit conversions (time, data, bases, velocity).
- Flight Director Mission Timeline & Pomodoro Engine (`spaceera.timeline`) with Mission Elapsed Time (MET), T-Minus event countdowns, and propulsion burn focus sessions.
- Live ISS tracker & 7-Day Space Launch Manifest plugin with:
  - real coastline map data
  - live ISS marker & 19-node ground track projection
  - white orbit path & blue visibility footprint
  - configurable user city with pass predictions and optical flare sightings
  - flashing `ACQUIRED` bar state when the ISS is in range
  - 7-day upcoming space launch manifest (Launch Library 2)
  - interactive launch pad coordinate targeting with glowing crosshairs
  - live mission HUD with T-minus countdown ticker and favorite bookmarks (`★`)
- High-resolution NASA Mission Control background.

## Screenshots

![Space Era Mission Control background](screenshots/theme-03-mission-control.png)

![Space Era Meatball background](screenshots/theme-01-meatball.png)

![Space Era Worm background](screenshots/theme-02-worm.png)

![Space Era ISS tracker](screenshots/plugin-iss-tracker.png)

![Space Era telemetry](screenshots/plugin-telemetry.png)

## Install

Install the theme directly from GitHub:

```bash
omarchy theme install https://github.com/diogogc/SpaceEraTheme.git
omarchy theme set "Space Era"
```

Then install the bundled console plugins:

```bash
mkdir -p ~/.config/omarchy/plugins
cp -a ~/.config/omarchy/themes/space-era/plugins/spaceera-iss-tracker ~/.config/omarchy/plugins/spaceera.iss-tracker
cp -a ~/.config/omarchy/themes/space-era/plugins/spaceera-telemetry ~/.config/omarchy/plugins/spaceera.telemetry
cp -a ~/.config/omarchy/themes/space-era/plugins/spaceera-dsky ~/.config/omarchy/plugins/spaceera.dsky
cp -a ~/.config/omarchy/themes/space-era/plugins/spaceera-timeline ~/.config/omarchy/plugins/spaceera.timeline
```

Add the widgets to your Omarchy bar configuration if they are not already present in `~/.config/omarchy/shell.json`:

```json
{
  "bar": {
    "layout": {
      "right": [
        "spaceera.iss-tracker",
        "spaceera.telemetry",
        "spaceera.dsky",
        "spaceera.timeline"
      ]
    }
  }
}
```

Omarchy usually hot-reloads local plugins. If needed, restart the shell:

```bash
omarchy restart shell
```

The plugins use standard command-line tools available on a typical Omarchy system: `bash`, `curl`, `jq`, and `python3`.

## Standalone ISS Tracker

The ISS tracker plugin is also available as its own repository:

```bash
git clone https://github.com/diogogc/spaceera-iss-tracker.git ~/.config/omarchy/plugins/spaceera.iss-tracker
```

## ISS Tracker Usage

Click `ISS` in the bar to open the tracker panel.

- Type a city in the `HOME` field and press Enter or `SET`.
- Your city is saved in `~/.config/spaceera/iss-location.json`.
- The map shows your location, the ISS location, orbit path, and visibility footprint.
- When the ISS is inside your visibility footprint, the bar flashes and shows `ACQUIRED`.

Right-click the bar widget to refresh live data.

## Telemetry Usage

Click `Telemetry` in the bar to open the system panel. The panel shows CPU, memory, video memory, and temperature as character-based Apollo-style needle gauges.

Right-click the bar widget to refresh immediately.

## DSKY Calculator Usage

Click `DSKY` in the bar to open the Apollo Guidance Computer DSKY panel.

- Type standard math expressions directly (e.g. `25 * 60`, `sqrt(144)`, `2^10`) or use the physical keypad.
- Switch programs/modes with top tabs or `PROG`:
  - `PROG 01`: General arithmetic and multi-register calculation (`R1` result, `R2` previous, `R3` memory).
  - `PROG 16`: Unix epoch timestamp and live UTC / local mission time.
  - `PROG 25`: Data storage unit converter (Bytes $\leftrightarrow$ KiB/MiB $\leftrightarrow$ GiB/TiB).
  - `PROG 30`: Base converter (Decimal $\leftrightarrow$ Hexadecimal $\leftrightarrow$ Binary).
  - `PROG 40`: Velocity converter (km/h $\leftrightarrow$ mph/knots $\leftrightarrow$ m/s/Mach).
- Right-click the bar widget to cycle program modes quickly.

## Flight Director & Pomodoro Usage

Click the Flight Director icon in the bar to open the mission timeline.

- **Mission Elapsed Time (MET)**: Real-time clock tracking session duration.
- **Propulsion Burn Engine (Focus Sessions)**:
  - Click `▶ IGNITION` to start a focus burn (default 25m).
  - Click `❚❚ HOLD` to pause or `⏭ STAGE SEP` to transition to coasting orbit (break).
  - Automatic desktop notification on burnout and stage transitions.
  - Quick presets for `25/5m`, `45/10m`, `50/10m`, and `60/15m` focus cycles.
- **T-Minus Countdown**: Quick buttons (`+5M`, `+15M`, `+30M`, `+60M`) for meeting or deadline countdowns.
- Right-click the bar widget to quickly toggle/pause the active burn.

## Credits

Created by **diogo carvalho**.

The Mission Control background is based on official NASA imagery. Space Era's theme styling, plugin design, and console instrumentation are original work by diogo carvalho.

## License

Released under the **Creative Commons Attribution 4.0 International License (CC BY 4.0)**. You may use, modify, and share it, but you must give appropriate credit to **diogo carvalho**.
