# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A single-file OpenSCAD project that generates 3D-printable bubble-letter name keychains. Each name produces one tag with a hole/ring at the front for a metal clip or keyring. Multiple names are laid out vertically on the build plate in one file.

**Requires**: OpenSCAD 2021.01+ (uses `textmetrics()`) and `Sniglet.ttf` (bundled in this directory).

## Rendering

Open `name_keychains.scad` in OpenSCAD and press **F6** to render (or **F5** for preview). Export with **File → Export → Export as STL**.

From the CLI:
```bash
openscad -o output.stl name_keychains.scad
```

## Key Parameters (top of file)

| Variable | Purpose |
|---|---|
| `names` | List of names to generate — one tag per entry |
| `text_size` | Letter height in mm |
| `thickness` | Tag depth in mm |
| `connection_mode` | `"backing"` (solid plate), `"bar"` (bottom strip), or `"none"` |
| `ring_outer_d` / `ring_hole_d` | Clip ring dimensions |
| `letter_spacing` | Values < 1 push letters together for the bubble-letter effect |

## Architecture

The file has two modules and one loop:

- `ring()` — extruded flat disc with a center hole for the clip.
- `name_tag(name)` — uses `textmetrics()` to measure the rendered text, then `union()`s the letters, ring, neck connector, and the chosen connection structure.
- The top-level `for` loop translates each `name_tag()` downward by `text_size + name_gap` so all tags sit side-by-side on the print bed.

The font file `Sniglet.ttf` must stay in the same directory as the `.scad` file (referenced via `use <Sniglet.ttf>`).
