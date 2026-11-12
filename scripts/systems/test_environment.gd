## Environment manager for Eternals of Aetherfalls.
## Manages environmental obstacles (trees, rocks, boundary forests, water barriers)
## and props (fallen logs, stumps, bushes, ferns, mushrooms, bridge, waterfall, landmarks)
## with proper Y-sorting and precise physics collision footprints.
extends Node2D

# ---------------------------------------------------------------------------
# Landmark Obstacle Positions (World Coordinates - Strictly Preserved for Regressions)
# ---------------------------------------------------------------------------
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

const ROCK_POSITIONS: Array = [
	Vector2( 150,  200), Vector2(-350,  150), Vector2( 600, -400),
	Vector2(-450,  500), Vector2( 800,  200), Vector2(-200, -500),
	Vector2(1100, -300), Vector2(-900,  400), Vector2( 300,  900),
	Vector2(-700, -600), Vector2( 500, 1100), Vector2(-1100, 800),
	Vector2(1400,  200), Vector2(-300, 1300), Vector2( 700, -900),
	Vector2(-1300, -500), Vector2(1600,  600), Vector2(-800, 1500),
]

# ---------------------------------------------------------------------------
# Preloaded Asset Library
# ---------------------------------------------------------------------------
const TEX_TREE_LARGE: Texture2D   = preload("res://assets/environments/tree_large.png") # 80x96 Oak
const TEX_TREE_MED: Texture2D     = preload("res://assets/environments/tree_deciduous_med.png") # 48x64
const TEX_PINE_LARGE: Texture2D   = preload("res://assets/environments/tree_pine_large.png") # 44x76
const TEX_PINE_SMALL: Texture2D   = preload("res://assets/environments/tree_pine_small.png") # 32x52
const TEX_BOULDER: Texture2D      = preload("res://assets/environments/boulder.png") # 36x32
const TEX_BOULDER_LG: Texture2D   = preload("res://assets/environments/boulder_large.png") # 48x36
const TEX_LOG: Texture2D          = preload("res://assets/environments/log.png") # 36x18
const TEX_BUSH: Texture2D         = preload("res://assets/environments/bush.png") # 24x20
const TEX_STUMP: Texture2D        = preload("res://assets/environments/tree_stump.png") # 20x18
const TEX_FERN: Texture2D         = preload("res://assets/environments/fern.png") # 26x20
const TEX_MUSHROOMS: Texture2D    = preload("res://assets/environments/mushrooms.png") # 20x16
const TEX_BRIDGE: Texture2D       = preload("res://assets/environments/bridge_wood.png") # 64x36
const TEX_WATERFALL: Texture2D    = preload("res://assets/environments/waterfall_anim.png") # 128x64 (4 frames)
const TEX_LANDMARKS: Texture2D    = preload("res://assets/environments/landmark_props.png") # 48x24
const TEX_RUINS: Texture2D        = preload("res://assets/environments/ruins_wall.png") # 48x32
const TEX_AQUATIC: Texture2D      = preload("res://assets/environments/aquatic_props.png") # 32x20

@onready var landmarks_container: Node2D = $Landmarks

func _ready() -> void:
	y_sort_enabled = true
	_create_landmarks()
	_create_forest_world()

# ---------------------------------------------------------------------------
# Strict Regression Landmarks
# ---------------------------------------------------------------------------
func _create_landmarks() -> void:
	var container: Node2D = landmarks_container if landmarks_container != null else self
	container.y_sort_enabled = true

	# Tree_0 through Tree_N
	for i in range(TREE_POSITIONS.size()):
		var pos: Vector2 = TREE_POSITIONS[i]
		var tree_body: StaticBody2D = StaticBody2D.new()
		tree_body.name = "Tree_%d" % i
		tree_body.position = pos + Vector2(0.0, 2.0)
		tree_body.collision_layer = 1
		tree_body.collision_mask = 0

		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = TEX_TREE_LARGE
		sprite.position = Vector2(0.0, -40.0) # trunk contact at y=0
		tree_body.add_child(sprite)

		var col: CollisionShape2D = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(10.0, 24.0)
		col.shape = shape
		col.position = Vector2(0.0, 4.0)

		tree_body.add_child(col)
		container.add_child(tree_body)

	# Rock_0 through Rock_N (Rock_0 at (150, 200) with radius 16.0 at position = pos)
	for i in range(ROCK_POSITIONS.size()):
		var pos: Vector2 = ROCK_POSITIONS[i]
		var rock_body: StaticBody2D = StaticBody2D.new()
		rock_body.name = "Rock_%d" % i
		rock_body.position = pos
		rock_body.collision_layer = 1
		rock_body.collision_mask = 0

		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = TEX_BOULDER
		sprite.position = Vector2(0.0, 0.0)
		rock_body.add_child(sprite)

		var col: CollisionShape2D = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 16.0
		col.shape = shape
		col.position = Vector2(0.0, 0.0)

		rock_body.add_child(col)
		container.add_child(rock_body)

# ---------------------------------------------------------------------------
# Full Designed Forest Environment (Task 4B.5)
# ---------------------------------------------------------------------------
func _create_forest_world() -> void:
	var props_container: Node2D = get_node_or_null("Props")
	if not props_container:
		props_container = Node2D.new()
		props_container.name = "Props"
		props_container.y_sort_enabled = true
		add_child(props_container)
	else:
		props_container.y_sort_enabled = true

	# 1. DENSE BOUNDARY CANOPY WALLS (North, South, West, East)
	_build_boundary_canopies(props_container)

	# 2. AREA A & B: WOODLAND CLEARING & FOREST TRAILS
	_build_woodland_trails_and_clearing(props_container)

	# 3. AREA C: POND & WATERFALL & RIVER SYSTEM
	_build_water_system(props_container)

	# 4. AREA D: DENSE WOODS & UNDERGROWTH
	_build_dense_woods_and_undergrowth(props_container)

	# 5. AREA E: EXPLORATION LANDMARK (Ancient Campsite & Ruins)
	_build_exploration_landmark(props_container)

# ---------------------------------------------------------------------------
# 1. Boundary Canopies
# ---------------------------------------------------------------------------
func _build_boundary_canopies(parent: Node2D) -> void:
	# North Forest Boundary (y: -210 to -240)
	for x in range(-250, 275, 48):
		if abs(x) < 25: continue # keep north trail open
		var y_off = -220 + int(sin(x * 0.05) * 12)
		if (x / 48) % 2 == 0:
			_spawn_oak_large(parent, Vector2(x, y_off))
		else:
			_spawn_pine_large(parent, Vector2(x + 10, y_off + 8))

	# South Forest Boundary (y: 210 to 240)
	for x in range(-250, 275, 48):
		if abs(x) < 25: continue # keep south trail open
		# Leave wide clearance around (150, 200) for Rock_0!
		if abs(x - 150) < 65: continue
		var y_off = 220 + int(cos(x * 0.05) * 12)
		if (x / 48) % 2 == 0:
			_spawn_oak_large(parent, Vector2(x, y_off))
		else:
			_spawn_pine_large(parent, Vector2(x - 10, y_off - 8))

	# West Forest Boundary (x: -210 to -245)
	for y in range(-190, 190, 45):
		if abs(y) < 25: continue # keep west trail open
		var x_off = -225 + int(sin(y * 0.06) * 12)
		_spawn_oak_large(parent, Vector2(x_off, y))
		_spawn_pine_small(parent, Vector2(x_off + 25, y + 15))

	# East Forest Boundary (x: 290 to 330)
	for y in range(-190, 190, 48):
		var x_off = 310 + int(cos(y * 0.06) * 14)
		_spawn_pine_large(parent, Vector2(x_off, y))
		_spawn_oak_med(parent, Vector2(x_off - 20, y + 16))

# ---------------------------------------------------------------------------
# 2. Woodland Trails & Core Glade (Area A & B)
# ---------------------------------------------------------------------------
func _build_woodland_trails_and_clearing(parent: Node2D) -> void:
	# Framing trees around spawn (0, 0)
	# Keeping corridors |x| > 24 for north/south trail, and |y| > 24 for east/west trail
	_spawn_oak_large(parent, Vector2(-68, -68))
	_spawn_oak_med(parent, Vector2(-35, -75))
	_spawn_pine_large(parent, Vector2(65, -65))
	_spawn_pine_small(parent, Vector2(35, -75))

	# Trees framing the southern trail
	_spawn_oak_large(parent, Vector2(-65, 75))
	_spawn_pine_large(parent, Vector2(65, 75))
	_spawn_pine_small(parent, Vector2(-35, 95))
	_spawn_oak_med(parent, Vector2(40, 115))

	# Props along trail edges (kept safely off cardinal paths |x| > 22 and |y| > 22)
	_spawn_log(parent, Vector2(-32, 45))
	_spawn_stump(parent, Vector2(35, 45))
	_spawn_boulder(parent, Vector2(-38, -35))
	_spawn_bush(parent, Vector2(35, -35))
	_spawn_bush(parent, Vector2(-42, 65))
	_spawn_fern(parent, Vector2(28, 65))
	_spawn_fern(parent, Vector2(-28, -55))
	_spawn_mushrooms(parent, Vector2(-52, -58))
	_spawn_mushrooms(parent, Vector2(48, -58))

# ---------------------------------------------------------------------------
# 3. Water System: Pond, River, Waterfall, Bridge (Area C)
# ---------------------------------------------------------------------------
func _build_water_system(parent: Node2D) -> void:
	# --- SOUTHWEST POND (center: x=-112, y=96) ---
	_spawn_oak_large(parent, Vector2(-155, 65))
	_spawn_pine_large(parent, Vector2(-115, 45))
	_spawn_oak_med(parent, Vector2(-155, 135))
	_spawn_pine_small(parent, Vector2(-85, 145))
	_spawn_boulder_large(parent, Vector2(-65, 68))
	_spawn_bush(parent, Vector2(-60, 115))
	_spawn_fern(parent, Vector2(-75, 48))
	_spawn_aquatic(parent, Vector2(-125, 95))
	_spawn_aquatic(parent, Vector2(-95, 115))

	# Pond water collision boundary
	var pond_col = StaticBody2D.new()
	pond_col.name = "PondBoundary"
	pond_col.collision_layer = 1
	pond_col.collision_mask = 0
	var p_shape = CollisionShape2D.new()
	var p_cir = CircleShape2D.new()
	p_cir.radius = 32.0
	p_shape.shape = p_cir
	p_shape.position = Vector2(-112, 96)
	pond_col.add_child(p_shape)
	parent.add_child(pond_col)

	# --- NORTHERN CLIFF & WATERFALL (x: 216, y: -150..-110) ---
	var waterfall_node = Node2D.new()
	waterfall_node.name = "WaterfallFeature"
	waterfall_node.position = Vector2(216, -135)
	waterfall_node.y_sort_enabled = true

	var wf_sprite = Sprite2D.new()
	wf_sprite.name = "WaterfallSprite"
	wf_sprite.texture = TEX_WATERFALL
	wf_sprite.hframes = 4
	wf_sprite.frame = 0
	wf_sprite.position = Vector2(0, -6)
	wf_sprite.z_index = 0
	waterfall_node.add_child(wf_sprite)

	var anim_script = GDScript.new()
	anim_script.source_code = """extends Sprite2D
var _t: float = 0.0
func _process(d: float) -> void:
	_t += d
	if _t >= 0.12:
		_t -= 0.12
		frame = (frame + 1) % 4
"""
	anim_script.reload()
	wf_sprite.set_script(anim_script)

	var cliff_body = StaticBody2D.new()
	cliff_body.name = "CliffCol"
	cliff_body.collision_layer = 1
	cliff_body.collision_mask = 0
	var c_shape = CollisionShape2D.new()
	var c_rect = RectangleShape2D.new()
	c_rect.size = Vector2(90, 26)
	c_shape.shape = c_rect
	c_shape.position = Vector2(0, -18)
	cliff_body.add_child(c_shape)
	waterfall_node.add_child(cliff_body)

	parent.add_child(waterfall_node)

	_spawn_boulder_large(parent, Vector2(170, -130))
	_spawn_boulder_large(parent, Vector2(265, -130))
	_spawn_pine_large(parent, Vector2(165, -160))
	_spawn_pine_large(parent, Vector2(275, -160))

	# --- RIVER & WOODEN BRIDGE ---
	# Wooden Bridge at Vector2(216, 0) - spanning the river
	var bridge_body = StaticBody2D.new()
	bridge_body.name = "WoodenBridge"
	bridge_body.position = Vector2(216, 0)
	bridge_body.collision_layer = 1
	bridge_body.collision_mask = 0
	bridge_body.y_sort_enabled = true

	# Walkable Deck (z_index = -1 so player renders on top of deck)
	var deck = Sprite2D.new()
	deck.name = "DeckSprite"
	deck.texture = TEX_BRIDGE
	deck.z_index = -1
	deck.position = Vector2(0, 0)
	bridge_body.add_child(deck)

	# North Railing collider (y = -18)
	var rail_n = CollisionShape2D.new()
	var rn_rect = RectangleShape2D.new()
	rn_rect.size = Vector2(48, 8)
	rail_n.shape = rn_rect
	rail_n.position = Vector2(0, -18)
	bridge_body.add_child(rail_n)

	# South Railing collider (y = 18)
	var rail_s = CollisionShape2D.new()
	var rs_rect = RectangleShape2D.new()
	rs_rect.size = Vector2(48, 8)
	rail_s.shape = rs_rect
	rail_s.position = Vector2(0, 18)
	bridge_body.add_child(rail_s)

	parent.add_child(bridge_body)

	# Riverbank blockers north and south of bridge
	var river_body = StaticBody2D.new()
	river_body.name = "RiverBanks"
	river_body.collision_layer = 1
	river_body.collision_mask = 0

	# North-west bank (y: -110 to -16)
	var r_nw = CollisionShape2D.new()
	var rnw_shape = RectangleShape2D.new()
	rnw_shape.size = Vector2(16, 95)
	r_nw.shape = rnw_shape
	r_nw.position = Vector2(196, -65)
	river_body.add_child(r_nw)

	# North-east bank (y: -110 to -16)
	var r_ne = CollisionShape2D.new()
	var rne_shape = RectangleShape2D.new()
	rne_shape.size = Vector2(16, 95)
	r_ne.shape = rne_shape
	r_ne.position = Vector2(236, -65)
	river_body.add_child(r_ne)

	# South-west bank (y: 16 to 140)
	var r_sw = CollisionShape2D.new()
	var rsw_shape = RectangleShape2D.new()
	rsw_shape.size = Vector2(16, 115)
	r_sw.shape = rsw_shape
	r_sw.position = Vector2(196, 75)
	river_body.add_child(r_sw)

	# South-east bank (y: 16 to 140)
	var r_se = CollisionShape2D.new()
	var rse_shape = RectangleShape2D.new()
	rse_shape.size = Vector2(16, 115)
	r_se.shape = rse_shape
	r_se.position = Vector2(236, 75)
	river_body.add_child(r_se)

	parent.add_child(river_body)

	# Riverbank trees and decor
	_spawn_oak_med(parent, Vector2(175, -55))
	_spawn_pine_small(parent, Vector2(250, -50))
	_spawn_fern(parent, Vector2(185, -15))
	_spawn_fern(parent, Vector2(245, -15))
	_spawn_boulder(parent, Vector2(185, 48))
	_spawn_bush(parent, Vector2(248, 46))

# ---------------------------------------------------------------------------
# 4. Dense Woods & Undergrowth (Area D)
# ---------------------------------------------------------------------------
func _build_dense_woods_and_undergrowth(parent: Node2D) -> void:
	# Northwest dense woods
	_spawn_oak_large(parent, Vector2(-125, -110))
	_spawn_oak_large(parent, Vector2(-168, -105))
	_spawn_pine_large(parent, Vector2(-88, -125))
	_spawn_pine_small(parent, Vector2(-140, -85))
	_spawn_log(parent, Vector2(-115, -92))
	_spawn_mushrooms(parent, Vector2(-128, -102))
	_spawn_fern(parent, Vector2(-96, -88))

	# North trail framing (leaving x=0 open)
	_spawn_oak_med(parent, Vector2(-45, -145))
	_spawn_pine_large(parent, Vector2(45, -145))

# ---------------------------------------------------------------------------
# 5. Exploration Landmark: Campsite & Ruins (Area E)
# ---------------------------------------------------------------------------
func _build_exploration_landmark(parent: Node2D) -> void:
	# Located at x: 260..295, y: -45..20 (East of bridge)
	var ruins = StaticBody2D.new()
	ruins.name = "AncientRuinsWall"
	ruins.position = Vector2(285, -35)
	ruins.collision_layer = 1
	ruins.collision_mask = 0

	var sp_r = Sprite2D.new()
	sp_r.name = "Sprite2D"
	sp_r.texture = TEX_RUINS
	sp_r.position = Vector2(0, -12)
	ruins.add_child(sp_r)

	var col_r = CollisionShape2D.new()
	var box_r = RectangleShape2D.new()
	box_r.size = Vector2(40, 12)
	col_r.shape = box_r
	col_r.position = Vector2(0, -4)
	ruins.add_child(col_r)
	parent.add_child(ruins)

	var campfire = StaticBody2D.new()
	campfire.name = "Campfire"
	campfire.position = Vector2(265, -12)
	campfire.collision_layer = 1
	campfire.collision_mask = 0

	var sp_cf = Sprite2D.new()
	sp_cf.name = "Sprite2D"
	sp_cf.texture = TEX_LANDMARKS
	sp_cf.region_enabled = true
	sp_cf.region_rect = Rect2(0, 0, 24, 24)
	sp_cf.position = Vector2(0, -6)
	campfire.add_child(sp_cf)

	var col_cf = CollisionShape2D.new()
	var cir_cf = CircleShape2D.new()
	cir_cf.radius = 8.0
	col_cf.shape = cir_cf
	col_cf.position = Vector2(0, 0)
	campfire.add_child(col_cf)
	parent.add_child(campfire)

	var chest = StaticBody2D.new()
	chest.name = "TreasureChest"
	chest.position = Vector2(286, -12)
	chest.collision_layer = 1
	chest.collision_mask = 0

	var sp_ch = Sprite2D.new()
	sp_ch.name = "Sprite2D"
	sp_ch.texture = TEX_LANDMARKS
	sp_ch.region_enabled = true
	sp_ch.region_rect = Rect2(24, 0, 24, 24)
	sp_ch.position = Vector2(0, -6)
	chest.add_child(sp_ch)

	var col_ch = CollisionShape2D.new()
	var cir_ch = CircleShape2D.new()
	cir_ch.radius = 7.0
	col_ch.shape = cir_ch
	col_ch.position = Vector2(0, 0)
	chest.add_child(col_ch)
	parent.add_child(chest)

	_spawn_pine_large(parent, Vector2(255, -55))
	_spawn_oak_large(parent, Vector2(305, -52))
	_spawn_boulder(parent, Vector2(248, 38))
	_spawn_log(parent, Vector2(275, 32))
	_spawn_bush(parent, Vector2(300, 15))

# ---------------------------------------------------------------------------
# Helper Spawn Functions
# ---------------------------------------------------------------------------
func _spawn_oak_large(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_TREE_LARGE
	sp.position = Vector2(0, -40)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(14.0, 12.0)
	col.shape = shape
	col.position = Vector2(0, -4)
	body.add_child(col)

	parent.add_child(body)

func _spawn_oak_med(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_TREE_MED
	sp.position = Vector2(0, -28)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(10.0, 10.0)
	col.shape = shape
	col.position = Vector2(0, -4)
	body.add_child(col)

	parent.add_child(body)

func _spawn_pine_large(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_PINE_LARGE
	sp.position = Vector2(0, -34)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(10.0, 10.0)
	col.shape = shape
	col.position = Vector2(0, -4)
	body.add_child(col)

	parent.add_child(body)

func _spawn_pine_small(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_PINE_SMALL
	sp.position = Vector2(0, -22)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(8.0, 8.0)
	col.shape = shape
	col.position = Vector2(0, -3)
	body.add_child(col)

	parent.add_child(body)

func _spawn_boulder(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_BOULDER
	sp.position = Vector2(0, -6)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	col.position = Vector2(0, -2)
	body.add_child(col)

	parent.add_child(body)

func _spawn_boulder_large(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_BOULDER_LG
	sp.position = Vector2(0, -8)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	col.position = Vector2(0, -2)
	body.add_child(col)

	parent.add_child(body)

func _spawn_log(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_LOG
	sp.position = Vector2(0, -4)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28.0, 10.0)
	col.shape = shape
	col.position = Vector2(0, 0)
	body.add_child(col)

	parent.add_child(body)

func _spawn_stump(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_STUMP
	sp.position = Vector2(0, -4)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 7.0
	col.shape = shape
	col.position = Vector2(0, 0)
	body.add_child(col)

	parent.add_child(body)

func _spawn_bush(parent: Node2D, pos: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sp = Sprite2D.new()
	sp.texture = TEX_BUSH
	sp.position = Vector2(0, -6)
	body.add_child(sp)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	col.position = Vector2(0, -2)
	body.add_child(col)

	parent.add_child(body)

func _spawn_fern(parent: Node2D, pos: Vector2) -> void:
	var sp = Sprite2D.new()
	sp.texture = TEX_FERN
	sp.position = pos + Vector2(0, -6)
	parent.add_child(sp)

func _spawn_mushrooms(parent: Node2D, pos: Vector2) -> void:
	var sp = Sprite2D.new()
	sp.texture = TEX_MUSHROOMS
	sp.position = pos + Vector2(0, -4)
	parent.add_child(sp)

func _spawn_aquatic(parent: Node2D, pos: Vector2) -> void:
	var sp = Sprite2D.new()
	sp.texture = TEX_AQUATIC
	sp.position = pos + Vector2(0, -6)
	parent.add_child(sp)
