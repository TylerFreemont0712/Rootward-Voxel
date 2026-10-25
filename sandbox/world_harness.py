"""Executed by CPython/WASI in a fresh job directory, never by host Python.

The harness turns the plain-data world snapshot into small objects a learner can read aloud
(`lamp.set_lit(True)`), and records each call as a command. It never touches the engine: the game
validates every recorded command again before anything changes.
"""
import json
import sys


class WorldError(Exception):
    """A mistake the notebook can explain in plain words."""


def _names(items):
    return ", ".join(repr(item.id) for item in items) or "none yet"


class _Recorder:
    def __init__(self):
        self.commands = []


_recorder = _Recorder()

# What the player's code has earned the right to do to houses, trees and doodads (set when the world is built).
_build = {}
_FACINGS = {"north": "N", "east": "E", "south": "S", "west": "W"}


def _need(ability, what):
    """Refuse, in plain words, an ability the player has not learned yet. The game checks it again."""
    if ability in _build.get("abilities", []):
        return
    lesson = _build.get("lessons", {}).get(ability)
    if lesson:
        raise WorldError("Your code cannot %s yet. Reach the lesson %r to learn how." % (what, lesson))
    raise WorldError("Your code cannot %s in this valley." % what)


def _direction(value):
    if not isinstance(value, str) or value not in _FACINGS:
        raise WorldError('face needs "north", "east", "south" or "west", not ' + repr(value))
    return value


def _cell(value, what):
    if isinstance(value, (list, tuple)) and len(value) in (2, 3) and all(
            isinstance(part, int) and not isinstance(part, bool) for part in value):
        return [value[0], value[1], 0 if len(value) == 2 else value[2]]
    raise TypeError(what + " needs a cell like [x, y, 0] (take one from bridge.cells), not " + repr(value))


class Lamp:
    def __init__(self, data):
        self.id = data["id"]
        self.zone = data["zone"]
        self.cell = data["cell"]
        self.lit = data["lit"]

    def set_lit(self, value):
        if not isinstance(value, bool):
            raise TypeError("set_lit needs True or False, not " + repr(value))
        _recorder.commands.append({"op": "set_field", "entity_id": self.id, "field": "enabled", "value": value})
        self.lit = value

    def __repr__(self):
        return "<Lamp %r lit=%s>" % (self.id, self.lit)


class Gate:
    def __init__(self, data):
        self.id = data["id"]
        self.zone = data["zone"]
        self.cell = data["cell"]
        self.is_open = data["open"]

    def set_open(self, value):
        if not isinstance(value, bool):
            raise TypeError("set_open needs True or False, not " + repr(value))
        _recorder.commands.append({"op": "set_field", "entity_id": self.id, "field": "open", "value": value})
        self.is_open = value

    def __repr__(self):
        return "<Gate %r is_open=%s>" % (self.id, self.is_open)


class Bridge:
    def __init__(self, data):
        self.id = data["id"]
        self.zone = data["zone"]
        self.cells = data["cells"]
        self.built = data["built"]

    def place_deck(self, cell):
        cell = _cell(cell, "place_deck")
        _recorder.commands.append({"op": "place", "kind": "bridge_deck", "at": cell})
        if self.built < len(self.cells) and cell == self.cells[self.built]:
            self.built += 1

    def remove_deck(self, cell):
        cell = _cell(cell, "remove_deck")
        _recorder.commands.append({"op": "remove", "at": cell})
        if self.built > 0 and cell == self.cells[self.built - 1]:
            self.built -= 1

    def __repr__(self):
        return "<Bridge %r built=%d of %d>" % (self.id, self.built, len(self.cells))


class Prop:
    """A builder object with a declared boolean interaction; no meshes or engine objects are exposed."""
    def __init__(self, data):
        self.id = data["id"]
        self.asset = data["asset"]
        self.name = data["name"]
        self.zone = data["zone"]
        self.cell = data["cell"]
        self.active = data["active"]

    def set_active(self, value):
        if not isinstance(value, bool):
            raise TypeError("set_active needs True or False, not " + repr(value))
        _recorder.commands.append({"op": "set_field", "entity_id": self.id, "field": "active", "value": value})
        self.active = value

    def __repr__(self):
        return "<Prop %r active=%s>" % (self.id, self.active)


class _Standing:
    """What houses and doodads share: where they stand and which way they face. A change you make is
    recorded as a command and shown on the object at once, so `house.face("north")` then `house.facing`
    reads back what you just asked for."""
    def __init__(self, data):
        self.id = data["id"]
        self.kind = data["kind"]
        self.name = data["name"]
        self.at = data["at"]
        self.cell = data["cell"]
        self.facing = data["facing"]
        self.zone = data["zone"]

    def face(self, direction):
        _need("turn", "turn houses and doodads")
        direction = _direction(direction)
        if direction == self.facing:
            return
        _recorder.commands.append({"op": "rotate", "entity_id": self.id, "facing": _FACINGS[direction]})
        self.facing = direction


class House(_Standing):
    def __init__(self, data):
        _Standing.__init__(self, data)
        self.locked = data["locked"]

    def __repr__(self):
        return "<House %r facing=%s>" % (self.id, self.facing)


class Doodad(_Standing):
    def __init__(self, data):
        _Standing.__init__(self, data)
        self.solid = data["solid"]

    def __repr__(self):
        return "<Doodad %r facing=%s>" % (self.id, self.facing)


class Tree:
    def __init__(self, data):
        self.at = data["at"]
        self.cell = data["cell"]
        self.size = data["size"]
        self.kind = data["kind"]
        self.zone = data["zone"]

    def __repr__(self):
        return "<Tree at=%r>" % (self.at,)


class Zone:
    def __init__(self, data, lamps, gates, bridges, props, houses, trees, doodads):
        self.id = data["id"]
        self.name = data["title"]
        self.lamps = [lamp for lamp in lamps if lamp.zone == self.id]
        self.gates = [gate for gate in gates if gate.zone == self.id]
        self.bridges = [bridge for bridge in bridges if bridge.zone == self.id]
        self.props = [prop for prop in props if prop.zone == self.id]
        self._houses = [house for house in houses if house.zone == self.id]
        self._trees = [tree for tree in trees if tree.zone == self.id]
        self._doodads = [doodad for doodad in doodads if doodad.zone == self.id]

    @property
    def houses(self):
        _need("read", "see the houses")
        return self._houses

    @property
    def trees(self):
        _need("read", "see the trees")
        return self._trees

    @property
    def doodads(self):
        _need("read", "see the doodads")
        return self._doodads

    def __repr__(self):
        return "<Zone %r: %d lamps>" % (self.id, len(self.lamps))


class World:
    def __init__(self, raw):
        self._raw = raw
        self.lamps = [Lamp(item) for item in raw.get("lamps", [])]
        self.gates = [Gate(item) for item in raw.get("gates", [])]
        self.bridges = [Bridge(item) for item in raw.get("bridges", [])]
        self.props = [Prop(item) for item in raw.get("props", [])]
        _build.clear()
        _build.update(raw.get("build", {}))
        self._houses = [House(item) for item in _build.get("houses", [])]
        self._trees = [Tree(item) for item in _build.get("trees", [])]
        self._doodads = [Doodad(item) for item in _build.get("doodads", [])]
        self.zones = [Zone(item, self.lamps, self.gates, self.bridges, self.props, self._houses, self._trees, self._doodads) for item in raw.get("zones", [])]
        self.player = raw["player"]
        self.memory = raw["memory"]

    def _find(self, items, wanted, kind):
        for item in items:
            if item.id == wanted:
                return item
        raise WorldError("There is no %s called %r that you can reach. Known: %s." % (kind, wanted, _names(items)))

    def lamp(self, name):
        return self._find(self.lamps, name, "lamp")

    def gate(self, name):
        return self._find(self.gates, name, "gate")

    def bridge(self, name):
        return self._find(self.bridges, name, "bridge")

    def prop(self, name):
        return self._find(self.props, name, "interactive object")

    def zone(self, name):
        return self._find(self.zones, name, "zone")

    @property
    def houses(self):
        _need("read", "see the houses")
        return self._houses

    def house(self, name):
        _need("read", "see the houses")
        return self._find(self._houses, name, "house")

    @property
    def trees(self):
        _need("read", "see the trees")
        return self._trees

    def tree(self, x, y):
        _need("read", "see the trees")
        for tree in self._trees:
            if abs(tree.at[0] - x) < 0.01 and abs(tree.at[1] - y) < 0.01:
                return tree
        raise WorldError("There is no tree at [%s, %s] that you can reach. Trees stand on whole and half cells: read world.trees for the real places." % (x, y))

    @property
    def doodads(self):
        _need("read", "see the doodads")
        return self._doodads

    def doodad(self, name):
        _need("read", "see the doodads")
        return self._find(self._doodads, name, "doodad")

    @property
    def here(self):
        for zone in self.zones:
            if zone.id == self._raw.get("zone"):
                return zone
        return None

    # The raw snapshot stays reachable for older programs: world["player"], world["memory"].
    def __getitem__(self, key):
        return self._raw[key]

    def get(self, key, default=None):
        return self._raw.get(key, default)


raw_world = json.load(sys.stdin)
with open("player.py", encoding="utf-8") as source_file:
    source = source_file.read()

# The normal Rootward launcher reports syntax/runtime/memory errors and enforces
# WASI isolation. The harness provides data, never engine objects or host callbacks.
namespace = {"__name__": "player", "__file__": "player.py"}
exec(compile(source, "player.py", "exec"), namespace)
program = namespace.get("program")
if not callable(program):
    raise TypeError("Define program(world) and put your changes inside it.")
world = World(raw_world)
answer = program(world)
commands = list(_recorder.commands)
memory = world.memory
if answer is None:
    pass
elif isinstance(answer, list):
    commands += answer
elif isinstance(answer, dict) and set(answer) == {"commands", "memory"}:
    if not isinstance(answer["commands"], list) or not isinstance(answer["memory"], dict):
        raise TypeError("commands must be a list; memory must be a dictionary.")
    commands += answer["commands"]
    memory = answer["memory"]
else:
    raise TypeError("program(world) does not need to return anything. Returned " + repr(answer)[:40] + ".")
if not isinstance(commands, list) or not isinstance(memory, dict):
    raise TypeError("commands must be a list; memory must be a dictionary.")
payload = json.dumps({"commands": commands, "memory": memory}, allow_nan=False, separators=(",", ":"))
if len(payload.encode("utf-8")) > 16384:
    raise ValueError("Returned commands exceed the 16 KiB result limit.")
print("\n__VOXEL_RESULT__" + payload)
