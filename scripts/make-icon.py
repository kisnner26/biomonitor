#!/usr/bin/env python3
"""genera el icono de 1024 px: emblema rojo y blanco de umbrella sobre negro, con un pulso verde."""
import math, sys
from PIL import Image, ImageDraw, ImageFilter

S = 4                      # supersampling
N = 1024 * S
c = N // 2
img = Image.new("RGB", (N, N), (6, 8, 9))
d = ImageDraw.Draw(img)

# vineta suave de fondo
bg = Image.new("RGB", (N, N), (6, 8, 9))
glow = Image.new("L", (N, N), 0)
ImageDraw.Draw(glow).ellipse([c - 470 * S, c - 470 * S, c + 470 * S, c + 470 * S], fill=70)
glow = glow.filter(ImageFilter.GaussianBlur(160 * S))
red_glow = Image.new("RGB", (N, N), (120, 8, 12))
img = Image.composite(red_glow, bg, glow)
d = ImageDraw.Draw(img)

RED = (214, 24, 32)
WHITE = (242, 240, 236)
R = 372 * S

# aro exterior
d.ellipse([c - R - 34 * S, c - R - 34 * S, c + R + 34 * S, c + R + 34 * S], outline=WHITE, width=12 * S)

# ocho gajos alternos, como el paraguas visto desde arriba
for k in range(8):
    a0 = -90 - 22.5 + k * 45
    a1 = a0 + 45
    col = RED if k % 2 == 0 else WHITE
    d.pieslice([c - R, c - R, c + R, c + R], a0, a1, fill=col)

# separaciones negras entre gajos
for k in range(8):
    a = math.radians(-90 - 22.5 + k * 45)
    d.line([c, c, c + math.cos(a) * R, c + math.sin(a) * R], fill=(6, 8, 9), width=9 * S)

# centro: disco negro con un pulso verde dentro
CR = 168 * S
d.ellipse([c - CR, c - CR, c + CR, c + CR], fill=(6, 8, 9))
d.ellipse([c - CR, c - CR, c + CR, c + CR], outline=WHITE, width=9 * S)

def ecg(p):
    g = lambda x, m, s: math.exp(-((x - m) ** 2) / (2 * s * s))
    return 0.15 * g(p, .16, .035) - .13 * g(p, .34, .012) + g(p, .37, .011) - .30 * g(p, .40, .012) + .27 * g(p, .62, .05)

def stroke(layer, pts, color, w):
    ld = ImageDraw.Draw(layer)
    for (x, y) in pts:
        ld.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=color)
    for a, b in zip(pts, pts[1:]):
        ld.line([a, b], fill=color, width=int(w))

pts = []
x0, x1 = c - 130 * S, c + 130 * S
for i in range(900):
    t = i / 899
    pts.append((x0 + (x1 - x0) * t, c + 36 * S - ecg(0.04 + t * 0.78) * 150 * S))
pulse = Image.new("RGBA", (N, N), (0, 0, 0, 0))
stroke(pulse, pts, (70, 238, 100, 255), 15 * S)
halo = pulse.filter(ImageFilter.GaussianBlur(10 * S))
img = Image.alpha_composite(img.convert("RGBA"), halo)
img = Image.alpha_composite(img, pulse)

img = img.convert("RGB").resize((1024, 1024), Image.LANCZOS)
out = sys.argv[1] if len(sys.argv) > 1 else "icon-1024.png"
img.save(out)
print("ok", out)
