## Temporary test environment for player movement verification.
## Draws a large grass field, a pixel grid, trees and rocks with Y-sorting.
## This scene is for prototype testing only and will be replaced by the
## permanent world in a later task.
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
@onready var ground_node: Node2D = $Ground
@onready var landmarks_container: Node2D = $Landmarks


func _ready() -> void:
	if ground_node:
		ground_node.draw.connect(_draw_ground_layer)
		ground_node.queue_redraw()
	_create_obstacles()


func _draw_ground_layer() -> void:
	if not ground_node:
		return
	var size: float = GROUND_HALF * 2.0
	# Grass ground
	ground_node.draw_rect(
		Rect2(Vector2(-GROUND_HALF, -GROUND_HALF), Vector2(size, size)),
		COLOR_GROUND
	)
	# Grid
	var half: int = GROUND_HALF
	var x: int = -half
	while x <= half:
		ground_node.draw_line(Vector2(x, -half), Vector2(x, half), COLOR_GRID, GRID_WIDTH)
		x += GRID_STEP
	var y: int = -half
	while y <= half:
		ground_node.draw_line(Vector2(-half, y), Vector2(half, y), COLOR_GRID, GRID_WIDTH)
		y += GRID_STEP
	# Origin marker
	ground_node.draw_line(Vector2(-12.0, 0.0), Vector2(12.0, 0.0), COLOR_ORIGIN, 2.0)
	ground_node.draw_line(Vector2(0.0, -12.0), Vector2(0.0, 12.0), COLOR_ORIGIN, 2.0)


func _create_obstacles() -> void:
	var container: Node2D = landmarks_container if landmarks_container != null else self

	# Create individual tree obstacle bodies with self-contained rendering and accurate collision
	for i in range(TREE_POSITIONS.size()):
		var pos: Vector2 = TREE_POSITIONS[i]
		var tree_body: StaticBody2D = StaticBody2D.new()
		tree_body.name = "Tree_%d" % i
		# Sort origin is set at the ground contact line of the trunk base: pos + Vector2(0, 2)
		tree_body.position = pos + Vector2(0.0, 2.0)
		tree_body.collision_layer = 1
		tree_body.collision_mask = 0

		# Tree visual drawing callback on the tree body itself
		tree_body.draw.connect(func():
			# Brown trunk rectangle: matches original pos + [-5, -6, 10, 24] in world space
			tree_body.draw_rect(Rect2(-5.0, -8.0, 10.0, 24.0), COLOR_TRUNK)
			# Green foliage circle: matches original pos + (0, -20) radius 22 in world space
			tree_body.draw_circle(Vector2(0.0, -22.0), 22.0, COLOR_FOLIAGE)
		)

		# Tree collision shape: accurately covers the visible trunk base (width 10, height 24)
		var col: CollisionShape2D = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(10.0, 24.0)
		col.shape = shape
		col.position = Vector2(0.0, 4.0)  # In world space: (pos.x, pos.y + 6.0)

		tree_body.add_child(col)
		container.add_child(tree_body)

	# Create individual rock obstacle bodies with self-contained rendering and accurate collision
	for i in range(ROCK_POSITIONS.size()):
		var pos: Vector2 = ROCK_POSITIONS[i]
		var rock_body: StaticBody2D = StaticBody2D.new()
		rock_body.name = "Rock_%d" % i
		# Sort origin is set at the ground contact line of the rock: pos + Vector2(0, -3)
		rock_body.position = pos + Vector2(0.0, -3.0)
		rock_body.collision_layer = 1
		rock_body.collision_mask = 0

		# Rock visual drawing callback on the rock body itself
		rock_body.draw.connect(func():
			# Dark shadow: matches original pos + (2, 3) radius 15 in world space
			rock_body.draw_circle(Vector2(2.0, 6.0), 15.0, COLOR_ROCK_DARK)
			# Main rock body: matches original pos + (0, 0) radius 13 in world space
			rock_body.draw_circle(Vector2(0.0, 3.0), 13.0, COLOR_ROCK)
		)

		# Rock collision shape: matches the visible rock body circle (radius 13)
		var col: CollisionShape2D = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 13.0
		col.shape = shape
		col.position = Vector2(0.0, 3.0)  # In world space: (pos.x, pos.y)

		rock_body.add_child(col)
		container.add_child(rock_body)
