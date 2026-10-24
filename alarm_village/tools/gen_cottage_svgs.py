#!/usr/bin/env python3
"""Generates the cottage SVG states + anchor JSON for the proof of concept.

All art is original, drawn here from plain shapes (no third-party assets).
Canvas: 160 x 152 units. Origin for placement = bottom-centre ground contact (80, 146).
Keep SVGs simple for flame_svg: paths, rects, ellipses, solid fills. No filters, no text.

Run from the project root:  python tools/gen_cottage_svgs.py
"""
import json, os, random

OUT_SVG = os.path.join('assets', 'images', 'svg')
OUT_ANCHORS = os.path.join('assets', 'anchors')
W, H = 160, 152

WALL, WALL_S = '#fff1d0', '#f1dcb0'
ROOF, ROOF_S, ROOF_D, ROOF_L = '#e4604f', '#c94a3e', '#a83a32', '#f08a78'
STONE, STONE_S, STONE_D = '#b8bcc8', '#9aa0ad', '#7a808e'
WOOD, WOOD_D = '#8a5a3a', '#6d4429'
GLASS, GLASS_LIT = '#cfeaff', '#ffd98a'
SHUTTER = '#3fa862'
ASH, ASH_D, ASH_L = '#3a3438', '#1d1a1f', '#575156'
EMBER, EMBER_L = '#ff8a2a', '#ffd24a'


def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
            f'viewBox="0 0 {W} {H}">\n{body}\n</svg>\n')


def shadow():
    return '<ellipse cx="80" cy="146" rx="68" ry="8" fill="#1d3a1f" fill-opacity="0.22"/>'


def chimney():
    return (f'<rect x="106" y="12" width="24" height="60" rx="3" fill="{STONE}"/>'
            f'<rect x="120" y="12" width="10" height="60" rx="3" fill="{STONE_S}"/>'
            f'<rect x="102" y="8" width="32" height="9" rx="3" fill="{STONE_S}"/>'
            f'<rect x="110" y="8" width="16" height="3" rx="1.5" fill="#2b2f38"/>')


def walls():
    return (f'<rect x="24" y="68" width="112" height="78" rx="4" fill="{WALL}"/>'
            f'<path d="M92 68H132a4 4 0 0 1 4 4V142a4 4 0 0 1-4 4H92Z" fill="{WALL_S}"/>'
            f'<rect x="20" y="136" width="120" height="12" rx="3" fill="{STONE}"/>'
            f'<rect x="20" y="136" width="120" height="3" rx="1.5" fill="#d3d6df"/>'
            + ''.join(f'<rect x="{x}" y="141" width="14" height="2" rx="1" fill="{STONE_S}"/>' for x in (28, 50, 74, 98, 120)))


def roof():
    # tile lines are clipped to the roof outline by computing the slope edges per row
    tiles = ''
    for i, y in enumerate(range(40, 76, 7)):
        xl = 44 - (y - 28) * (38 / 50) + 5
        xr = 116 + (y - 28) * (38 / 50) - 5
        tiles += (f'<rect x="{xl + (i % 2) * 4:.1f}" y="{y}" width="{xr - xl - (i % 2) * 8:.1f}" height="1.6" '
                  f'fill="{ROOF_D}" fill-opacity="0.35"/>')
    return (f'<polygon points="6,78 44,28 80,28 80,78" fill="{ROOF}"/>'
            f'<polygon points="80,28 116,28 154,78 80,78" fill="{ROOF_S}"/>'
            f'<polygon points="6,78 44,28 52,28 14,78" fill="{ROOF_L}" fill-opacity="0.55"/>'
            + tiles +
            f'<rect x="4" y="76" width="152" height="6" rx="3" fill="{ROOF_D}"/>'
            f'<rect x="44" y="26" width="72" height="4" rx="2" fill="{ROOF_L}"/>')


def dormer(lit=False, broken=False):
    glass = ASH_D if broken else (GLASS_LIT if lit else GLASS)
    return (f'<rect x="62" y="44" width="36" height="26" fill="{WALL}"/>'
            f'<rect x="88" y="44" width="10" height="26" fill="{WALL_S}"/>'
            f'<rect x="70" y="48" width="20" height="16" rx="2" fill="{WOOD}"/>'
            f'<rect x="72" y="50" width="16" height="12" rx="1.5" fill="{glass}"/>'
            f'<rect x="79.3" y="50" width="1.4" height="12" fill="{WOOD}"/>'
            f'<polygon points="54,48 80,20 106,48" fill="{ROOF}"/>'
            f'<polygon points="80,20 106,48 80,48" fill="{ROOF_S}"/>'
            f'<polygon points="54,48 80,20 84,24 58,48" fill="{ROOF_L}" fill-opacity="0.55"/>'
            f'<rect x="52" y="46" width="56" height="4" rx="2" fill="{ROOF_D}"/>')


def door(lit=False):
    s = (f'<rect x="64" y="144" width="32" height="4" rx="2" fill="{STONE}"/>'
         f'<rect x="68" y="102" width="24" height="44" rx="10" fill="{WOOD_D}"/>'
         f'<rect x="70" y="104" width="20" height="42" rx="9" fill="{WOOD}"/>')
    s += ''.join(f'<rect x="{x}" y="108" width="1.2" height="38" fill="{WOOD_D}" fill-opacity="0.6"/>' for x in (75, 80, 85))
    s += f'<circle cx="86" cy="126" r="2" fill="#ffe082"/>'
    if lit:
        s += (f'<rect x="94" y="110" width="6" height="10" rx="2" fill="#2b2f38"/>'
              f'<rect x="95" y="111.5" width="4" height="7" rx="1.5" fill="{EMBER_L}"/>')
    return s


def window(x, lit=False, broken=False):
    y, w, h = 94, 22, 26
    glass = ASH_D if broken else (GLASS_LIT if lit else GLASS)
    shut = ASH if broken else SHUTTER
    s = (f'<rect x="{x - 6}" y="{y - 1}" width="5" height="{h + 2}" rx="1.5" fill="{shut}"/>'
         f'<rect x="{x + w + 1}" y="{y - 1}" width="5" height="{h + 2}" rx="1.5" fill="{shut}"/>'
         f'<rect x="{x - 2}" y="{y - 2}" width="{w + 4}" height="{h + 4}" rx="3" fill="{WOOD}"/>'
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="{glass}"/>')
    if not broken:
        s += (f'<rect x="{x + w / 2 - 0.7}" y="{y}" width="1.4" height="{h}" fill="{WOOD}"/>'
              f'<rect x="{x}" y="{y + h / 2 - 0.7}" width="{w}" height="1.4" fill="{WOOD}"/>')
        if not lit:
            s += f'<rect x="{x + 2}" y="{y + 2}" width="6" height="3" rx="1.5" fill="#ffffff" fill-opacity="0.7"/>'
    else:
        s += (f'<path d="M{x} {y + h} L{x + 8} {y + h - 9} L{x + 6} {y + h - 14} L{x + 14} {y + h - 18}" '
              f'stroke="{STONE_D}" stroke-width="1.2" fill="none"/>'
              f'<circle cx="{x + 15}" cy="{y + h - 5}" r="1.6" fill="{EMBER}"/>')
    s += (f'<rect x="{x - 3}" y="{y + h + 2}" width="{w + 6}" height="4" rx="2" fill="{WALL_S}"/>'
          f'<rect x="{x - 2}" y="{y + h + 5}" width="{w + 4}" height="6" rx="1.5" fill="{WOOD}"/>')
    if not broken:
        cols = ['#ff7a8a', '#ffd166', '#ffffff', '#ff7a8a', '#ffd166']
        for i, c in enumerate(cols):
            s += (f'<circle cx="{x + 2 + i * 4.5}" cy="{y + h + 4}" r="2" fill="{c}"/>'
                  f'<circle cx="{x + 2 + i * 4.5}" cy="{y + h + 7}" r="1.8" fill="#4aa65a"/>')
    return s


def glow(cx, cy, r, op):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{GLASS_LIT}" fill-opacity="{op * 0.45}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r * 0.62}" fill="{GLASS_LIT}" fill-opacity="{op * 0.55}"/>')


def healthy(lit=False):
    s = shadow() + chimney() + walls() + window(36, lit) + window(102, lit) + door(lit) + roof() + dormer(lit)
    if lit:
        s = (shadow() + chimney() + walls() + glow(47, 107, 30, 1) + glow(113, 107, 30, 1) + glow(80, 56, 16, 1) +
             window(36, True) + window(102, True) + door(True) + roof() + dormer(True))
    return svg(s)


def damaged():
    r = random.Random(4)
    s = shadow() + chimney() + walls() + window(36, broken=True) + window(102, broken=True) + door() + roof() + dormer(broken=True)
    # soot streaks climbing from the windows and along the eaves
    for x in (33, 99):
        s += (f'<path d="M{x} 92 C{x - 3} 86 {x + 4} 84 {x + 2} 80 L{x + 20} 80 C{x + 18} 84 {x + 24} 86 {x + 22} 92Z" '
              f'fill="{ASH_D}" fill-opacity="0.4"/>')
    # roof holes with burning edges and charred rafters
    for pts in ('32,66 46,52 58,58 52,72 38,74', '104,60 120,50 132,60 126,72 110,72'):
        s += f'<polygon points="{pts}" fill="#1c1416" stroke="{EMBER}" stroke-width="1.6" stroke-linejoin="round"/>'
    s += (f'<path d="M34 72 L56 54" stroke="{WOOD_D}" stroke-width="2.6"/>'
          f'<path d="M126 70 L108 52" stroke="{WOOD_D}" stroke-width="2.6"/>')
    # soot on the foundation and the door
    s += f'<rect x="20" y="136" width="120" height="12" rx="3" fill="{ASH_D}" fill-opacity="0.3"/>'
    s += f'<path d="M68 102 H92 V110 C86 106 74 112 68 108Z" fill="{ASH_D}" fill-opacity="0.45"/>'
    for _ in range(14):
        x, y = r.uniform(28, 132), r.uniform(70, 140)
        s += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r.uniform(1.4, 3.4):.1f}" fill="{ASH_D}" fill-opacity="{r.uniform(.2, .4):.2f}"/>'
    for (x, y) in ((40, 62), (50, 56), (118, 55), (126, 64), (22, 142), (136, 142), (80, 100)):
        s += f'<circle cx="{x}" cy="{y}" r="1.6" fill="{EMBER}"/><circle cx="{x}" cy="{y}" r="0.7" fill="{EMBER_L}"/>'
    return svg(s)


def ruined():
    r = random.Random(11)
    s = f'<ellipse cx="80" cy="140" rx="72" ry="12" fill="{ASH_D}" fill-opacity="0.85"/>'
    # surviving chimney stub with a jagged top
    s += (f'<path d="M106 146 V82 L110 76 L114 80 L119 72 L124 79 L130 74 V146Z" fill="{STONE_S}"/>'
          f'<path d="M120 146 V78 L124 79 L130 74 V146Z" fill="{STONE_D}"/>'
          f'<path d="M106 120 C110 112 112 100 108 90 L114 90 C118 104 114 114 118 124Z" fill="{ASH_D}" fill-opacity="0.45"/>')
    # broken wall corner and foundation segments
    s += (f'<path d="M22 146 V104 L32 98 L38 110 L46 102 L54 146Z" fill="{ASH_L}"/>'
          f'<path d="M44 146 L46 102 L54 146Z" fill="{ASH}"/>'
          f'<rect x="20" y="136" width="36" height="10" rx="2" fill="{STONE_S}"/>'
          f'<rect x="62" y="140" width="26" height="6" rx="2" fill="{STONE_S}"/>'
          f'<rect x="96" y="138" width="40" height="8" rx="2" fill="{STONE_S}"/>')
    # charred beams
    for (x1, y1, x2, y2, w) in ((26, 100, 70, 138, 4), (130, 84, 84, 134, 4), (40, 130, 112, 122, 3), (58, 96, 98, 136, 2.4)):
        s += f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{ASH_D}" stroke-width="{w}" stroke-linecap="round"/>'
        s += f'<path d="M{x1} {y1 - 1} L{x2} {y2 - 1}" stroke="{ASH_L}" stroke-width="1" stroke-linecap="round"/>'
    # rubble: ash, roof-tile shards, stones
    cols = [ASH, ASH_D, ASH_L, ROOF_D, ROOF_S, STONE_D]
    for _ in range(90):
        x, y = r.gauss(78, 22), r.gauss(138, 5)
        if 18 < x < 142 and 124 < y < 147:
            wd, ht = r.uniform(2, 6), r.uniform(1.4, 3.4)
            s += f'<rect x="{x:.1f}" y="{y:.1f}" width="{wd:.1f}" height="{ht:.1f}" rx="0.8" fill="{r.choice(cols)}"/>'
    for (x, y) in ((34, 134), (60, 142), (84, 136), (98, 144), (126, 140), (70, 130), (112, 132), (48, 128)):
        s += f'<circle cx="{x}" cy="{y}" r="1.7" fill="{EMBER}"/><circle cx="{x}" cy="{y}" r="0.7" fill="{EMBER_L}"/>'
    return svg(s)


ANCHORS = {
    'name': 'cottage',
    'canvas': [W, H],
    'origin': 'bottom_center',
    'windows': [[47, 107], [113, 107], [80, 56]],
    'door_lantern': [97, 115],
    'chimney': [118, 8],
    # on_building fires fade out when the building turns to ruins; ground fires stay.
    'fire_points': [
        {'x': 40, 'y': 66, 'appear_at': 0.12, 'size': 46, 'on_building': True},
        {'x': 120, 'y': 62, 'appear_at': 0.22, 'size': 46, 'on_building': True},
        {'x': 80, 'y': 104, 'appear_at': 0.34, 'size': 40, 'on_building': True},
        {'x': 126, 'y': 134, 'appear_at': 0.48, 'size': 36, 'on_building': False},
        {'x': 30, 'y': 138, 'appear_at': 0.56, 'size': 34, 'on_building': False},
        {'x': 80, 'y': 140, 'appear_at': 0.62, 'size': 38, 'on_building': False},
        {'x': 56, 'y': 136, 'appear_at': 0.66, 'size': 30, 'on_building': False},
    ],
}


def main():
    os.makedirs(OUT_SVG, exist_ok=True); os.makedirs(OUT_ANCHORS, exist_ok=True)
    files = {'healthy': healthy(False), 'lit': healthy(True), 'damaged': damaged(), 'ruined': ruined()}
    for state, content in files.items():
        with open(os.path.join(OUT_SVG, f'building_cottage_{state}.svg'), 'w') as f:
            f.write(content)
    with open(os.path.join(OUT_ANCHORS, 'cottage.json'), 'w') as f:
        json.dump(ANCHORS, f, indent=2)
    print('wrote', ', '.join(files), 'and cottage.json')


if __name__ == '__main__':
    main()
