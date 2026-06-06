#!/usr/bin/env python3
"""Generate one STL per name by driving the OpenSCAD CLI."""

import argparse
import json
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Generate name keychain STLs from a JSON file.")
    parser.add_argument("names_file", nargs="?", default="names.json",
                        help="JSON file containing a list of name strings (default: names.json)")
    parser.add_argument("--scad", default="name_keychains.scad",
                        help="Path to the .scad file (default: name_keychains.scad)")
    parser.add_argument("--out-dir", default=".", metavar="DIR",
                        help="Directory for the generated STL files (default: current dir)")
    parser.add_argument("--openscad", default="openscad",
                        help="OpenSCAD executable (default: openscad)")
    args = parser.parse_args()

    names_path = Path(args.names_file)
    if not names_path.exists():
        sys.exit(f"Error: names file not found: {names_path}")

    with names_path.open() as f:
        names = json.load(f)

    if not isinstance(names, list) or not all(isinstance(n, str) for n in names):
        sys.exit("Error: JSON file must contain a list of strings.")

    scad_path = Path(args.scad)
    if not scad_path.exists():
        sys.exit(f"Error: SCAD file not found: {scad_path}")

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    for name in names:
        safe = name.replace(" ", "_")
        out_file = out_dir / f"{safe}.stl"
        # Override the names array so only this single name is rendered.
        override = f'names=["{name}"]'
        cmd = [args.openscad, "--enable=textmetrics", "-D", override, "-o", str(out_file), str(scad_path)]
        print(f"Rendering {name!r} -> {out_file} ...", flush=True)
        result = subprocess.run(cmd)
        if result.returncode != 0:
            print(f"  WARNING: openscad exited with code {result.returncode} for {name!r}")

    print("Done.")


if __name__ == "__main__":
    main()
