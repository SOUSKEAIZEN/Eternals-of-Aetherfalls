## Temporary test environment for player movement verification.
## Draws a large grass field, a pixel grid, trees and rocks using _draw().
## This scene is for prototype testing only and will be replaced by the
## permanent world in a later task.
##
## Nothing here moves or runs any per-frame logic — _draw() is called once
## on startup and never again, keeping runtime cost at zero.
extends Node2D


# ---------------------------------------------------------------------------
# Ground
# ---------------------------------------------------------------------------
const GROUND_HALF: int    = 3000
const COLOR_GROUND: Color = Color(0.29, 0.54, 0.20)        # Grass green

# ---------------------------------------------------------------------------
# Grid
# ---------------------------------------------------------------------------
const GRID_STEP: int      = 100
const GRID_WIDTH: float   = 1.0
const COLOR_GRID: Color   = Color(0.22, 0.44, 0.14, 0.45)  # Darker green, semi-transparent

# ---------------------------------------------------------------------------
# Origin marker  (white cross at world 0,0 — shows player spawn point)
# ---------------------------------------------------------------------------
const COLOR_ORIGIN: Color = Color(1.0, 1.0, 1.0, 0.70)

# ---------------------------------------------------------------------------
# Trees
# ---------------------------------------------------------------------------
const COLOR_TRUNK:   Color = Color(0.42, 0.26, 0.09)
const COLOR_FOLIAGE: Color = Color(0.14, 0.44, 0.09)

const TREE_POSITIONS: Array = [
	Vector2(-400, -300), Vector2( 500, -250), Vector2(-200,  400),
	Vector2( 700,  300), Vector2(-600,  100), Vector2( 300, -500),
	Vector2(-800, -400), Vector2( 900, -100), Vector2(-100,  700),
	Vector2( 600,  600), Vector2(-700,  700), Vector2( 200, -800),
	Vector2(-500, -700), Vector2( 800, -600), Vector2(-300, -600),
	Vector2(1200,  400), Vector2(-1200, -200), Vector2(1000,  800),
	Vector2(-1000, 600), Vector2( 400, 1200), Vector2(-1400,  500),
	Vector2(1500, -400), Vector2(-200, -1200), Vector2(1300, 1000),
	Vector2(-1600, -800), Vector2(1800,  300), Vector2(-500, 1600),
]

# ---------------------------------------------------------------------------
# Rocks
# ---------------------------------------------------------------------------
const COLOR_ROCK:      Color = Color(0.52, 0.52, 0.52)
const COLOR_ROCK_DARK: Color = Color(0.36, 0.36, 0.36)

const ROCK_POSITIONS: Array = [
	Vector2( 150,  200), Vector2(-350,  150), Vector2( 600, -400),
	Vector2(-450,  500), Vector2( 800,  200), Vector2(-200, -500),
	Vector2(1100, -300), Vector2(-900,  400), Vector2( 300,  900),
	Vector2(-700, -600), Vector2( 500, 1100), Vector2(-1100, 800),
	Vector2(1400,  200), Vector2(-300, 1300), Vector2( 700, -900),
	Vector2(-1300, -500), Vector2(1600,  600), Vector2(-800, 1500),
]


# ---------------------------------------------------------------------------
# Setup & Lifecycle
# ---------------------------------------------------------------------------
@onready var landmarks_container: Node2D = $Landmarks


func _ready() -> void:
	_create_obstacles()


func _create_obstacles() -> void:
	var container: Node2D = landmarks_container if landmarks_container != null else self

	# Create tree trunk collision bodies
	for i in range(TREE_POSITIONS.size()):
		var pos: Vector2 = TREE_POSITIONS[i]
		var tree_body: StaticBody2D = StaticBody2D.new()
		tree_body.name = "Tree_%d" % i
		tree_body.position = pos
		tree_body.collision_layer = 1
		tree_body.collision_mask = 0

		var col: CollisionShape2D = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape: CapsuleShape2D = CapsuleShape2D.new()
		shape.radius = 5.0
		shape.height = 24.0
		col.shape = shape
		col.position = Vector2(0.0, 6.0)  # Matches trunk rect center

		tree_body.add_child(col)
		container.add_child(tree_body)

	# Create rock collision bodies
	for i in range(ROCK_POSITIONS.size()):
		var pos: Vector2 = ROCK_POSITIONS[i]
		var rock_body: StaticBody2D = StaticBody2D.new()
		rock_body.name = "Rock_%d" % i
		rock_body.position = pos
		rock_body.collision_layer = 1
		rock_body.collision_mask = 0

		var col: CollisionShape2D = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 13.0  # Matches rock body circle radius
		col.shape = shape

		rock_body.add_child(col)
		container.add_child(rock_body)


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------
func _draw() -> void:
	_draw_ground()
	_draw_grid()
	_draw_rocks()     # Rocks behind trees
	_draw_trees()
	_draw_origin_marker()


func _draw_ground() -> void:
	var size: float = GROUND_HALF * 2.0
	draw_rect(
		Rect2(Vector2(-GROUND_HALF, -GROUND_HALF), Vector2(size, size)),
		COLOR_GROUND
	)


func _draw_grid() -> void:
	var half: int = GROUND_HALF
	# Vertical lines
	var x: int = -half
	while x <= half:
		draw_line(Vector2(x, -half), Vector2(x, half), COLOR_GRID, GRID_WIDTH)
		x += GRID_STEP
	# Horizontal lines
	var y: int = -half
	while y <= half:
		draw_line(Vector2(-half, y), Vector2(half, y), COLOR_GRID, GRID_WIDTH)
		y += GRID_STEP


func _draw_trees() -> void:
	for pos in TREE_POSITIONS:
		_draw_tree(pos)


func _draw_tree(pos: Vector2) -> void:
	# Brown trunk rectangle
	draw_rect(Rect2(pos + Vector2(-5.0, -6.0), Vector2(10.0, 24.0)), COLOR_TRUNK)
	# Green foliage circle, centred above the trunk
	draw_circle(pos + Vector2(0.0, -20.0), 22.0, COLOR_FOLIAGE)


func _draw_rocks() -> void:
	for pos in ROCK_POSITIONS:
		_draw_rock(pos)


func _draw_rock(pos: Vector2) -> void:
	# Dark shadow slightly offset for depth
	draw_circle(pos + Vector2(2.0, 3.0), 15.0, COLOR_ROCK_DARK)
	# Main rock body
	draw_circle(pos, 13.0, COLOR_ROCK)


func _draw_origin_marker() -> void:
	# White cross marks world (0, 0) — the player's start position
	draw_line(Vector2(-12.0, 0.0), Vector2(12.0, 0.0), COLOR_ORIGIN, 2.0)
	draw_line(Vector2(0.0, -12.0), Vector2(0.0, 12.0), COLOR_ORIGIN, 2.0)
