extends Node2D

# Minimal script - no preloads to avoid crashes
@export var module_count: int = 3
@export var module_radius: float = 250.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var modules: Array = []

func _ready() -> void:
    print("Level_G: _ready() starting")
    rng.randomize()

    var container: Node2D = Node2D.new()
    container.name = "FloorContainer"
    add_child(container)

    var center: Vector2 = Vector2(640, 360)

    # Create first module at center only
    var first = _create_module(center, module_radius, 0, container)
    modules.append(first)
    
    print("Level_G: module 0 created")


func _hex_points(radius: float) -> PackedVector2Array:
    var pts: PackedVector2Array = PackedVector2Array()
    for i in range(6):
        var angle: float = PI / 3.0 * i + PI / 6.0
        pts.append(Vector2(cos(angle), sin(angle)) * radius)
    return pts


func _create_module(pos: Vector2, radius: float, index: int, parent: Node) -> Node2D:
    var mod: Node2D = Node2D.new()
    mod.name = "Module_%d" % index
    mod.position = pos

    var poly: Polygon2D = Polygon2D.new()
    poly.polygon = _hex_points(radius)
    poly.color = Color(0.12, 0.15, 0.19)
    mod.add_child(poly)

    var label: Label = Label.new()
    label.text = "M%d" % index
    label.position = Vector2(0, -radius * 0.4)
    mod.add_child(label)

    var spawn: Node2D = Node2D.new()
    spawn.name = "SpawnPoint"
    spawn.position = Vector2(0, 0)
    mod.add_child(spawn)

    parent.add_child(mod)
    return mod


func _create_corridor(a: Vector2, b: Vector2, parent: Node) -> Node2D:
    var cor: Node2D = Node2D.new()
    cor.position = a
    var line: Line2D = Line2D.new()
    line.width = 18.0
    line.default_color = Color(0.25, 0.25, 0.3)
    line.points = [Vector2.ZERO, b - a]
    cor.add_child(line)
    parent.add_child(cor)
    return cor
