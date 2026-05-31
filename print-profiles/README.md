# Bambu Studio print profiles

Ready-to-use [Bambu Studio](https://bambulab.com/en/download/studio) project files (`.3mf`) for specific real-world fitments of the parametric storage bin. Open in Bambu Studio, slice, and print.

These were designed for the technical / under-seat compartments of a **HYMER Grand Canyon S** camper but are useful as concrete reference dimensions and as a starting point for your own variants.

| File | Purpose | Notes |
|---|---|---|
| `ObenBoxX2.gcode.3mf` | Upper bin (×2 plated) | Already sliced — contains G-code, ready to print on a Bambu printer |
| `OberhalbGas.3mf` | Bin above the gas locker | Project file (re-slice for your printer/filament) |
| `UntenBox.3mf` | Lower bin | Project file (re-slice for your printer/filament) |

## How to use

1. Install [Bambu Studio](https://bambulab.com/en/download/studio).
2. Double-click the `.3mf` file or open it via **File → Open Project**.
3. Adjust filament / printer profile to match your hardware if needed.
4. Re-slice (project files) or send directly (the `.gcode.3mf`).

## Generating your own variant

If your compartment dimensions differ, generate a new STL/3MF from [`../storage-bin.scad`](../storage-bin.scad) using OpenSCAD (see the [main README](../README.md)) or the [MakerWorld Parametric Maker](https://makerworld.com/de/models/2867878-parametric-open-front-storage-bin#profileId-3204005), then import the mesh into Bambu Studio.
