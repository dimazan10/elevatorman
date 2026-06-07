extends Node2D

const SECRET_SCENE = preload("res://Scenes/Game/SecretLevel.tscn")
const PLAYER_SCENE = preload("res://Objects/player.tscn")
const HEALTH_UI = preload("res://Objects/UI_HP.tscn")
const DASH_UI = preload("res://Objects/DashUI.tscn")

@export var module_count: int = 5
@export var module_radius: float = 300.0
@export var module_spacing_extra: float = 32.0
@export var safe_mode: bool = true # when true, do not instantiate player/UI/complex nodes
@export var spawn_player: bool = false
@export var spawn_ui: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var modules: Array = []

func _ready() -> void:
    rng.randomize()

    var container: Node2D = Node2D.new()
    container.name = "FloorContainer"
    add_child(container)

    var center: Vector2 = Vector2(640, 360)

    # Create first module at center
    var first = _create_module(center, module_radius, 0, container)
    modules.append(first)

    # Create other modules around existing ones
    for i in range(1, module_count):
        var placed: bool = false
        var tries: int = 0
        while not placed and tries < 20:
            var parent_idx: int = rng.randi_range(0, modules.size() - 1)
            var parent_mod: Node2D = modules[parent_idx]
            var dir_idx: int = rng.randi_range(0, 5)
            var angle: float = dir_idx * PI / 3.0
            var offset: Vector2 = Vector2(cos(angle), sin(angle)) * (module_radius * 2 + module_spacing_extra)
            var pos: Vector2 = parent_mod.position + offset
            var ok: bool = true
            for m in modules:
                if m.position.distance_to(pos) < (module_radius * 1.5):
                    ok = false
                    break
            if ok:
                var mod = _create_module(pos, module_radius, i, container)
                modules.append(mod)
                _create_corridor(parent_mod.position, pos, container)
                placed = true
            tries += 1
        if not placed:
            # fallback random placement
            var pos2: Vector2 = center + Vector2(rng.randf_range(-800.0, 800.0), rng.randf_range(-300.0, 300.0))
            var mod2 = _create_module(pos2, module_radius, i, container)
            modules.append(mod2)
            var rand_parent_idx: int = rng.randi_range(0, modules.size() - 1)
            _create_corridor(modules[rand_parent_idx].position, pos2, container)

    # Optionally spawn player/UI — disabled in safe_mode to avoid crashes
    if not safe_mode and spawn_player:
        var player_inst = PLAYER_SCENE.instantiate()
        add_child(player_inst)
        player_inst.position = modules[0].position

    if not safe_mode and spawn_ui:
        var h = HEALTH_UI.instantiate()
        add_child(h)
        var d = DASH_UI.instantiate()
        add_child(d)

    # Place a lightweight Hole placeholder (avoid instancing the full SecretLevel to prevent crashes)
    var hole_node: Node2D = Node2D.new()
    hole_node.name = "Hole"
    hole_node.position = modules[0].position
    var hole_sprite: Sprite2D = Sprite2D.new()
    var hole_tex = load("res://Assets/SpritesElevator/Hole.png")
    if hole_tex:
        hole_sprite.texture = hole_tex
    hole_node.add_child(hole_sprite)

    var floor_elev: Sprite2D = Sprite2D.new()
    var lift_tex = load("res://Assets/SpritesElevator/Lift2.png")
    if lift_tex:
        floor_elev.texture = lift_tex
    floor_elev.position = Vector2(0, -61)
    hole_node.add_child(floor_elev)

    add_child(hole_node)


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
