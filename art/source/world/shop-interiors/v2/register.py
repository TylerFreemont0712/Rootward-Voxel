#!/usr/bin/env python3
"""Records the second-pass shop models in pipeline/world-catalog.json (2026-11-12).

    python3 art/source/world/shop-interiors/v2/register.py [asset-id ...]

Existing ids move to their new version (the earlier version's source stays on disk); new ids are added. Footprints
are logical [min_x, min_y, width, height] in the model's own frame, front toward -y; area documents own placement.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
CATALOG = ROOT / 'pipeline/world-catalog.json'
RECORD = 'art/source/world/shop-interiors/v2/'
PIVOT = 'Ground centre; Blender -Y front, +Y logical north.'
FURNITURE = ('Reusable visual; the area document owns placement, collision, inspections and any lamp or sign role.')

# id: (version, label, footprint or None, record file, extra behaviour)
ASSETS = {
    # Morning Loaf
    'bakery-shell': ('v2', 'Morning Loaf · cutaway room (tiled)', None, 'author_bakery.py',
                     'Room shell with a hinged oxblood door (`door_leaf_bakery`); the room document owns collision.'),
    'bakery-oven': ('v2', 'Morning Loaf beehive bread oven', [-2.0, -1.2, 3.65, 2.2], 'author_bakery.py',
                    'The fire and embers are one lamp-glass mesh, bound by the room as the `oven-fire` fixture.'),
    'bakery-bread-wall': ('v1', 'Bread wall of baskets and cupboards', [-1.85, -.34, 3.7, .62], 'author_bakery.py', ''),
    'bakery-counter': ('v2', 'Marble serving counter with patisserie case', [-1.95, -.5, 3.9, 1.0], 'author_bakery.py', ''),
    'bakery-cake-table': ('v1', 'Round three-tier cake table', [-.78, -.78, 1.56, 1.56], 'author_bakery.py', ''),
    'bakery-proving-table': ('v2', "Baker's bench with dough and proving baskets", [-1.35, -.55, 2.7, 1.1], 'author_bakery.py', ''),
    'bakery-proving-cabinet': ('v1', 'Glazed proving cabinet', [-.62, -.62, 1.24, 1.0], 'author_bakery.py', ''),
    'bakery-mixer': ('v1', 'Green enamel dough mixer', [-.45, -.35, .9, .97], 'author_bakery.py', ''),
    'bakery-flour-sacks': ('v2', 'Flour sacks on a pallet with a bin', [-.95, -.6, 1.9, 1.1], 'author_bakery.py', ''),
    'bakery-cooling-rack': ('v1', 'Wheeled cooling rack of trays', [-.42, -.35, .84, .7], 'author_bakery.py', ''),
    'bakery-cafe-table': ('v1', 'Marble bistro table and bentwood chairs', [-.85, -.45, 1.7, .9], 'author_bakery.py', ''),
    'bakery-dresser': ('v1', 'Bakery dresser of china, tins and moulds', [-1.05, -.32, 2.1, .6], 'author_bakery.py', ''),
    'bakery-pretzel-stand': ('v1', 'Pretzel tree with a tray of rolls', [-.34, -.34, .68, .68], 'author_bakery.py', ''),
    'bakery-gift-stand': ('v1', 'Étagère of jams, biscuits and boxed cakes', [-.58, -.25, 1.16, .5], 'author_bakery.py', ''),
    'bakery-pendant': ('v1', 'Green enamel pendant lamp', None, 'author_bakery.py',
                       'Its bulb is lamp glass: a room binds the placed pendant as a fixture.'),
    # The Pantry
    'greengrocer-shell': ('v2', 'The Pantry · cutaway room (green boards)', None, 'author_greengrocer.py',
                          'Room shell with a hinged bottle-green door (`door_leaf_pantry`); the room document owns collision.'),
    'greengrocer-produce-stand': ('v2', 'Double-sided produce island', [-1.58, -.72, 3.16, 1.44], 'author_greengrocer.py', ''),
    'greengrocer-counter': ('v2', 'Provisions counter with cheese case and coffee mill', [-1.95, -.5, 3.9, 1.0], 'author_greengrocer.py', ''),
    'greengrocer-jar-shelves': ('v2', 'Dresser of preserves with a library ladder', [-1.82, -.9, 3.64, 1.15], 'author_greengrocer.py', ''),
    'greengrocer-bin-wall': ('v1', 'Dry goods bin wall', [-1.82, -.47, 3.64, .79], 'author_greengrocer.py', ''),
    'greengrocer-sack-row': ('v2', 'Open sacks of potatoes, onions, peas, oats and beans', [-1.4, -.7, 2.8, 1.0], 'author_greengrocer.py', ''),
    'greengrocer-barrels': ('v1', 'Barrels of apples, potatoes and onions', [-1.15, -.4, 2.3, .9], 'author_greengrocer.py', ''),
    'greengrocer-dairy': ('v1', 'Dairy cool cupboard with milk churns', [-.82, -.74, 1.64, 1.03], 'author_greengrocer.py', ''),
    'greengrocer-barrow': ('v1', "Teo Vasko's market barrow", [-2.0, -.65, 2.95, 1.3], 'author_greengrocer.py', ''),
    'greengrocer-flower-stand': ('v1', 'Stepped stand of flower buckets', [-.86, -.42, 1.98, .84], 'author_greengrocer.py', ''),
    'greengrocer-squash-pallet': ('v1', 'Pallet of pumpkins, squash and beetroot', [-.72, -.52, 1.44, 1.0], 'author_greengrocer.py', ''),
    'greengrocer-crate-stack': ('v1', 'Stacked crates and a sack truck', [-.5, -.58, 1.2, .85], 'author_greengrocer.py', ''),
    'greengrocer-basket-table': ('v1', 'Trestle table of baskets: eggs, mushrooms, cherries', [-.88, -.47, 1.76, .94], 'author_greengrocer.py', ''),
    'greengrocer-platform-scale': ('v1', 'Cast-iron platform scale with a sack', [-.38, -.32, .76, .7], 'author_greengrocer.py', ''),
    'greengrocer-basket-stack': ('v1', 'Stack of shopping baskets', [-.32, -.36, .7, .6], 'author_greengrocer.py', ''),
    'greengrocer-pendant': ('v1', 'Bottle-green glass dome pendant', None, 'author_greengrocer.py',
                            'Its bulb is lamp glass: a room binds the placed pendant as a fixture.'),
    # Finch & Thread
    'tailor-shell': ('v2', 'Finch & Thread · cutaway room (stripe and velvet)', None, 'author_tailor.py',
                     'Room shell with a hinged navy door (`door_leaf_tailor`); the room document owns collision.'),
    'tailor-cloth-shelves': ('v2', 'Bolt cabinet with a library ladder', [-1.52, -.98, 3.04, 1.26], 'author_tailor.py', ''),
    'tailor-spool-wall': ('v2', 'Thread wall over button drawers', [-1.32, -.25, 2.64, .56], 'author_tailor.py', ''),
    'tailor-cutting-table': ('v2', 'Cutting table with pinned pattern and shears', [-1.52, -.66, 3.04, 1.32], 'author_tailor.py', ''),
    'tailor-dress-form': ('v2', "Dress form with Braum's half-made coat", [-.36, -.36, .72, .72], 'author_tailor.py', ''),
    'tailor-dress-form-gown': ('v1', 'Dress form in a wine velvet gown', [-.5, -.5, 1.0, 1.0], 'author_tailor.py', ''),
    'tailor-dress-form-suit': ('v1', 'Dress form in a tweed waistcoat and tie', [-.36, -.36, .72, .72], 'author_tailor.py', ''),
    'tailor-sewing-table': ('v2', 'Treadle sewing machine with chair and work lamp', [-.66, -.84, 1.84, 1.14], 'author_tailor.py',
                            'The work lamp is lamp glass, bound by the room as the `sewing-lamp` fixture.'),
    'tailor-mirror': ('v2', 'Three-way fitting mirror on a dais', [-.66, -.66, 1.7, 1.16], 'author_tailor.py', ''),
    'tailor-fitting-room': ('v1', 'Curtained fitting booth', [-.72, -.72, 1.46, 1.44], 'author_tailor.py', ''),
    'tailor-order-rail': ('v1', 'Rail of finished orders with hatboxes', [-1.82, -.2, 3.64, .52], 'author_tailor.py', ''),
    'tailor-hat-stand': ('v1', 'Hat stand and hatboxes', [-.32, -.32, 1.04, .66], 'author_tailor.py', ''),
    'tailor-counter': ('v1', 'Glass-topped haberdashery counter', [-1.42, -.42, 2.84, .84], 'author_tailor.py', ''),
    'tailor-settee': ('v1', 'Buttoned velvet settee and tea table', [-.86, -.34, 2.4, .7], 'author_tailor.py', ''),
    'tailor-pressing': ('v1', 'Pressing station with irons on a stove', [-1.22, -.24, 2.5, .48], 'author_tailor.py', ''),
    'tailor-rug': ('v1', 'Knotted rug, wine and navy', None, 'author_tailor.py', 'Flat; casts no shadow.'),
    'tailor-chandelier': ('v1', 'Small brass chandelier with tulip shades', None, 'author_tailor.py',
                          'Its five candle bulbs are one lamp-glass mesh: a room binds the placed chandelier as one fixture.'),
}


STOREFRONTS = {
    'haverlund-bakery': 'Morning Loaf, the bakery (oxblood front, awning, bracket sign)',
    'haverlund-greengrocer': 'The Pantry, provisions (bottle-green front, awning, crates and baskets)',
    'haverlund-tailor': 'Finch & Thread, tailor and haberdasher (navy front, valance, bracket sign)',
}


def storefront(catalog, asset):
    entry = catalog['assets'][asset]
    entry['version'] = 'v3'
    entry['source'] = f'art/source/world/{asset}/v3/model.blend'
    entry['label'] = STOREFRONTS[asset]
    entry['notes'] = ('art/source/world/square-hub/v1/author_shops.py is initial authoring only; edit the adopted model.blend. '
                      'Deliberate square-renewal source edit (v2, art/source/world/square-renewal/v1/), then the 2026-11-12 '
                      'storefront edit (v3, ' + RECORD + 'revise_fronts.py): deep dressed windows, gilt glass, the shop\'s own '
                      'colour and street features. Previous versions retained.')


def main():
    raw = CATALOG.read_text()
    catalog = json.loads(raw)
    chosen = sys.argv[1:] or list(ASSETS) + list(STOREFRONTS)
    for asset in [a for a in chosen if a in STOREFRONTS]:
        storefront(catalog, asset)
    for asset in [a for a in chosen if a not in STOREFRONTS]:
        version, label, footprint, record, behaviour = ASSETS[asset]
        entry = catalog['assets'].get(asset, {})
        number = int(version.lstrip('v'))
        entry.update({
            'version': number,
            'authority': 'blender',
            'status': 'integrated_sparks_square',
            'label': label,
            'source': f'art/source/world/{asset}/{version}/model.blend',
            'runtime': f'assets/world/{asset}/model.glb',
            'pivot': 'Room origin (cell 0, 0); floor -0.5 to 11.5, west and north walls standing, glazed door at x 6.'
                     if asset.endswith('-shell') else PIVOT + (' Suspension point at the top.' if 'pendant' in asset else ''),
            'logical_footprint': footprint,
            'illustrated_edges': True,
            'notes': ('Second market-shop pass. ' + RECORD + record + ' is the protected initial authoring record (shared kit: '
                      + RECORD + 'interior_kit.py); the saved model.blend is the editable authority.'
                      + (' Earlier version retained beside it.' if number > 1 else '')),
            'behavior': (FURNITURE + (' ' + behaviour if behaviour else '')),
        })
        if 'pendant' in asset or 'chandelier' in asset or asset.endswith('-rug'):
            entry['casts_shadow'] = False
        catalog['assets'][asset] = entry
    CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n')
    print('registered', ', '.join(chosen))


if __name__ == '__main__':
    main()
