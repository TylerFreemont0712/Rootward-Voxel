"""One-time record: furnish Morning Loaf, The Pantry and Finch & Thread (content/areas/shop-*.json, v2 -> v3).

Each room gets its own shell (the shop's glazed door, in the shopfront's colour, replaces the borrowed workshop barn
doors), purpose-made furniture with collision, brass pendants (the lamp ids are unchanged, so saved programs keep
working), a chalk board the lodger's code can write to (a display with a commission notice), a shopkeeper with a
small working round, and inspections. The JSON documents are the masters afterwards; edit them, not this.
Run: python3 art/source/world/shop-interiors/v1/revise_rooms.py   (refuses documents already at v3)
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]


def asset(id, kind, at, turn=0, height=0.0, solid=True, scale=1):
    entry = {'id': id, 'asset': kind, 'at': at, 'turn': turn, 'height': height, 'scale': scale}
    if solid:
        entry['solid'] = True
    return entry


def pendants(spots):
    return [asset(f'shop-pendant-{n + 1}-model', 'clockshop-brass-pendant', at, 0, 3.7, False) for n, at in enumerate(spots)]


ROOMS = {
    'bakery': {
        'title': 'Morning Loaf',
        'assets': [
            asset('oven', 'bakery-oven', [2.6, 10.5]),
            asset('bread-rack-north', 'bakery-bread-rack', [-0.25, 8.9], 90),
            asset('bread-rack-south', 'bakery-bread-rack', [-0.25, 6.0], 90),
            asset('serving-counter', 'bakery-counter', [8.0, 5.5]),
            asset('proving-table', 'bakery-proving-table', [3.9, 6.6]),
            asset('flour-sacks', 'bakery-flour-sacks', [10.5, 10.4]),
            asset('bake-board-model', 'shop-chalk-board', [7.6, 11.36], 0, 2.35, False),
        ],
        'pendants': [[4.0, 4.2], [8.4, 8.2]],
        'extra_lamps': [{'id': 'oven-fire', 'zone': 'shop-floor', 'at': [2.6, 9.5], 'style': 'fixture', 'stand': [3, 8], 'automatic': True, 'requires': 'field-tablet', 'title': 'Oven fire'}],
        'extra_fixtures': [{'id': 'oven-fire', 'asset': 'oven', 'range': 4.5, 'energy': 1.1}],
        'display': {'id': 'bake-board', 'title': 'Morning Loaf bake board', 'object': 'bake-board-model', 'at': [7, 10],
                    'commission': 'bake-order', 'default': ['SECOND BATCH AT 11']},
        'keeper': {'id': 'ada', 'phantom': 'woman', 'at': [8, 7], 'route': [[8, 7], [3, 8]], 'speed': 0.8,
                   'errands': [{'target': 'serving-counter', 'activity': 'trade', 'seconds': 8.0}, {'target': 'oven', 'activity': 'inspect', 'seconds': 10.0}]},
        'inspections': [
            {'id': 'bake-order', 'at': [7, 10], 'title': 'A note on the bake board',
             'text': 'Pinned to the frame, in pencil, in a hand that presses hard: BOARD. PLEASE. PEOPLE KEEP KNOCKING ON THE BACK DOOR TO ASK WHEN. — A. KETTERING'},
            {'id': 'bread-oven', 'at': [3, 8], 'title': 'The oven',
             'text': 'Warm right through the brick. Somebody has chalked a row of ticks on the flue, then rubbed half of them out.'},
            {'id': 'bread-racks', 'at': [1, 7], 'title': 'The racks',
             'text': 'Tin loaves on the bottom, rounds above, baguettes standing in the top like umbrellas in a stand. A paper tag on the end of each shelf says what time it came out.'},
            {'id': 'proving-bowls', 'at': [4, 5], 'title': 'Proving bowls',
             'text': 'Dough rising under a damp cloth. One bowl has a pencil mark on the rim, a finger’s width above the dough.'},
        ],
    },
    'greengrocer': {
        'title': 'The Pantry',
        'assets': [
            asset('jar-shelves', 'pantry-jar-shelves', [-0.22, 4.4], 90),
            asset('sack-row', 'pantry-sack-row', [-0.1, 9.8], 90),
            asset('produce-stand', 'pantry-produce-stand', [4.5, 7.4]),
            asset('grocer-counter', 'pantry-counter', [8.5, 5.8]),
            asset('back-crates', 'bakery-flour-sacks', [10.5, 10.3]),
            asset('price-board-model', 'shop-chalk-board', [8.6, 11.36], 0, 2.35, False),
        ],
        'pendants': [[3.5, 4.2], [8.5, 8.6]],
        'display': {'id': 'price-board', 'title': 'The Pantry price board', 'object': 'price-board-model', 'at': [8, 10],
                    'commission': 'price-order', 'default': ['APPLES 4P']},
        'keeper': {'id': 'pantry-tessa', 'skin': 'sparks_tessa', 'at': [8, 7], 'route': [[8, 7], [4, 6]],
                   'errands': [{'target': 'grocer-counter', 'activity': 'trade', 'seconds': 8.0}, {'target': 'produce-stand', 'activity': 'inspect', 'seconds': 7.0}]},
        'inspections': [
            {'id': 'price-order', 'at': [8, 10], 'title': 'The price board',
             'text': 'APPLES 4P in chalk, three days old. A slate underneath lists today’s prices in pencil, crossed out and rewritten twice. A note: TESSA — CAN YOUR LODGER’S SLATE DO THIS? I NEVER KNOW WHAT CHANGED. — T. VASKO'},
            {'id': 'produce', 'at': [4, 6], 'title': 'The produce stand',
             'text': 'Apples, oranges, lemons, cabbages, carrots, plums. Each crate has a tag that says which hill farm it came from, and one that just says ORCHARD in a different hand.'},
            {'id': 'jars', 'at': [1, 4], 'title': 'Jars and tins',
             'text': 'Preserves, honey, tea and spices, labelled in neat capitals. Someone has turned every label to face the front.'},
            {'id': 'scale', 'at': [8, 4], 'title': 'The beam scale',
             'text': 'Brass, polished where hands rest on it. A single apple sits in the pan as if waiting to be weighed.'},
        ],
    },
    'bookshop': {
        'title': 'Finch & Thread',
        'assets': [
            asset('cloth-shelves', 'tailor-cloth-shelves', [-0.22, 3.0], 90),
            asset('cheval-mirror', 'tailor-mirror', [-0.22, 9.4], 90),
            asset('spool-wall', 'tailor-spool-wall', [2.8, 11.38]),
            asset('cutting-table', 'tailor-cutting-table', [5.6, 6.6]),
            asset('dress-form-window', 'tailor-dress-form', [9.8, 2.6]),
            asset('dress-form-coat', 'tailor-dress-form', [2.2, 7.4], 90),
            asset('sewing-table', 'tailor-sewing-table', [9.4, 8.6]),
            asset('order-board-model', 'shop-chalk-board', [8.4, 11.36], 0, 2.35, False),
        ],
        'pendants': [[4.5, 4.0], [7.0, 8.4]],
        'display': {'id': 'order-board', 'title': 'Finch & Thread order board', 'object': 'order-board-model', 'at': [8, 10],
                    'commission': 'order-ticket', 'default': ['ALTERATIONS INSIDE']},
        'keeper': {'id': 'gret', 'phantom': 'woman', 'at': [6, 8], 'route': [[6, 8], [9, 7]], 'speed': 0.7,
                   'errands': [{'target': 'cutting-table', 'activity': 'inspect', 'seconds': 9.0}, {'target': 'sewing-table', 'activity': 'inspect', 'seconds': 9.0}]},
        'inspections': [
            {'id': 'order-ticket', 'at': [8, 10], 'title': 'The order book',
             'text': 'Open on the board’s ledge. Fourteen finished orders, and a column headed COLLECTED with only two ticks in it. In the margin: they don’t know it’s ready. — G.F.'},
            {'id': 'cloth', 'at': [1, 3], 'title': 'The cloth wall',
             'text': 'Bolts rolled tight, sorted by colour, then by weight. A gap where the plum wool should be has a note pinned in it: ORDERED.'},
            {'id': 'coat-in-progress', 'at': [3, 6], 'title': 'A coat on the stand',
             'text': 'Navy, tacked together with white thread. The sleeves are pinned to the form’s shoulders, waiting. A paper tag: BRAUM — NOT BY LUNCH.'},
            {'id': 'spools', 'at': [3, 10], 'title': 'The thread wall',
             'text': 'A hundred and twenty-eight spools in rows of sixteen. Every row runs light to dark, except one, where two blues have swapped.'},
        ],
    },
}

for shop, spec in ROOMS.items():
    path = ROOT / f'content/areas/shop-{shop}.json'
    doc = json.loads(path.read_text())
    if doc['version'] >= 3:
        raise SystemExit(f'{path.name} already furnished; edit the document instead.')
    room = doc['interior']
    room['shell'] = {'bakery': 'bakery-shell', 'greengrocer': 'pantry-shell', 'bookshop': 'tailor-shell'}[shop]
    room['assets'] = spec['assets'] + pendants(spec['pendants'])
    for link in room['links']:
        link['doors'] = 'shell'
    room['lamp_fixtures'] = [{'id': f'shop-pendant-{n + 1}', 'asset': f'shop-pendant-{n + 1}-model', 'range': 7, 'energy': 1.2}
                             for n in range(len(spec['pendants']))] + spec.get('extra_fixtures', [])
    lamps = {lamp['id']: lamp for lamp in doc['lamps']}
    for n, at in enumerate(spec['pendants']):
        lamps[f'shop-pendant-{n + 1}']['at'] = at
    doc['lamps'] = list(lamps.values()) + spec.get('extra_lamps', [])
    room['inspections'] = spec['inspections']
    doc['displays'] = [dict(spec['display'], zone='shop-floor')]
    doc['villagers'] = [spec['keeper']]
    doc['version'] = 3
    path.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + '\n')
    print('Furnished', path.name)
