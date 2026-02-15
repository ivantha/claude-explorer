#!/usr/bin/env python3
"""Generate macOS app icon set for Claude Explorer.

Design: Abstract gauge arc on dark background — representing usage monitoring.
- Background: Dark indigo-charcoal (#1C1C2E)
- Main element: 270-degree circular arc, warm amber (#E8873A) to coral (#D4533B)
- Accent: Golden indicator dot (#FFD166) at ~70% of the arc
"""

import json
import math
import os
from pathlib import Path

from PIL import Image, ImageDraw

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
ICON_DIR = PROJECT_ROOT / "ClaudeExplorer" / "Assets.xcassets" / "AppIcon.appiconset"

# Colors
BG_COLOR = (28, 28, 46)        # #1C1C2E — dark indigo-charcoal
AMBER = (232, 135, 58)         # #E8873A — warm amber
CORAL = (212, 83, 59)          # #D4533B — coral
DOT_COLOR = (255, 209, 102)    # #FFD166 — golden indicator

# Icon sizes: (base_size, scale, filename)
ICON_SPECS = [
    (16,  1, "icon_16x16.png"),
    (16,  2, "icon_16x16@2x.png"),
    (32,  1, "icon_32x32.png"),
    (32,  2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png"),
]

SUPERSAMPLE = 4  # render at 4x then downscale


def lerp_color(c1, c2, t):
    """Linearly interpolate between two RGB colors."""
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def draw_icon(size):
    """Draw the icon at the given pixel size, using supersampling."""
    render_size = size * SUPERSAMPLE
    img = Image.new("RGBA", (render_size, render_size), (*BG_COLOR, 255))
    draw = ImageDraw.Draw(img)

    cx = cy = render_size / 2
    # Arc radius and thickness proportional to image size
    radius = render_size * 0.35
    thickness = render_size * 0.10

    # Draw the 270-degree arc as many small segments for gradient effect.
    # Arc starts at 135 degrees (bottom-left) and sweeps 270 degrees clockwise.
    start_angle = 135  # degrees
    sweep = 270
    num_segments = 360

    for i in range(num_segments):
        t0 = i / num_segments
        t1 = (i + 1) / num_segments
        angle0 = start_angle + sweep * t0
        angle1 = start_angle + sweep * t1

        # Gradient from amber to coral along the arc
        color = lerp_color(AMBER, CORAL, t0)

        # Bounding box for the arc
        bbox = [
            cx - radius, cy - radius,
            cx + radius, cy + radius,
        ]
        draw.arc(bbox, angle0, angle1, fill=color, width=int(thickness))

    # Draw indicator dot at ~70% of the arc
    dot_t = 0.70
    dot_angle_deg = start_angle + sweep * dot_t
    dot_angle_rad = math.radians(dot_angle_deg)
    dot_x = cx + radius * math.cos(dot_angle_rad)
    dot_y = cy + radius * math.sin(dot_angle_rad)
    dot_r = thickness * 0.55
    draw.ellipse(
        [dot_x - dot_r, dot_y - dot_r, dot_x + dot_r, dot_y + dot_r],
        fill=(*DOT_COLOR, 255),
    )

    # Downscale with LANCZOS for crisp result
    img = img.resize((size, size), Image.LANCZOS)
    return img


def generate_contents_json():
    """Generate the Contents.json with filename entries."""
    images = []
    size_map = {
        (16, 1): "icon_16x16.png",
        (16, 2): "icon_16x16@2x.png",
        (32, 1): "icon_32x32.png",
        (32, 2): "icon_32x32@2x.png",
        (128, 1): "icon_128x128.png",
        (128, 2): "icon_128x128@2x.png",
        (256, 1): "icon_256x256.png",
        (256, 2): "icon_256x256@2x.png",
        (512, 1): "icon_512x512.png",
        (512, 2): "icon_512x512@2x.png",
    }
    for (base_size, scale), filename in sorted(size_map.items()):
        images.append({
            "filename": filename,
            "idiom": "mac",
            "scale": f"{scale}x",
            "size": f"{base_size}x{base_size}",
        })

    contents = {
        "images": images,
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }
    return contents


def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True)

    print("Generating macOS app icons for Claude Explorer...")
    for base_size, scale, filename in ICON_SPECS:
        pixel_size = base_size * scale
        img = draw_icon(pixel_size)
        out_path = ICON_DIR / filename
        img.save(out_path, "PNG")
        print(f"  {filename} ({pixel_size}x{pixel_size}px)")

    # Write Contents.json
    contents = generate_contents_json()
    contents_path = ICON_DIR / "Contents.json"
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)
        f.write("\n")
    print(f"  Contents.json updated")

    print(f"\nAll icons written to {ICON_DIR}")


if __name__ == "__main__":
    main()
