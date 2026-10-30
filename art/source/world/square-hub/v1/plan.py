"""The layout of Rootward Square, version 3: the town's central hub. Plain data, no Blender, shared by
author_area.py (which writes content/areas/haverlund-square.json) and author_ground.py (which builds the square's
base ground model), so walkable cells, levels, stairs, walls and every placement agree.

Logical coordinates: x east, y north, one cell = one metre; Blender uses the same x and y with z up. The game camera
looks from the south-east and about 31 degrees down, so the tall buildings stand on the north and west sides and the
south and east edges are low balustrades over the lower town, 10 m down.

    SW  the street down from Spindle Lane (arrival), two flights from level 2
    NW  Hill Street, rising out of the north edge (open, for a later area)
    NE  Lantern Row, the road leaving the east edge (open, for a later area)
    SE  the Harbour Steps, going down past the south edge (open, for a later area)
"""
import math

W, H = 72, 64
ARRIVAL = (1, 8)
LOWER_TOWN = -10.0          # the ground the south and east edges look down onto
ROOTWELL = (42.0, 24.0)

# --- cells ---------------------------------------------------------------------------------------------------------
STREET_Y = range(6, 11)      # the arrival street, five wide
HILL_X = range(0, 12)        # the hill along the west side, level 2
CAFE = (range(0, 12), range(0, 6))
NW_STREET_X = range(12, 18)  # Hill Street
BAND_Y = range(49, 64)       # the north band: the buildings' plots and yards
NE_ROAD_Y = range(43, 49)    # Lantern Row leaves the east edge here
SE_STEPS_X = range(58, 64)   # the Harbour Steps leave the south edge here
PARKS_X = (29, 49)           # the two walled pocket parks between the north buildings, five cells square
ROOTWELL_SCALE = 1.35
RING = 9.6                   # lamps round the Rootwell's plaza ring


def cells():
    """{(x, y): {level, walk, kind}} for every cell, and the stair list."""
    grid = {}
    for x in range(W):
        for y in range(H):
            grid[(x, y)] = {'level': 0, 'walk': True, 'kind': 'plaza'}
    for x in HILL_X:
        for y in range(11, H):
            grid[(x, y)] = {'level': 2, 'walk': False, 'kind': 'hill'}
    for x in CAFE[0]:
        for y in CAFE[1]:
            grid[(x, y)] = {'level': 0, 'walk': True, 'kind': 'cafe'}
    stairs = []
    for y in STREET_Y:
        for x in range(0, 6):
            grid[(x, y)] = {'level': 2, 'walk': True, 'kind': 'street'}
        grid[(6, y)] = {'level': 1, 'walk': True, 'kind': 'stair'}
        stairs.append({'at': [6, y], 'up': 'W'})
        for x in range(7, 11):
            grid[(x, y)] = {'level': 1, 'walk': True, 'kind': 'street'}
        grid[(11, y)] = {'level': 0, 'walk': True, 'kind': 'stair'}
        stairs.append({'at': [11, y], 'up': 'W'})
    for x in range(12, W):
        for y in BAND_Y:
            grid[(x, y)] = {'level': 0, 'walk': False, 'kind': 'band'}
    for x0 in PARKS_X:
        for x in range(x0, x0 + 5):
            for y in range(49, 54):
                grid[(x, y)] = {'level': 0, 'walk': True, 'kind': 'park'}
    for x in NW_STREET_X:
        for y in BAND_Y:
            if y < 56:
                grid[(x, y)] = {'level': 0, 'walk': True, 'kind': 'street'}
            elif y == 56:
                grid[(x, y)] = {'level': 0, 'walk': True, 'kind': 'stair'}
                stairs.append({'at': [x, y], 'up': 'N'})
            else:
                grid[(x, y)] = {'level': 1, 'walk': True, 'kind': 'street'}
    return grid, stairs


# --- buildings (the area's own; each is a separate placed model) ------------------------------------------------------
# block: the rectangles [x0, y0, x1, y1] that stop walking, inside the walkable square only.
BUILDINGS = [
    # The west frontage: three shop-houses in a terrace, then the fruit market hall.
    {'id': 'bakery', 'asset': 'haverlund-bakery', 'at': [15.4, 16.7], 'turn': 90, 'block': [[12, 14.2, 18.6, 19.2]]},
    {'id': 'greengrocer', 'asset': 'haverlund-greengrocer', 'at': [15.4, 21.5], 'turn': 90, 'block': [[12, 19.2, 18.6, 23.8]]},
    {'id': 'bookshop', 'asset': 'haverlund-bookshop', 'at': [15.4, 26.3], 'turn': 90, 'block': [[12, 23.8, 18.6, 28.8]]},
    {'id': 'fruit-market', 'asset': 'haverlund-fruit-market', 'at': [16.5, 37.5], 'turn': 90, 'block': [[12, 31.0, 21.3, 44.0]]},
    # The north frontage: bank, guild hall, post office, and the café on the corner of Lantern Row.
    {'id': 'bank', 'asset': 'haverlund-bank', 'at': [23.0, 54.5], 'turn': 0, 'block': []},
    {'id': 'guild-hall', 'asset': 'square-guildhall', 'at': [41.0, 55.0], 'turn': 0, 'block': []},
    {'id': 'post-office', 'asset': 'haverlund-post-office', 'at': [58.5, 53.2], 'turn': 0, 'block': []},
    {'id': 'cafe', 'asset': 'haverlund-cafe', 'at': [67.5, 52.2], 'turn': 0, 'block': []},
    # The Rootwell, 35 % larger than its model, on its plaza ring.
    {'id': 'rootwell-plaza', 'asset': 'rootwell-plaza', 'at': list(ROOTWELL), 'turn': 0, 'block': []},
    {'id': 'rootwell', 'asset': 'rootwell-beacon', 'at': list(ROOTWELL), 'turn': 0, 'scale': ROOTWELL_SCALE,
     'block': [[ROOTWELL[0] - 4.73, ROOTWELL[1] - 1.96, ROOTWELL[0] + 4.73, ROOTWELL[1] + 1.96],
               [ROOTWELL[0] - 1.96, ROOTWELL[1] - 4.73, ROOTWELL[0] + 1.96, ROOTWELL[1] + 4.73],
               [ROOTWELL[0] - 3.65, ROOTWELL[1] - 3.65, ROOTWELL[0] + 3.65, ROOTWELL[1] + 3.65]]},
]


def ring(angle, radius=RING):
    return round(ROOTWELL[0] + radius * math.cos(math.radians(angle)), 2), round(ROOTWELL[1] + radius * math.sin(math.radians(angle)), 2)


def facing_centre(angle):
    """The turn that faces a thing standing at `angle` round the Rootwell toward it (turn 0 faces south, 90 east)."""
    return (angle + 270) % 360


L, BENCH, BENCH_Y, BIN, BOLLARD = (.25, .25), (.85, .33), (.33, .85), (.2, .2), (.12, .12)
SEAT, SEAT_Y = (1.75, .9), (.9, 1.75)   # a planter bench along X, or turned along Y
DRESSING = [
    # The Rootwell's ring: eight lamps between the conduits, bins and the screen.
    ['lamp-ring-1', 'square-banner-lamp', *ring(22.5), 22, 1.0, L],
    ['lamp-ring-2', 'square-banner-lamp', *ring(67.5), 67, 1.0, L],
    ['lamp-ring-3', 'square-banner-lamp', *ring(112.5), 112, 1.0, L],
    ['well-west-model', 'square-banner-lamp', *ring(157.5), 157, 1.0, L],
    ['lamp-ring-5', 'square-banner-lamp', *ring(202.5), 202, 1.0, L],
    ['lamp-ring-6', 'square-banner-lamp', *ring(247.5), 247, 1.0, L],
    ['lamp-ring-7', 'square-banner-lamp', *ring(292.5), 292, 1.0, L],
    ['well-east-model', 'square-banner-lamp', *ring(337.5), 337, 1.0, L],
    ['bin-ring-1', 'town-bin', *ring(55, 11.0), facing_centre(55), 1.0, BIN],
    ['bin-ring-2', 'town-bin', *ring(235, 11.0), facing_centre(235), 1.0, BIN],
    ['square-screen', 'square-node', 35.0, 17.65, 0, 1.0, (.43, .28)],
    # Seats round the Rootwell, 12.4 m out, in pairs either side of each conduit: every bench faces the well with a
    # planter at its back, so a seat in the open square still feels sheltered and the four ways in stay clear.
    ['seat-north-w', 'town-planter-bench', 36.0, 36.4, 0, 1.0, SEAT],
    ['seat-north-e', 'town-planter-bench', 48.0, 36.4, 0, 1.0, SEAT],
    ['seat-south-w', 'town-planter-bench', 36.0, 11.6, 180, 1.0, SEAT],
    ['seat-south-e', 'town-planter-bench', 48.0, 11.6, 180, 1.0, SEAT],
    ['seat-west-s', 'town-planter-bench', 29.6, 18.0, 90, 1.0, SEAT_Y],
    ['seat-west-n', 'town-planter-bench', 29.6, 30.0, 90, 1.0, SEAT_Y],
    ['seat-east-s', 'town-planter-bench', 54.4, 18.0, 270, 1.0, SEAT_Y],
    ['seat-east-n', 'town-planter-bench', 54.4, 30.0, 270, 1.0, SEAT_Y],
    # Low lit bollards line the conduits that lead to the guild hall, the promenade and the market: the main walks
    # read at night without more tall posts in the middle of the square.
    *[[f'path-light-{name}-{i + 1}', 'town-bollard-light', x, y, 0, 1.0, BOLLARD]
      for name, points in (('north', [(40.6, 35.5), (43.4, 35.5), (40.6, 39.5), (43.4, 39.5), (40.6, 43.5), (43.4, 43.5)]),
                           ('south', [(40.6, 5.5), (43.4, 5.5), (40.6, 9.5), (43.4, 9.5), (40.6, 13.5), (43.4, 13.5)]),
                           ('west', [(26.0, 22.6), (26.0, 25.4), (30.0, 22.6), (30.0, 25.4)]))
      for i, (x, y) in enumerate(points)],
    # The west frontage: lamps on the pavement between the shops, the shops' wares are part of their models.
    ['lamp-shops-1', 'square-banner-lamp', 20.4, 13.6, 90, 1.0, L],
    ['lamp-shops-2', 'square-banner-lamp', 20.4, 23.8, 90, 1.0, L],
    ['lamp-shops-3', 'square-banner-lamp', 20.6, 30.0, 90, 1.0, L],
    ['bin-shops', 'town-bin', 20.4, 19.2, 90, 1.0, BIN],
    # The market aisle in front of the hall: a row of stalls facing it, stock behind them.
    ['flower-stall', 'square-flower-stall', 25.9, 33.6, 270, 1.0, (.95, 1.75)],
    ['fruit-stall', 'square-fruit-stall', 25.9, 37.8, 270, 1.0, (.8, 1.7)],
    ['produce-stall', 'square-market-stall', 25.9, 41.7, 270, 1.0, (.95, 1.4)],
    ['market-crates', 'lane-crates', 27.6, 42.9, 20, 1.0, (.45, .45)],
    ['market-crates-2', 'lane-crates', 28.1, 40.0, 70, 1.0, (.45, .45)],
    ['handcart', 'lane-handcart', 28.6, 33.2, 90, .9, (1.05, .65)],
    # A second row of stalls back to back with the first, their stock between, facing out to the square.
    ['market-stall-east', 'square-market-stall', 29.6, 35.6, 90, 1.0, (.95, 1.4)],
    ['fruit-stall-east', 'square-fruit-stall', 29.6, 39.8, 90, 1.0, (.8, 1.7)],
    # Lights strung the length of the aisle between the hall and the stalls.
    ['festoon-market', 'town-festoon', 23.5, 37.75, 90, 1.0, [(0, -4, .15, .15), (0, 4, .15, .15)]],
    ['bike-rack', 'town-bike-rack', 23.6, 29.6, 0, 1.0, (1.25, .8)],
    ['bicycle', 'lane-bicycle', 23.0, 29.6, 90, 1.0, None],
    ['fountain', 'town-fountain', 23.6, 12.4, 90, 1.0, (.5, .5)],
    ['tree-market', 'town-tree-grate', 24.5, 46.0, 0, 1.0, (.75, .75)],
    ['tree-market-tree', 'lane-tree', 24.5, 46.0, 30, .85, None],
    # The arrival: a news kiosk where the street meets the square; the street's foot is left open.
    ['kiosk', 'town-kiosk', 15.4, 3.4, 90, 1.0, (1.1, 1.1)],
    ['signpost', 'town-signpost', 19.4, 11.2, 0, 1.0, (.25, .25)],
    ['poster-column-west', 'town-poster-column', 29.5, 8.5, 0, 1.0, (.65, .65)],
    ['bin-kiosk', 'town-bin', 17.2, 1.4, 180, 1.0, BIN],
    ['lamp-street-foot', 'square-banner-lamp', 12.5, 11.5, 0, 1.0, L],
    # The south-west terrace under the street: a quiet overlook, benches facing the view.
    ['bench-terrace-1', 'lane-bench', 4.0, 0.9, 0, 1.0, BENCH],
    ['bench-terrace-2', 'lane-bench', 8.5, 0.9, 0, 1.0, BENCH],
    ['terrace-planter', 'lane-planter', 1.0, 4.6, 90, .9, (.28, .6)],
    ['terrace-planter-2', 'lane-planter', 10.4, 4.6, 90, .9, (.28, .6)],
    ['lamp-terrace', 'square-banner-lamp', 6.25, 4.6, 0, 1.0, L],
    # The south promenade along the balustrade: benches face the view, lamps between, bins beside.
    ['lamp-promenade-1', 'square-banner-lamp', 16.0, 1.0, 0, 1.0, L],
    ['lamp-promenade-2', 'square-banner-lamp', 25.0, 1.0, 0, 1.0, L],
    ['lamp-promenade-3', 'square-banner-lamp', 34.0, 1.0, 0, 1.0, L],
    ['lamp-promenade-4', 'square-banner-lamp', 50.0, 1.0, 0, 1.0, L],
    ['lamp-harbour-steps', 'square-banner-lamp', 56.5, 1.0, 0, 1.0, L],
    ['lamp-harbour-steps-2', 'square-banner-lamp', 65.0, 1.0, 0, 1.0, L],
    ['bench-promenade-1', 'lane-bench', 20.5, 1.0, 0, 1.0, BENCH],
    ['bench-promenade-2', 'lane-bench', 29.5, 1.0, 0, 1.0, BENCH],
    ['bench-promenade-3', 'lane-bench', 38.5, 1.0, 0, 1.0, BENCH],
    ['bench-promenade-4', 'lane-bench', 46.8, 1.0, 0, 1.0, BENCH],
    ['bin-promenade-1', 'town-bin', 22.1, 0.9, 180, 1.0, BIN],
    ['bin-promenade-2', 'town-bin', 40.1, 0.9, 180, 1.0, BIN],
    ['telescope', 'lane-telescope', 44.5, .9, 180, 1.0, (.3, .3)],
    # Coffee by the view: a cart on the promenade, its counter toward the square, the benches a few steps away.
    ['coffee-cart', 'town-coffee-cart', 31.0, 4.8, 180, 1.0, (1.25, .85)],
    # The east overlook: benches face out over the lower town, lamps between.
    ['lamp-east-1', 'square-banner-lamp', 70.6, 4.0, 270, 1.0, L],
    ['lamp-east-2', 'square-banner-lamp', 70.6, 13.0, 270, 1.0, L],
    ['lamp-east-3', 'square-banner-lamp', 70.6, 21.0, 270, 1.0, L],
    ['lamp-east-4', 'square-banner-lamp', 70.6, 30.0, 270, 1.0, L],
    ['lamp-east-5', 'square-banner-lamp', 70.6, 38.5, 270, 1.0, L],
    ['bench-east-1', 'lane-bench', 70.6, 8.5, 90, 1.0, BENCH_Y],
    ['bench-east-2', 'lane-bench', 70.6, 17.0, 90, 1.0, BENCH_Y],
    ['bench-east-3', 'lane-bench', 70.6, 34.2, 90, 1.0, BENCH_Y],
    # The east garden: four lawns with a tree each either side of the path, benches facing the path, a fountain.
    ['lawn-1', 'town-lawn', 59.0, 18.5, 0, 1.0, None],
    ['lawn-2', 'town-lawn', 65.0, 18.5, 0, 1.0, None],
    ['lawn-3', 'town-lawn', 59.0, 29.5, 0, 1.0, None],
    ['lawn-4', 'town-lawn', 65.0, 29.5, 0, 1.0, None],
    ['garden-tree-1', 'lane-tree', 59.0, 18.0, 0, 1.0, (.4, .4)],
    ['garden-tree-2', 'lane-tree', 65.0, 18.0, 120, .95, (.4, .4)],
    ['garden-tree-3', 'lane-tree', 59.0, 30.0, 240, 1.05, (.4, .4)],
    ['garden-tree-4', 'lane-tree', 65.0, 30.0, 60, 1.0, (.4, .4)],
    ['bench-garden-1', 'lane-bench', 59.0, 21.4, 180, 1.0, BENCH],
    ['bench-garden-2', 'lane-bench', 65.0, 21.4, 180, 1.0, BENCH],
    ['bench-garden-3', 'lane-bench', 59.0, 26.6, 0, 1.0, BENCH],
    ['bench-garden-4', 'lane-bench', 65.0, 26.6, 0, 1.0, BENCH],
    ['bin-garden', 'town-bin', 62.0, 21.4, 180, 1.0, BIN],
    ['garden-fountain', 'town-fountain', 54.6, 20.6, 90, 1.0, (.5, .5)],
    ['lamp-garden-1', 'square-banner-lamp', 56.0, 26.6, 270, 1.0, L],
    ['lamp-garden-2', 'square-banner-lamp', 62.0, 26.6, 270, 1.0, L],
    ['lamp-garden-3', 'square-banner-lamp', 68.0, 21.4, 270, 1.0, L],
    # The building yard in the south-east: stock for whatever goes up next.
    ['timber', 'square-timber-store', 50.0, 8.0, 0, 1.0, (1.9, 1.2)],
    ['yard-crates', 'lane-crates', 53.5, 9.5, 0, 1.0, (.45, .45)],
    # The civic forecourt: each door between a pair of lamps, planters, notices and the post box.
    ['lamp-bank-1', 'square-banner-lamp', 20.5, 47.7, 180, 1.0, L],
    ['lamp-bank-2', 'square-banner-lamp', 25.5, 47.7, 0, 1.0, L],
    ['hall-lamp-model', 'square-banner-lamp', 37.5, 47.7, 180, 1.0, L],
    ['lamp-hall-east', 'square-banner-lamp', 44.5, 47.7, 0, 1.0, L],
    ['planter-hall-1', 'lane-planter', 39.0, 48.0, 0, .9, (.6, .28)],
    ['planter-hall-2', 'lane-planter', 43.0, 48.0, 0, .9, (.6, .28)],
    ['public-notices', 'lane-notice-board', 34.6, 47.8, 0, 1.0, (.7, .2)],
    ['lamp-post-1', 'square-banner-lamp', 56.0, 47.7, 180, 1.0, L],
    ['lamp-post-2', 'square-banner-lamp', 61.0, 47.7, 0, 1.0, L],
    ['post-box', 'lane-post-box', 54.6, 47.8, 0, 1.0, (.25, .25)],
    ['bin-civic', 'town-bin', 47.0, 47.9, 0, 1.0, BIN],
    # Hill Street and Lantern Row: bollards mark where the streets meet the square.
    ['bollard-hill-1', 'town-bollard', 12.5, 48.5, 0, 1.0, BOLLARD],
    ['bollard-hill-2', 'town-bollard', 16.5, 48.5, 0, 1.0, BOLLARD],
    ['lamp-hill-street', 'square-banner-lamp', 17.3, 51.0, 270, 1.0, L],
    ['bollard-row-1', 'town-bollard', 63.5, 43.5, 0, 1.0, BOLLARD],
    ['bollard-row-2', 'town-bollard', 63.5, 47.5, 0, 1.0, BOLLARD],
    ['lamp-lantern-row', 'square-banner-lamp', 62.5, 41.5, 270, 1.0, L],
    # The café terrace on the corner: tables under parasols, a lamp.
    ['cafe-table-1', 'town-parasol-table', 64.6, 46.6, 0, 1.0, (.55, .55)],
    ['cafe-table-2', 'town-parasol-table', 67.4, 46.6, 40, 1.0, (.55, .55)],
    ['cafe-table-3', 'town-parasol-table', 70.2, 46.6, 80, 1.0, (.55, .55)],
    ['festoon-cafe', 'town-festoon', 67.2, 48.3, 0, 1.0, [(-4, 0, .15, .15), (4, 0, .15, .15)]],
    ['poster-column-east', 'town-poster-column', 60.0, 38.5, 0, 1.0, (.65, .65)],
    # The pocket parks between the north buildings: a lawn, a tree at the back, two benches facing each other.
    ['park-1-lawn', 'town-lawn', 31.0, 51.0, 0, 1.0, None],
    ['park-1-tree', 'lane-tree', 31.0, 52.7, 0, 1.0, (.4, .4)],
    ['park-1-bench-w', 'lane-bench', 29.25, 51.2, 90, 1.0, BENCH_Y],
    ['park-1-bench-e', 'lane-bench', 32.75, 51.2, 270, 1.0, BENCH_Y],
    ['park-2-lawn', 'town-lawn', 51.0, 51.0, 0, 1.0, None],
    ['park-2-tree', 'lane-tree', 51.0, 52.7, 140, .95, (.4, .4)],
    ['park-2-bench-w', 'lane-bench', 49.25, 51.2, 90, 1.0, BENCH_Y],
    ['park-2-bench-e', 'lane-bench', 52.75, 51.2, 270, 1.0, BENCH_Y],
    # Robots at their work (those on rounds are moved by the stage from their first point).
    ['heron', 'robot-heron', 46.5, 9.5, 300, 1.0, (.3, .3)],
    ['tender', 'robot-tender', 47.6, 28.2, 135, 1.0, (.28, .28)],
    ['tally', 'robot-tally', 27.9, 37.8, 300, 1.0, (.28, .28)],
    ['wick', 'robot-wick', 49.0, 18.8, 220, 1.0, (.25, .25)],
    ['pip', 'robot-pip', 56.0, 45.6, 0, 1.0, None],
    ['trowel', 'robot-trowel', 55.6, 22.6, 0, 1.0, None],
    ['porter', 'robot-pip', 14.0, 9.0, 0, 1.0, None],
]

RUNS = [
    # The south edge, over the lower town: the café corner and the square, leaving the Harbour Steps open between the
    # two parapets.
    ('balustrade', (-0.25, -0.3, 0.0), (57.3, -0.3, 0.0)),
    ('balustrade', (63.7, -0.3, 0.0), (71.3, -0.3, 0.0)),
    # The east edge, up to Lantern Row, then along the road's open south side beyond the square.
    ('balustrade', (71.3, -0.3, 0.0), (71.3, 42.25, 0.0)),
    ('balustrade', (71.3, 42.25, 0.0), (98.3, 42.25, 0.0)),
    # The arrival street's open south side, over the café: level 2, the upper flight, level 1, the lower flight.
    ('railing', (-0.5, 5.65, 2.0), (5.5, 5.65, 2.0)),
    ('railing-stair', (5.5, 5.65, 2.0), (6.5, 5.65, 1.0)),
    ('railing', (6.5, 5.65, 1.0), (10.5, 5.65, 1.0)),
    ('railing-stair', (10.5, 5.65, 1.0), (11.5, 5.65, 0.0)),
    # Garden railings on the hill's proud coping (2.16) where it stands over the street and the gaps between the shops,
    # the fruit market and Hill Street.
    ('railing', (6.5, 10.65, 2.16), (11.65, 10.65, 2.16)),
    ('railing', (11.65, 10.65, 2.16), (11.65, 14.65, 2.16)),
    ('railing', (11.65, 28.6, 2.16), (11.65, 31.6, 2.16)),
    ('railing', (11.65, 43.4, 2.16), (11.65, 63.5, 2.16)),
    # Hill Street's open east side over the bank's light-well and yard: the flight, then the level-1 street.
    ('railing-stair', (17.65, 55.5, 0.0), (17.65, 56.5, 1.0)),
    ('railing', (17.65, 56.5, 1.0), (17.65, 63.5, 1.0)),
    # The pocket parks: a low wall along the front with a gap to walk in, and a wall closing the yard behind.
    ('wall', (28.65, 48.75, 0.0), (30.2, 48.75, 0.0)),
    ('wall', (31.8, 48.75, 0.0), (33.35, 48.75, 0.0)),
    ('wall', (28.65, 53.6, 0.0), (33.35, 53.6, 0.0)),
    ('wall', (48.65, 48.75, 0.0), (50.2, 48.75, 0.0)),
    ('wall', (51.8, 48.75, 0.0), (53.35, 48.75, 0.0)),
    ('wall', (48.65, 53.6, 0.0), (53.35, 53.6, 0.0)),
    # Lantern Row's front gardens beyond the square, each house's gate in its wall.
    ('wall', (71.9, 48.9, 0.0), (77.9, 48.9, 0.0)),
    ('gate', (77.9, 48.9, 0.0), (79.9, 48.9, 0.0)),
    ('wall', (79.9, 48.9, 0.0), (85.9, 48.9, 0.0)),
    ('gate', (85.9, 48.9, 0.0), (87.9, 48.9, 0.0)),
    ('wall', (87.9, 48.9, 0.0), (99.9, 48.9, 0.0)),
]

# --- background houses: the town round the square (not walkable; rendering only) ------------------------------------
# [asset, x, y, ground z, turn, look]. Turn 0 faces south, 90 east, 180 north, 270 west. A look is a seed, a palette
# or {"seed", "plain"} (plain hides the dressing on houses only glimpsed).
HOUSES = [
    # The hill behind the shops and the market, facing the square (east), level 2.
    ['seaside-lantern-row-house', 5.0, 15.5, 2.0, 90, 3],
    ['seaside-rosewash-house', 5.5, 24.0, 2.0, 90, 'warm_lane'],
    ['seaside-saltwind-house', 4.5, 34.5, 2.0, 90, 11],
    ['seaside-eaveside-terrace', 5.0, 45.0, 2.0, 90, 5],
    ['seaside-shingle-court-cottage', 4.0, 55.5, 2.0, 90, 8],
    # Further up the hill to the west, the arrival street's neighbours.
    ['seaside-rosewash-house', -6.0, 13.5, 4.0, 90, {'seed': 21, 'plain': True}],
    ['seaside-lantern-row-house', -6.5, 22.0, 4.0, 90, {'seed': 22, 'plain': True}],
    ['seaside-saltwind-house', -7.0, 31.5, 4.0, 90, {'seed': 23, 'plain': True}],
    ['seaside-eaveside-terrace', -7.0, 42.0, 4.0, 90, {'seed': 24, 'plain': True}],
    ['seaside-rosewash-house', -4.0, 0.5, 3.0, 0, 'ochre_court'],
    ['seaside-shingle-court-cottage', -12.0, -1.0, 3.0, 0, {'seed': 26, 'plain': True}],
    # Behind the north buildings: yards, then the upper town rising.
    ['seaside-rosewash-house', 30.5, 61.5, 0.0, 0, 31],
    ['seaside-lantern-row-house', 51.0, 60.5, 0.0, 0, 32],
    ['seaside-shingle-court-cottage', 68.5, 59.8, 0.0, 0, 33],
    ['seaside-saltwind-house', 24.0, 70.0, 1.5, 0, {'seed': 34, 'plain': True}],
    ['seaside-eaveside-terrace', 40.0, 70.5, 1.5, 0, {'seed': 35, 'plain': True}],
    ['seaside-rosewash-house', 55.0, 70.0, 1.5, 0, {'seed': 36, 'plain': True}],
    ['seaside-lantern-row-house', 66.0, 69.0, 1.5, 0, {'seed': 37, 'plain': True}],
    # Hill Street's neighbours, either side as it climbs.
    ['seaside-lantern-row-house', 7.0, 68.5, 3.0, 90, {'seed': 41, 'plain': True}],
    ['seaside-rosewash-house', 22.5, 67.5, 1.5, 270, 42],
    # Lantern Row, east of the square: houses on its north side, the road at level 0.
    ['seaside-eaveside-terrace', 78.0, 53.5, 0.0, 0, 51],
    ['seaside-rosewash-house', 88.0, 53.0, 0.0, 0, {'seed': 52, 'plain': True}],
    # The lower town under the south and east balustrades, 10 m down, set back so roofs stay below the rail.
    ['seaside-saltwind-house', 10.0, -14.0, LOWER_TOWN, 0, {'seed': 61, 'plain': True}],
    ['seaside-rosewash-house', 22.0, -12.5, LOWER_TOWN, 180, {'seed': 62, 'plain': True}],
    ['seaside-shingle-court-cottage', 33.0, -11.5, LOWER_TOWN, 180, 63],
    ['seaside-eaveside-terrace', 44.5, -14.0, LOWER_TOWN, 180, {'seed': 64, 'plain': True}],
    ['seaside-rosewash-house', 69.0, -12.0, LOWER_TOWN, 180, {'seed': 65, 'plain': True}],
    ['seaside-saltwind-house', 84.0, -8.0, LOWER_TOWN, 270, {'seed': 66, 'plain': True}],
    ['seaside-shingle-court-cottage', 83.0, 6.0, LOWER_TOWN, 270, 67],
    ['seaside-rosewash-house', 84.5, 18.0, LOWER_TOWN, 270, {'seed': 68, 'plain': True}],
    ['seaside-eaveside-terrace', 84.0, 30.5, LOWER_TOWN, 270, {'seed': 69, 'plain': True}],
    # More of the lower town: a second row south of the cross street, the strip by the Harbour Steps, the east rows.
    ['seaside-rosewash-house', 52.5, -12.5, LOWER_TOWN, 180, {'seed': 70, 'plain': True}],
    ['seaside-lantern-row-house', 2.0, -28.0, LOWER_TOWN, 0, {'seed': 71, 'plain': True}],
    ['seaside-saltwind-house', 14.5, -29.0, LOWER_TOWN, 180, {'seed': 72, 'plain': True}],
    ['seaside-shingle-court-cottage', 36.0, -28.0, LOWER_TOWN, 0, {'seed': 73, 'plain': True}],
    ['seaside-rosewash-house', 46.5, -29.0, LOWER_TOWN, 180, {'seed': 74, 'plain': True}],
    ['seaside-eaveside-terrace', 70.0, -28.0, LOWER_TOWN, 0, {'seed': 75, 'plain': True}],
    ['seaside-lantern-row-house', 82.0, -28.0, LOWER_TOWN, 180, {'seed': 76, 'plain': True}],
    ['seaside-rosewash-house', 97.0, -6.0, LOWER_TOWN, 90, {'seed': 77, 'plain': True}],
    ['seaside-saltwind-house', 97.0, 8.0, LOWER_TOWN, 90, {'seed': 78, 'plain': True}],
    ['seaside-lantern-row-house', 97.0, 21.0, LOWER_TOWN, 90, {'seed': 79, 'plain': True}],
    ['seaside-shingle-court-cottage', 97.0, 33.0, LOWER_TOWN, 90, {'seed': 80, 'plain': True}],
    ['seaside-eaveside-terrace', -11.0, -15.0, -3.5, 0, {'seed': 81, 'plain': True}],
    ['seaside-rosewash-house', -24.0, -14.0, -3.5, 0, {'seed': 82, 'plain': True}],
    ['seaside-saltwind-house', -25.0, -1.0, 4.5, 0, {'seed': 83, 'plain': True}],
    # The upper town: another row on the higher terrace, Hill Street's west side, the west hill, Lantern Row's end.
    ['seaside-saltwind-house', 25.0, 83.0, 3.0, 0, {'seed': 84, 'plain': True}],
    ['seaside-rosewash-house', 37.0, 83.0, 3.0, 0, {'seed': 85, 'plain': True}],
    ['seaside-eaveside-terrace', 49.0, 83.5, 3.0, 0, {'seed': 86, 'plain': True}],
    ['seaside-lantern-row-house', 60.0, 83.0, 3.0, 0, {'seed': 87, 'plain': True}],
    ['seaside-saltwind-house', 72.0, 83.0, 3.0, 0, {'seed': 88, 'plain': True}],
    ['seaside-rosewash-house', 85.0, 70.0, 1.5, 0, {'seed': 89, 'plain': True}],
    ['seaside-eaveside-terrace', 5.5, 81.0, 3.0, 90, {'seed': 90, 'plain': True}],
    ['seaside-rosewash-house', -20.0, 18.0, 6.0, 90, {'seed': 91, 'plain': True}],
    ['seaside-saltwind-house', -21.0, 31.0, 6.0, 90, {'seed': 92, 'plain': True}],
    ['seaside-lantern-row-house', -20.5, 44.0, 6.0, 90, {'seed': 93, 'plain': True}],
    ['seaside-rosewash-house', 98.0, 53.0, 0.0, 0, {'seed': 94, 'plain': True}],
]

# Trees in the gardens and yards round the square: [asset, x, y, ground z, turn, scale].
TREES = [
    ['lane-cypress', 10.0, 19.5, 2.0, 0, 1.0], ['lane-cypress', 10.0, 29.8, 2.0, 40, .9], ['lane-cypress', 10.0, 40.5, 2.0, 80, 1.05],
    ['lane-tree', 9.0, 51.5, 2.0, 0, .9], ['lane-cypress', 63.0, 57.5, 0.0, 0, 1.0], ['lane-tree', 4.0, 60.5, 2.0, 200, .9], ['lane-tree', 40.0, 63.5, 1.5, 90, 1.1],
    ['lane-tree', 8.0, -22.0, LOWER_TOWN, 0, 1.0], ['lane-tree', 40.0, -22.5, LOWER_TOWN, 160, 1.1], ['lane-cypress', 63.0, -32.0, LOWER_TOWN, 0, 1.0],
    ['lane-tree', 88.0, -16.0, LOWER_TOWN, 70, 1.0], ['lane-tree', 101.0, 27.0, LOWER_TOWN, 10, .9], ['lane-cypress', -16.0, 26.0, 6.0, 0, 1.0],
    ['lane-tree', -14.0, 52.0, 6.0, 300, 1.0], ['lane-tree', 92.0, 62.0, 0.0, 45, 1.0], ['lane-tree', 18.0, 78.0, 3.0, 0, .9],
]


# --- exits, zones, story -------------------------------------------------------------------------------------------
ZONES = [
    {'id': 'spindle-steps', 'title': 'Spindle Steps', 'rect': [0, 6, 12, 5]},
    {'id': 'hill-street', 'title': 'Hill Street', 'rect': [12, 49, 6, 15]},
    {'id': 'lantern-row', 'title': 'Lantern Row', 'rect': [64, 43, 8, 6]},
    {'id': 'harbour-steps', 'title': 'The Harbour Steps', 'rect': [57, 0, 8, 4]},
    {'id': 'pocket-parks', 'title': 'The pocket parks', 'rect': [29, 49, 25, 5]},
    {'id': 'east-garden', 'title': 'The east garden', 'rect': [54, 14, 16, 22]},
    {'id': 'market', 'title': 'The market', 'rect': [12, 12, 17, 34]},
    {'id': 'rootward-square', 'title': 'Rootward Square', 'rect': [0, 0, W, H]},
]

LAMPS = [
    {'id': 'well-west', 'at': list(ring(157.5)), 'stand': [32, 27], 'title': 'Rootwell lamp, west', 'asset': 'well-west-model'},
    {'id': 'well-east', 'at': list(ring(337.5)), 'stand': [52, 20], 'title': 'Rootwell lamp, east', 'asset': 'well-east-model'},
    {'id': 'hall-lamp', 'at': [37.5, 47.7], 'stand': [36, 47], 'title': 'Hall lamp', 'asset': 'hall-lamp-model'},
]

INSPECTIONS = [
    ('beacon-dial', [47, 19], 'The pressure dial', 'The needle sits just past the first mark. Somebody has scratched a line in the brass where it used to rest.'),
    ('beacon-notices', [42, 18], 'Notices on the beacon', 'A tide table, a meeting on Thursday, and a drawing of a lost tortoise called Admiral. Last seen heading for the harbour.'),
    ('beacon-door', [48, 24], 'A small teal door', 'Locked. The keyhole is polished bright. Chalked on the step: BACK AT 4.'),
    ('beacon-glass', [37, 29], 'The beacon', 'Up close, the root moves. Not much. About as much as someone asleep.'),
    ('hall-counter', [41, 48], 'Enquiries', 'A brass bell, a ledger open at today and a mug gone cold. The clerk’s chair is turned to the window.'),
    ('hall-clock', [44, 48], 'The guild hall clock', 'Ten past nine. The bakery says five past. Nobody’s sure which to believe.'),
    ('post-office', [58, 48], 'Post Office', 'Parcels in brown paper, every one tied with the same knot. One is addressed in pencil to the lighthouse.'),
    ('post-box', [55, 47], 'The post box', 'Last collection 5.15. Someone has posted a pine cone. It’s still in the slot.'),
    ('public-notices', [34, 47], 'Guild notices', 'The beacon’s quarterly reading, a call for volunteers to repaint the railings, and a reward for a lost brass key.'),
    ('bakery', [20, 16], 'Morning Loaf', 'The racks are half empty already. A card in the window: SECOND BATCH AT ELEVEN.'),
    ('greengrocer', [20, 21], 'The greengrocer', 'Oranges stacked into a careful pyramid. One is missing from the very top.'),
    ('bookshop', [20, 25], 'Finch & Sons', 'A tray of books at a penny each. On top, a tide almanac eleven years out of date.'),
    ('fruit-market', [22, 39], 'The fruit market', 'Lemons by the crate and figs by the dozen. A chalkboard by the scales: PEACHES TOMORROW. Under it, smaller: PROBABLY.'),
    ('bank', [23, 48], 'Haverlund Savings', 'The brass plate has been polished so often the H is half gone. Inside, a clerk counts the same stack of notes for the second time.'),
    ('cafe', [66, 48], 'The Harbour Cup', 'Steam on the windows and a dish of sugar cubes on every table. A sign on the till: WE DO NOT SERVE GULLS.'),
    ('kiosk', [17, 3], 'The news kiosk', 'Today’s Haverlund Herald: TRAM No. 7 LATE AGAIN. The vendor has underlined AGAIN in pencil.'),
    ('fountain', [24, 11], 'The drinking fountain', 'Cold, and faintly of iron. The tin cup is chained on, and the chain is longer than it needs to be.'),
    ('flower-stall', [24, 34], 'The flower stall', 'Buckets of sweet peas and stocks, and a jam jar of coins nobody is minding.'),
    ('tally', [27, 36], 'Tally', '“FOUR PENCE. STOP. PLEASE COUNT IT. STOP. PLEASE COUNT IT AGAIN. STOP.”'),
    ('heron', [45, 10], 'Heron', 'The crate swings an inch and stops. “I. AM. WAITING. FOR. THE. WIND. STOP.”'),
    ('tender', [48, 29], 'Tender', 'It’s watching a valve wheel as if it might do something. “CHECKING. STILL CHECKING. STOP.”'),
    ('wick', [50, 18], 'Wick', '“IT IS 9.14. LAMP TWO IS NOT DUE UNTIL 19.40. I AM EARLY. STOP.”'),
    ('timber', [50, 6], 'Building timber', 'Planks stacked to dry, chalked with a guild mark and a date. A tarpaulin tied over the best of it.'),
    ('shade-tree', [60, 22], 'The garden bench', 'Initials cut into the seat: R.W. Varnished over more than once.'),
    ('pocket-park', [31, 50], 'A pocket park', 'Somebody has left half a sandwich on the bench, neatly wrapped, as if they mean to come back.'),
    ('south-view', [44, 0], 'Over the rail', 'Roofs all the way down to the water. One chimney below is close enough to warm your hands at.'),
    ('east-view', [71, 26], 'The east wall', 'Down below, a man is carrying a ladder sideways along a street too narrow for it.'),
    ('signpost', [20, 11], 'The fingerpost', 'Hill Street one way, the Harbour Steps the other. Someone has tied a ribbon round the Lantern Row arm, as if it might wander off.'),
    ('poster-column', [31, 9], 'The poster column', 'BAND TONIGHT, pasted over CIRCUS, pasted over a band from last summer. You can still make out the drummer’s name.'),
    ('coffee-cart', [31, 6], 'The coffee cart', 'The urn ticks as it cools. A cup sits upside down on its saucer, the way you leave one when you mean to come back.'),
    ('street-steps', [12, 8], 'Spindle Steps', 'The way back up to the lane. Chalked on the bottom step: 212. Under it, in other chalk: LIAR. 213.'),
]


def house_extent(asset, x, y, turn, extents):
    """The plan rectangle of a placed house from its model bounds (x0, x1, south, north at turn 0)."""
    x0, x1, s0, n1 = extents[asset]
    corners = [(x0, -s0), (x1, -s0), (x1, n1), (x0, n1)]
    th = math.radians(turn)
    pts = [(x + cx * math.cos(th) - cy * math.sin(th), y + cx * math.sin(th) + cy * math.cos(th)) for cx, cy in corners]
    return min(p[0] for p in pts), min(p[1] for p in pts), max(p[0] for p in pts), max(p[1] for p in pts)
