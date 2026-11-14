#!/usr/bin/env python3
"""One-time layout record for the three market shop rooms, version 4 (2026-11-12).

    python3 art/source/world/shop-interiors/v2/layout_rooms.py [bakery|greengrocer|tailor ...]

Copies each current room document to content/areas/archive/shop-<trade>-v3.json (once), then writes version 4: the
new furniture, pendants, inspections and keeper rounds. Ids a save or quest may hold are kept: the lamps
(`shop-pendant-1`, `shop-pendant-2`, `oven-fire`, `sewing-lamp`), the boards and their commissions, the door link,
the spawn and the keepers. After this, the room documents are the authority; edit them, not this record.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
AREAS = ROOT / 'content/areas'


def asset(id, model, at, turn=0, height=0.0, solid=True):
    item = {'id': id, 'asset': model, 'at': [round(at[0], 3), round(at[1], 3)], 'turn': turn, 'height': height, 'scale': 1}
    if solid:
        item['solid'] = True
    return item


def lamp(id, at, stand=(6, 3), title=None):
    item = {'id': id, 'zone': 'shop-floor', 'at': [at[0], at[1]], 'style': 'fixture', 'stand': list(stand), 'automatic': True,
            'requires': 'field-tablet'}
    if title:
        item['title'] = title
    return item


def inspection(id, at, title, text):
    return {'id': id, 'at': list(at), 'title': title, 'text': text}


# ------------------------------------------------------------------------------------------------- Morning Loaf
def bakery(doc):
    pendants = [((3.4, 4.3), 4.1), ((7.75, 7.55), 4.1), ((10.3, 2.9), 4.1), ((3.2, 7.45), 4.1)]
    interior = doc['interior']
    interior['assets'] = [
        asset('oven', 'bakery-oven', (2.75, 10.45)),
        asset('proving-cabinet', 'bakery-proving-cabinet', (-.2, 9.95), 90),
        asset('flour-sacks', 'bakery-flour-sacks', (.06, 8.15), 90),
        asset('dresser', 'bakery-dresser', (-.22, 5.6), 90),
        asset('cafe-window', 'bakery-cafe-table', (.5, 3.0), 90),
        asset('cake-table', 'bakery-cake-table', (3.4, 4.3)),
        asset('proving-table', 'bakery-proving-table', (3.2, 7.45)),
        asset('mixer', 'bakery-mixer', (5.2, 10.3)),
        asset('serving-counter', 'bakery-counter', (7.75, 7.9)),
        asset('bread-wall', 'bakery-bread-wall', (8.05, 11.19)),
        asset('cooling-rack', 'bakery-cooling-rack', (10.8, 9.95)),
        asset('cafe-front', 'bakery-cafe-table', (10.3, 1.7)),
        asset('cafe-middle', 'bakery-cafe-table', (10.3, 4.15)),
        asset('pretzel-stand', 'bakery-pretzel-stand', (7.6, 2.3)),
        asset('gift-stand', 'bakery-gift-stand', (8.85, 4.75)),
        asset('bake-board-model', 'shop-chalk-board', (8.05, 11.36), 0, 2.85, False),
    ] + [asset(f'shop-pendant-{i + 1}-model', 'bakery-pendant', at, 0, h, False) for i, (at, h) in enumerate(pendants)]
    doc['lamps'] = [lamp(f'shop-pendant-{i + 1}', at) for i, (at, _) in enumerate(pendants)] + \
                   [lamp('oven-fire', (2.75, 9.4), (4, 9), 'Oven fire')]
    interior['lamp_fixtures'] = [{'id': f'shop-pendant-{i + 1}', 'asset': f'shop-pendant-{i + 1}-model', 'range': 6.5, 'energy': 1.1}
                                 for i in range(len(pendants))] + [{'id': 'oven-fire', 'asset': 'oven', 'range': 5.0, 'energy': 1.2}]
    old = {item['id']: item for item in interior['inspections']}
    interior['inspections'] = [
        old['bake-order'],
        inspection('bread-oven', (1, 9), 'The oven',
                   'Warm right through the brick. KETTERING 1885 on the brass plate, polished where a sleeve rubs it. '
                   'Somebody has chalked a row of ticks on the chimney, then rubbed half of them out.'),
        inspection('bread-racks', (8, 10), 'The bread wall',
                   'Rounds on the left, tins on the right, plaits in the middle where people can see them. Each basket '
                   'has a price tag, and a time pencilled on the back of the tag.'),
        inspection('proving-bowls', (3, 6), 'Proving baskets',
                   'Dough rising in cane baskets. One basket has a pencil line inside the rim, a finger’s width above '
                   'the dough.'),
        inspection('cake-table', (2, 3), 'The cake table',
                   'Three tiers. On the top, a wedding cake with sugar roses and a card: FOR THE HALL — SATURDAY. '
                   'DO NOT TOUCH. That has been underlined twice.'),
        inspection('station-clock', (1, 1), 'The clock',
                   'Four minutes fast. On the frame, in pencil: so the bread is never late.'),
        inspection('mixer', (5, 9), 'The mixer',
                   'Green enamel, a brass badge that says No 2, and a hand wheel for when the power drops. '
                   'There is no No 1 anywhere in the shop.'),
    ]
    for villager in doc['villagers']:
        if villager['id'] == 'ada':
            villager['at'] = [8, 9]
            villager['route'] = [[8, 9], [3, 9], [10, 9]]
            villager['errands'] = [{'target': 'serving-counter', 'activity': 'trade', 'seconds': 8.0},
                                   {'target': 'oven', 'activity': 'inspect', 'seconds': 10.0},
                                   {'target': 'cooling-rack', 'activity': 'inspect', 'seconds': 6.0}]


# ------------------------------------------------------------------------------------------------- The Pantry
def greengrocer(doc):
    pendants = [((3.6, 6.4), 4.1), ((7.8, 7.5), 4.1), ((4.0, 2.7), 4.1)]
    interior = doc['interior']
    interior['assets'] = [
        asset('bin-wall', 'greengrocer-bin-wall', (2.0, 11.2)),
        asset('jar-shelves', 'greengrocer-jar-shelves', (8.4, 11.25)),
        asset('grocer-counter', 'greengrocer-counter', (7.8, 7.7)),
        asset('produce-stand', 'greengrocer-produce-stand', (3.6, 6.4)),
        asset('barrow', 'greengrocer-barrow', (4.15, 2.7)),
        asset('flower-stand', 'greengrocer-flower-stand', (-.05, 1.3), 90),
        asset('barrels', 'greengrocer-barrels', (0.0, 4.2), 90),
        asset('dairy', 'greengrocer-dairy', (-.2, 6.9), 90),
        asset('sack-row', 'greengrocer-sack-row', (.05, 9.3), 90),
        asset('squash-pallet', 'greengrocer-squash-pallet', (10.4, 1.4)),
        asset('crate-stack', 'greengrocer-crate-stack', (10.75, 9.6)),
        asset('basket-table', 'greengrocer-basket-table', (8.0, 4.2)),
        asset('platform-scale', 'greengrocer-platform-scale', (10.6, 6.4), 270),
        asset('basket-stack', 'greengrocer-basket-stack', (7.3, .9)),
        asset('price-board-model', 'shop-chalk-board', (8.4, 11.36), 0, 2.95, False),
    ] + [asset(f'shop-pendant-{i + 1}-model', 'greengrocer-pendant', at, 0, h, False) for i, (at, h) in enumerate(pendants)]
    doc['lamps'] = [lamp(f'shop-pendant-{i + 1}', at) for i, (at, _) in enumerate(pendants)]
    interior['lamp_fixtures'] = [{'id': f'shop-pendant-{i + 1}', 'asset': f'shop-pendant-{i + 1}-model', 'range': 6.5, 'energy': 1.1}
                                 for i in range(len(pendants))]
    old = {item['id']: item for item in interior['inspections']}
    interior['inspections'] = [
        old['price-order'],
        dict(old['produce'], at=[4, 5]),
        dict(old['jars'], at=[9, 10]),
        dict(old['scale'], at=[8, 7]),
        inspection('barrow', (3, 2), "Teo's barrow",
                   'Brought in off the street for the day. T. VASKO \u00b7 FRUIT & VEG on the board, and under the new '
                   'paint, older letters showing through: VASKO & CO.'),
        inspection('bins', (2, 10), 'The bins',
                   'Rice, lentils, beans, oats, sugar, coffee. The coffee bin is nearly empty and smells wonderful. Chalked '
                   'on its lid: ASK TESSA, NOT ME. \u2014 T.V.'),
        inspection('flowers', (1, 2), 'The flower buckets',
                   'Tulips, sunflowers, sweet peas. A paper tag tied to the sunflowers: KEEP SIX BACK FOR MIRA.'),
    ]
    for villager in doc['villagers']:
        if villager['id'] == 'pantry-tessa':
            villager['at'] = [8, 9]
            villager['route'] = [[8, 9], [4, 5], [1, 1]]
            villager['errands'] = [{'target': 'grocer-counter', 'activity': 'trade', 'seconds': 8.0},
                                   {'target': 'produce-stand', 'activity': 'inspect', 'seconds': 7.0},
                                   {'target': 'flower-stand', 'activity': 'inspect', 'seconds': 6.0}]


# ------------------------------------------------------------------------------------------------- Finch & Thread
def tailor(doc):
    lights = [((5.6, 7.0), 4.1), ((2.0, 5.8), 4.1), ((9.3, 5.2), 4.1)]
    interior = doc['interior']
    interior['assets'] = [
        asset('fitting-room', 'tailor-fitting-room', (.22, 10.78)),
        asset('spool-wall', 'tailor-spool-wall', (2.75, 11.22)),
        asset('sewing-table', 'tailor-sewing-table', (5.25, 10.75)),
        asset('order-rail', 'tailor-order-rail', (8.25, 11.2)),
        asset('hat-stand', 'tailor-hat-stand', (10.85, 10.9)),
        asset('cheval-mirror', 'tailor-mirror', (.55, 8.6), 90),
        asset('settee', 'tailor-settee', (-.05, 5.8), 90),
        asset('rug', 'tailor-rug', (2.0, 5.8), 90, 0.0, False),
        asset('cloth-shelves', 'tailor-cloth-shelves', (-.2, 2.2), 90),
        asset('cutting-table', 'tailor-cutting-table', (5.6, 7.0)),
        asset('dress-form-coat', 'tailor-dress-form', (3.3, 8.4)),
        asset('dress-form-window', 'tailor-dress-form-gown', (9.9, 2.3)),
        asset('dress-form-suit', 'tailor-dress-form-suit', (4.1, 3.6)),
        asset('haberdashery', 'tailor-counter', (9.3, 5.3)),
        asset('pressing', 'tailor-pressing', (10.2, 8.5)),
        asset('order-board-model', 'shop-chalk-board', (8.25, 11.36), 0, 2.95, False),
    ] + [asset(f'shop-pendant-{i + 1}-model', 'tailor-chandelier', at, 0, h, False) for i, (at, h) in enumerate(lights)]
    doc['lamps'] = [lamp(f'shop-pendant-{i + 1}', at) for i, (at, _) in enumerate(lights)] + \
                   [lamp('sewing-lamp', (4.95, 10.77), (5, 9), 'Sewing lamp')]
    interior['lamp_fixtures'] = [{'id': f'shop-pendant-{i + 1}', 'asset': f'shop-pendant-{i + 1}-model', 'range': 6.5, 'energy': 1.1}
                                 for i in range(len(lights))] + [{'id': 'sewing-lamp', 'asset': 'sewing-table', 'range': 3.0, 'energy': .8}]
    old = {item['id']: item for item in interior['inspections']}
    interior['inspections'] = [
        old['order-ticket'],
        dict(old['cloth'], at=[1, 3]),
        dict(old['coat-in-progress'], at=[3, 8]),
        dict(old['spools'], at=[3, 10]),
        inspection('gown', (9, 2), 'The gown in the window',
                   'Wine velvet, with a blush sash. A card pinned to the hem: FOR THE BAND\u2019S SINGER \u2014 SATURDAY. '
                   'HEM NOT DONE.'),
        inspection('fitting-room', (1, 9), 'The fitting booth',
                   'A curtain, a stool and a looking glass. Pinned inside the curtain, a list of measurements in a small '
                   'hand, with one figure crossed out three times.'),
        inspection('buttons', (9, 4), 'Buttons',
                   'Hundreds of them under the glass, sorted by colour and then by size. The fullest tray is labelled ODDS.'),
    ]
    for villager in doc['villagers']:
        if villager['id'] == 'gret':
            villager['at'] = [6, 8]
            villager['route'] = [[6, 8], [5, 9], [9, 6]]
            villager['errands'] = [{'target': 'cutting-table', 'activity': 'inspect', 'seconds': 9.0},
                                   {'target': 'sewing-table', 'activity': 'inspect', 'seconds': 9.0},
                                   {'target': 'haberdashery', 'activity': 'trade', 'seconds': 7.0}]


SHOPS = {'bakery': bakery, 'greengrocer': greengrocer, 'tailor': tailor}


def main():
    chosen = sys.argv[1:] or list(SHOPS)
    for shop in chosen:
        path = AREAS / f'shop-{shop}.json'
        doc = json.loads(path.read_text())
        archive = AREAS / 'archive' / f'shop-{shop}-v3.json'
        if not archive.exists():
            if doc.get('version') != 3:
                raise SystemExit(f'{path.name} is version {doc.get("version")}; this record expects version 3 to archive')
            archive.write_text(path.read_text())
        SHOPS[shop](doc)
        doc['version'] = 4
        path.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + '\n')
        print('laid out', path.name)


if __name__ == '__main__':
    main()
