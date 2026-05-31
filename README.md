# Parametric Open-Front Storage Bin (OpenSCAD)

A fully parametric, open-front storage bin with a low front wall and a diagonal chamfer on the side walls. Designed in [OpenSCAD](https://openscad.org/) and compatible with the **MakerWorld Parametric Maker** so you can resize it directly in the browser without installing anything.

Originally designed to organise the technical compartments of a HYMER Grand Canyon S camper, but useful anywhere you need a tidy, drop-in bin: drawers, shelves, vans, workshops, kitchens.

![Storage Bin Preview](docs/preview.png)

## Print profile on MakerWorld

Ready-to-print profiles (with sliced settings) are published on MakerWorld:

**➡️ [Parametrischer offener Aufbewahrungsbehälter on MakerWorld](https://makerworld.com/de/models/2867878-parametric-open-front-storage-bin#profileId-3204005)**

You can also customise the dimensions directly on MakerWorld via the Parametric Maker — no local OpenSCAD installation required.

## Features

- Fully parametric: width, depth, height, front-wall height, chamfer length, wall and floor thickness
- Diagonal chamfer on the side walls for easy access to contents
- Optional bottom-edge chamfer to relieve elephant-foot artefacts
- Printer presets for Bambu Lab **P1S**, **P2S**, **H2C**, **H2D** (auto-clamps dimensions to the build volume) plus a **Custom** option
- Single STL — prints flat on the build plate, no supports required

## Parameters

All parameters are exposed via the OpenSCAD Customizer (and the MakerWorld Parametric Maker):

| Section | Parameter | Description |
|---|---|---|
| Printer / Build Volume | `printer` | Preset: `P1S`, `P2S`, `H2C`, `H2D`, or `Custom` |
| Printer / Build Volume | `max_build_x/y/z` | Custom build volume (used only when `printer = "Custom"`) |
| Outer Dimensions | `width`, `depth`, `height` | Outer size in mm (auto-capped to build volume) |
| Front Opening | `front_height` | Height of the short front wall |
| Front Opening | `chamfer_len` | Length of the diagonal chamfer along the side walls (0 = vertical step) |
| Walls | `wall`, `floor_t` | Wall and floor thickness |
| Cosmetic | `bottom_chamfer` | Outer bottom-edge chamfer for elephant-foot relief |
| Quality | `$fn` | Render smoothness |

Geometric inputs are clamped internally, so any combination of slider values produces a valid model.

## Installing OpenSCAD

1. Download OpenSCAD for your platform from <https://openscad.org/downloads.html>
   - **Windows**: MSI or portable ZIP
   - **macOS**: DMG (Apple Silicon and Intel builds available)
   - **Linux**: AppImage, Snap, Flatpak, or your distro's package manager
2. Install and launch OpenSCAD.
3. Recommended: use the latest **development snapshot** — it ships a much improved Customizer and faster preview than the 2021 stable build.

## Using this model

1. Clone or download this repository:

   ```bash
   git clone https://github.com/BetaHydri/openscad-parametric-storage-bin.git
   ```

2. Open `storage-bin.scad` in OpenSCAD.
3. Open the **Customizer** panel (`Window → Customizer`) and adjust the parameters.
4. Press **F5** for a quick preview, **F6** for a full render.
5. Export the mesh: `File → Export → Export as STL…` (or `.3MF`).

## Printing

Recommended slicer settings (tested on Bambu Lab H2D with Bambu PLA Basic):

- **Layer height**: 0.20 mm
- **Walls / perimeters**: 3
- **Top / bottom layers**: 4
- **Infill**: 15 % gyroid (more if you need extra rigidity)
- **Supports**: none — the geometry is self-supporting
- **Brim**: optional; only needed for very tall/narrow bins
- **Orientation**: print flat on the build plate (floor down)

For a ready-to-print `.3mf` with profile-tuned settings, use the [MakerWorld print profile](https://makerworld.com/de/models/2867878-parametric-open-front-storage-bin#profileId-3204005).

### Bambu Studio project files

The [`print-profiles/`](print-profiles/) folder contains Bambu Studio `.3mf` project files for concrete fitments used in a HYMER Grand Canyon S camper — open them directly in Bambu Studio, re-slice if needed, and print. See [`print-profiles/README.md`](print-profiles/README.md) for details.

## License

Released under the [MIT License](LICENSE). Attribution is appreciated but not required.

## Contributing

Issues and pull requests are welcome — especially:

- Additional printer presets
- Cosmetic variants (rounded corners, dividers, label slot, magnet pockets)
- Improvements to the Customizer parameter ranges
