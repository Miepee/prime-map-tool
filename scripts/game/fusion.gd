class_name Fusion extends Game

const ROOM_WIDTH : int = 240
const ROOM_HEIGHT : int = 160
const ROOM_DIVISOR : int = 5

func _init(rdv_header : Dictionary) -> void:
	super(rdv_header)
	
	# Set virtual members
	
	## Map of region names and their offsets in global space
	## Each region is required to have an offset, even if it's Vector2.ZERO
	region_offset = {
		&"Main Deck": Vector2(1500,-500),
		&"Sector 1 (SRX)": Vector2(1200,350),
		&"Sector 2 (TRO)": Vector2(2400,350),
		&"Sector 3 (PYR)": Vector2(100,350),
		&"Sector 4 (AQA)": Vector2(2000,1200),
		&"Sector 5 (ARC)": Vector2(600,1200),
		&"Sector 6 (NOC)": Vector2(1400,1800),
	} 
	
	## Map of region names that contain subregions and their offsets in local coordinates
	## Inner array expected type is Array[Vector2]
	subregion_offset = {}
	
	## Map of region names and room subregion indices
	## Inner dictionary expected type is Dictionary[StringName, int]
	## Defines what rooms are in a subregion
	subregion_map = {}
	
	## Map of room names and their z-indices
	## Use this if rooms need to be manually adjusted
	# TODO: s2, 4, 6
	z_index_override = {
		&"Docking Bay Hangar": 1,
		&"Station Entrance": 2,
		&"Central Nexus": 3,
		&"Elevator to Habitation Deck": -1,		
		&"Nexus Storage": 1,
		&"Nexus Navigation Room": 2,
		&"Sub-Zero Containment": 2,
		
		# East Main Deck
		&"Operations Ventilation Storage": -1,
		&"Operations Room": -1,
		&"Operations Deck Save Room": -1,
		&"Operations Deck Recharge Room": -1,
		&"Crew Quarters Save Room": 2,
		
		# West Main Deck
		&"Main Elevator Cache": -1,
		&"Main Elevator Shaft": -1,
		
		# Reactor Core
		&"Silo Entry": 1,
		&"Silo Tunnel": 2,
		&"Crew Quarters East": 2,
		
		# Sector 1
		&"Glass Tube to Sector 3 (PYR)": -1,
		&"Lava Lake Annex": -1,
		&"Entrance Lobby": 1,
		&"Antechamber": -1,
		&"Yameba Corridor": 1,
		&"Atmospheric Stabilizer Northwest": 2,
		&"Hornoad Hole": 1,
		&"Wall Jump Tutorial": 1,
		&"Charge Core Arena": -1,
		&"Charge Core Upper Access": -1,
		&"Atmospheric Stabilizer Central": -1,
		&"Tourian Save Room East": 1,
		
		# Sector 3
		&"Glass Tube to Sector 5 (ARC)": -1,
		&"Main Boiler": -1,
		&"Red Tower": 1,
		
		# Sector 5
		&"Training Grounds": 1,
		&"Security Save Room": -1,
		&"Arctic Underside": -1,
		&"Cellar": 1,
		&"Frozen Tower": 1,
		&"Mini-Fridge": 1,
		&"Cellar Save Room": 1,
		&"Flooded Access": 1,
		
		
		
	}
	
	## Map of region names and their color
	region_color = {
		&"Main Deck": Color.WHITE,
		&"Sector 1 (SRX)": Color.WHITE,
		&"Sector 2 (TRO)": Color.WHITE,
		&"Sector 3 (PYR)": Color.WHITE,
		&"Sector 4 (AQA)": Color.WHITE,
		&"Sector 5 (ARC)": Color.WHITE,
		&"Sector 6 (NOC)": Color.WHITE,
	}
	
	## 2D Array describing how the inventory is displayed
	## Required to interact with the inventory, but not to display the map
	
	var _all := InventoryInterface.AllButton.new(self)
	var none := InventoryInterface.NoneButton.new(self)
	var charge := InventoryInterface.PickupButton.new(self, &"Charge Beam", &"res://data/games/am2r/item_images/Charge Beam.png")
	var wide := InventoryInterface.PickupButton.new(self, &"Wide Beam", &"res://data/games/am2r/item_images/Spazer Beam.png")
	var plasma := InventoryInterface.PickupButton.new(self, &"Plasma Beam", &"res://data/games/am2r/item_images/Plasma Beam.png")
	var wave := InventoryInterface.PickupButton.new(self, &"Wave Beam", &"res://data/games/am2r/item_images/Wave Beam.png")
	var iceBeam := InventoryInterface.PickupButton.new(self, &"Ice Beam", &"res://data/games/am2r/item_images/Ice Beam.png")
	var mainMissiles := InventoryInterface.PickupButton.new(self, &"Missile Data", &"res://data/games/am2r/item_images/Missile Launcher.png")
	var supers := InventoryInterface.PickupButton.new(self, &"Super Missile Data", &"res://data/games/am2r/item_images/Super Missile Launcher.png")
	var iceMissile := InventoryInterface.PickupButton.new(self, &"Ice Missile Data", &"res://data/games/am2r/item_images/Walljump Boots.png")
	var diffusion := InventoryInterface.PickupButton.new(self, &"Diffusion Missile Data", &"res://data/games/am2r/item_images/Infinite Bomb Propulsion.png")
	var morph := InventoryInterface.PickupButton.new(self, &"Morph Ball", &"res://data/games/am2r/item_images/Morph Ball.png")
	var bomb := InventoryInterface.PickupButton.new(self, &"Morph Ball Bomb Data", &"res://data/games/am2r/item_images/Bombs.png")
	var mainPB := InventoryInterface.PickupButton.new(self, &"Power Bomb Data", &"res://data/games/am2r/item_images/Power Bomb Launcher.png")
	var hj := InventoryInterface.PickupButton.new(self, &"Hi-Jump", &"res://data/games/am2r/item_images/Hi-Jump Boots.png")
	var space := InventoryInterface.PickupButton.new(self, &"Space Jump", &"res://data/games/am2r/item_images/Space Jump.png")
	var speed := InventoryInterface.PickupButton.new(self, &"Speed Booster", &"res://data/games/am2r/item_images/Speed Booster.png")
	var screw := InventoryInterface.PickupButton.new(self, &"Screw Attack", &"res://data/games/am2r/item_images/Screw Attack.png")
	var varia := InventoryInterface.PickupButton.new(self, &"Varia Suit", &"res://data/games/am2r/item_images/Varia Suit.png")
	var grav := InventoryInterface.PickupButton.new(self, &"Gravity Suit", &"res://data/games/am2r/item_images/Gravity Suit.png")
	
	var lv0 := InventoryInterface.PickupButton.new(self, &"Level 0 Keycard", &"res://data/games/am2r/item_images/Arm Cannon.png")
	var lv1 := InventoryInterface.PickupButton.new(self, &"Level 1 Keycard", &"res://data/games/am2r/item_images/Power Grip.png")
	var lv2 := InventoryInterface.PickupButton.new(self, &"Level 2 Keycard", &"res://data/games/am2r/item_images/Spider Ball.png")
	var lv3 := InventoryInterface.PickupButton.new(self, &"Level 3 Keycard", &"res://data/games/am2r/item_images/Spring Ball.png")
	var lv4 := InventoryInterface.PickupButton.new(self, &"Level 4 Keycard", &"res://data/games/am2r/item_images/Unknown.png")
	
	var dna_names : Array[StringName] = [&"Infant Metroid 1", &"Infant Metroid 2", &"Infant Metroid 3", &"Infant Metroid 4", &"Infant Metroid 5", &"Infant Metroid 6", &"Infant Metroid 7", &"Infant Metroid 8", &"Infant Metroid 9", &"Infant Metroid 10", &"Infant Metroid 11", &"Infant Metroid 12", &"Infant Metroid 13", &"Infant Metroid 14", &"Infant Metroid 15", &"Infant Metroid 16", &"Infant Metroid 17", &"Infant Metroid 18", &"Infant Metroid 19", &"Infant Metroid 20"]
	var dnas := InventoryInterface.MultiPickupSlider.new(self, dna_names, &"res://data/games/am2r/item_images/dna.png")
	var etanks := InventoryInterface.PickupSlider.new(self, &"Energy Tank", &"res://data/games/am2r/item_images/Energy Tank.png", 1, 14)
	var missiles := InventoryInterface.PickupSlider.new(self, &"Missiles", &"res://data/games/am2r/item_images/Missile Expansion.png", 5, 50)
	var pbs := InventoryInterface.PickupSlider.new(self, &"Power Bombs", &"res://data/games/am2r/item_images/Power Bomb Tank.png", 2, 30)
	inventory_layout = [
		[_all, none],
		[charge, wide, plasma, wave, iceBeam],
		[mainMissiles, supers, iceMissile, diffusion],
		[hj, speed, space, screw],
		[morph, bomb, mainPB, varia, grav],
		[lv0, lv1, lv2, lv3, lv4],
		[missiles, pbs],
		[etanks, dnas]
	]

## Override with Randovania's game ID
func get_game_id() -> StringName:
	return &"fusion"

## Override if your rooms need to be flipped horizontally or vertically
func get_region_scale() -> Vector2:
	return Vector2(1, 1)

## Collect and store data about rooms
## Room texture MUST be set
@warning_ignore_start("integer_division") # https://github.com/godotengine/godot/issues/42966
func init_room_data(_room_data : RoomData, _extra_data : Dictionary) -> void:
	_room_data.extra.map_name = _extra_data.extra.map_name
	
	var all_x : Array[int] = []
	var all_y : Array[int] = []
	for ele in _extra_data.extra.minimap_coordinates:
		all_x.append( int(ele.x) )
		all_y.append( int(ele.y) )
	all_x.sort()
	all_y.sort()
	
	if len(all_x) > 0:
		_room_data.extra.x_position = all_x[0] * (ROOM_WIDTH / ROOM_DIVISOR)
		_room_data.extra.y_position = all_y[0] * (ROOM_HEIGHT / ROOM_DIVISOR)
	else:
		_room_data.extra.x_position = 10
		_room_data.extra.y_position = 10
	var path := "res://data/games/%s/room_images/%s.png" % [get_game_id(), _room_data.extra.map_name]
	_room_data.texture = get_room_texture(path)
	
	_room_data.extra.image_width = _room_data.texture.get_width() / ROOM_DIVISOR
	_room_data.extra.image_height = _room_data.texture.get_height() / ROOM_DIVISOR

## Set properties on the room itself (position, minimum size, etc)
## Outline material and config MUST be set
func init_room(room : Room) -> void:
	room.position.x = room.data.extra.x_position
	room.position.y = room.data.extra.y_position
	
	room.custom_minimum_size.x = room.data.extra.image_width
	room.custom_minimum_size.y = room.data.extra.image_height
	
	var outline_config := Room.OutlineConfig.new(
		15, # - Outline thickness while hovered
		25  # - Outline thickness for starting room
	)
	room.config = outline_config

## Collect and store data about nodes
## Use setter functions from [NodeData] to maintain consistency
## The order in which properties are set isn't strict, but they are all required
## Certain node types have extra, required fields. They are separated by newline
func init_node_data(_node_data : NodeData, _extra_data : Dictionary) -> void:
	_node_data.set_type(_extra_data.node_type)
	
	var room_data : RoomData = _extra_data.room_data
	
	var x_coord = room_data.extra.x_position + \
	(_extra_data.coordinates.x / ROOM_DIVISOR)
	
	var y_coord = room_data.extra.y_position + \
	room_data.texture.get_height() / ROOM_DIVISOR - \
	_extra_data.coordinates.y / ROOM_DIVISOR
	_node_data.set_coords(Vector2(x_coord, y_coord))
	
	match _node_data.get_type():
		&"dock":
			_node_data.set_scale( Vector2(0.1, 0.1) )
			_node_data.set_hover_scale( Vector2(0.15, 0.15) )
			
			_node_data.set_dock_type(_extra_data.dock_type)
			_node_data.set_dock_weakness(_extra_data.default_dock_weakness)
			
			_node_data.set_color(Color.WHITE)
			
			if _node_data.get_dock_type() in SHARED_NODE_TEXTURES:
				_node_data.set_texture( SHARED_NODE_TEXTURES[_node_data.get_dock_type()] )
			else:
				_node_data.set_texture( preload("res://data/icons/node marker/door.png") )
		
		&"pickup":
			_node_data.set_item_name(_node_data.name)
			
			#_node_data.set_color()
			_node_data.set_scale( Vector2(0.1, 0.1) )
			_node_data.set_hover_scale( Vector2(0.15, 0.15) )
			_node_data.set_texture(preload("res://data/icons/node marker/node_marker.png"))
		
		&"generic":
			_node_data.set_heal(_extra_data.heal)
			_node_data.set_color(Color.WHEAT)
			_node_data.set_scale( Vector2(0.1, 0.1) )
			_node_data.set_hover_scale( Vector2(0.15, 0.15) )
			_node_data.set_texture( SHARED_NODE_TEXTURES[_node_data.type] )
		
		&"event":
			_node_data.set_event_id(_extra_data.event_name)
			_node_data.set_color(Color.LIME_GREEN)
			_node_data.set_scale( Vector2(0.1, 0.1) )
			_node_data.set_hover_scale( Vector2(0.15, 0.15) )
			_node_data.set_texture( SHARED_NODE_TEXTURES[_node_data.type] )
		
		# TODO
		&"hint":
			_node_data.set_color(Color.WHEAT)
			_node_data.set_scale( Vector2(0.1, 0.1) )
			_node_data.set_hover_scale( Vector2(0.15, 0.15) )
			_node_data.set_texture( SHARED_NODE_TEXTURES["generic"] )
		
		# If your game has extra node types, add them here

## Set properties on the NodeMarker itself (offsets, horizontal/vertical flipping, etc)
func init_node_marker(_marker : NodeMarker) -> void:
	match _marker.data.get_type():
		&"dock": pass
		&"pickup": pass
		&"generic": pass
		&"event": pass
