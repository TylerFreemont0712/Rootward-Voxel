"""The town round Spindle Lane, so the lane no longer floats: plain data shared by author_lane_ground.py (the ground
model haverlund-lane-surround) and dress_lane.py (which places it and the background houses in
content/areas/haverlund-lane.json). Lane coordinates: x east, y north, z up; the lane set itself owns the cells
x 0..23, y -1..27 (and its tunnel hill and gate steps), so nothing here draws over it.

    south and east (toward the camera): the lower town 8 m down, a street under the walls, then houses set back so
        their roofs stay below the lane's line of sight;
    west (behind the workshop row): a back lane, then the town climbing the hill;
    north: the town steps carry on down from the gate toward the square, houses either side.
"""
LT = -8.0
X0, X1, Y0, Y1 = -44, 72, -46, 76
STEPS_X = (12, 13)


def owned(x, y):
    """Cells the lane set draws (its terraces, the tunnel hill, the steps just past the gate)."""
    return 0 <= x <= 23 and -1 <= y <= 27 or -3 <= x <= -1 and -1 <= y <= 4 or x in STEPS_X and 28 <= y <= 29


def heights():
    """{(x, y): (z, kind)} for every cell outside the lane; kind is 'street', 'garden', 'yard', 'hill' or 'steps'."""
    cells = {}
    for x in range(X0, X1 + 1):
        for y in range(Y0, Y1 + 1):
            if owned(x, y):
                continue
            if x <= -4 and -8 <= y <= 4:
                z, kind = (4.7 if y <= 2 else 2.2), 'hill'
            elif y <= -2 or x >= 24 and y <= 27:
                street = (-7 <= y <= -2 and x >= -3) or (-11 <= y <= -9 and x <= -4) or 24 <= x <= 29 or y in (-25, -26) or x in (46, 47)
                z, kind = LT, 'street' if street else 'garden'
            elif x <= -1:
                z, kind = (1.0, 'street') if x >= -4 else (3.0, 'garden') if x >= -20 else (5.0, 'garden')
            elif x <= 11:
                z, kind = (1.0, 'garden') if y <= 36 else (-2.0, 'garden') if y <= 50 else (-5.0, 'garden')
            elif x >= 14:
                z, kind = (1.0, 'yard') if x <= 15 and y <= 30 else (-3.0, 'garden') if y <= 50 else (-5.0, 'garden')
            else:
                z, kind = -5.0, 'street'
            cells[(x, y)] = (z, kind)
    return cells


def steps():
    """The town steps from the gate down toward the square: a landing, two flights of half-metre treads, a landing,
    a third flight and the street beyond. [(x, y, low, high)] for stair cells; landings and the street as plain cells."""
    stairs, plain = [], {}
    z = -.6
    for y in range(30, 76):
        flight = 31 <= y <= 36 or 39 <= y <= 41
        for x in STEPS_X:
            if flight:
                stairs.append((x, y, z - .5, z))
            else:
                plain[(x, y)] = z
        if flight:
            z -= .5
    return stairs, plain


# Background houses: [asset, x, y, ground z, turn, look]; turn 0 faces south, 90 east, 180 north, 270 west.
HOUSES = [
    # The lower town south, its fronts on the street under the wall (north); a second row beyond the cross street.
    ['seaside-saltwind-house', -14.0, -15.0, LT, 180, {'seed': 101, 'plain': True}],
    ['seaside-rosewash-house', -2.0, -14.0, LT, 180, {'seed': 102, 'plain': True}],
    ['seaside-eaveside-terrace', 9.5, -15.0, LT, 180, {'seed': 103, 'plain': True}],
    ['seaside-shingle-court-cottage', 22.0, -13.5, LT, 180, 104],
    ['seaside-lantern-row-house', 33.0, -13.5, LT, 180, {'seed': 105, 'plain': True}],
    ['seaside-rosewash-house', 43.0, -14.0, LT, 180, {'seed': 106, 'plain': True}],
    ['seaside-rosewash-house', -8.0, -33.0, LT, 0, {'seed': 107, 'plain': True}],
    ['seaside-saltwind-house', 6.0, -34.0, LT, 0, {'seed': 108, 'plain': True}],
    ['seaside-eaveside-terrace', 22.0, -34.0, LT, 0, {'seed': 109, 'plain': True}],
    ['seaside-lantern-row-house', 37.0, -33.0, LT, 0, {'seed': 110, 'plain': True}],
    # The lower town east, fronts on the street under the east wall (west).
    ['seaside-rosewash-house', 36.0, -2.0, LT, 270, {'seed': 111, 'plain': True}],
    ['seaside-saltwind-house', 36.5, 10.0, LT, 270, {'seed': 112, 'plain': True}],
    ['seaside-shingle-court-cottage', 36.0, 22.0, LT, 270, 113],
    ['seaside-lantern-row-house', 52.0, 0.0, LT, 90, {'seed': 114, 'plain': True}],
    ['seaside-eaveside-terrace', 54.0, 13.0, LT, 90, {'seed': 115, 'plain': True}],
    ['seaside-rosewash-house', 53.0, 25.0, LT, 90, {'seed': 116, 'plain': True}],
    # Behind the workshop row, up the hill: facing east over the lane's roofs.
    ['seaside-rosewash-house', -10.0, 9.0, 3.0, 90, 117],
    ['seaside-saltwind-house', -11.0, 20.0, 3.0, 90, 118],
    ['seaside-lantern-row-house', -10.0, 30.5, 3.0, 90, 119],
    ['seaside-eaveside-terrace', -26.0, 12.0, 5.0, 90, {'seed': 120, 'plain': True}],
    ['seaside-rosewash-house', -26.0, 25.0, 5.0, 90, {'seed': 121, 'plain': True}],
    ['seaside-shingle-court-cottage', -12.0, -3.0, 4.7, 0, {'seed': 122, 'plain': True}],
    ['seaside-saltwind-house', -27.0, -2.0, 4.7, 0, {'seed': 123, 'plain': True}],
    # North of the lane, either side of the town steps as they go down.
    ['seaside-rosewash-house', 4.0, 32.5, 1.0, 90, 124],
    ['seaside-lantern-row-house', 6.0, 44.0, -2.0, 90, {'seed': 125, 'plain': True}],
    ['seaside-shingle-court-cottage', 22.0, 35.5, -3.0, 270, 126],
    ['seaside-saltwind-house', 22.5, 45.0, -3.0, 270, {'seed': 127, 'plain': True}],
    ['seaside-eaveside-terrace', 36.0, 38.0, -3.0, 0, {'seed': 128, 'plain': True}],
    ['seaside-rosewash-house', -9.0, 41.0, 3.0, 90, {'seed': 129, 'plain': True}],
    ['seaside-saltwind-house', 6.0, 60.0, -5.0, 0, {'seed': 130, 'plain': True}],
    ['seaside-lantern-row-house', 22.0, 60.0, -5.0, 0, {'seed': 131, 'plain': True}],
]

TREES = [
    ['lane-tree', -6.0, 2.0, 4.7, 0, 1.0], ['lane-cypress', -6.0, 14.5, 3.0, 0, 1.0], ['lane-tree', -17.0, 24.0, 3.0, 90, .9],
    ['lane-tree', 30.0, -22.0, LT, 30, 1.0], ['lane-tree', 8.0, -24.0, LT, 120, 1.1], ['lane-cypress', 31.0, 4.0, LT, 0, 1.1],
    ['lane-tree', 44.0, 18.0, LT, 200, 1.0], ['lane-tree', 9.0, 39.0, -2.0, 0, .9], ['lane-cypress', 17.0, 41.0, -3.0, 0, 1.0],
    ['lane-tree', 30.0, 46.0, -3.0, 80, 1.0],
]
