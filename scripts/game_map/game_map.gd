class_name GameMap extends Control
## Displays a map given a [Game]

static var game : Game = null
static func get_game() -> Game:
	return game
static func _static_init() -> void:
	game = GameFactory.create_from_game_name("fusion")
	game.all()

signal map_drawn(dock_connections : Dictionary[NodeMarker, NodeMarker])
signal map_resolved(reached_nodes : Array[NodeData])

@export var ui : Control
@export var inventory_interface : UITab
@export var trick_interface : UITab
@export var randovania_interface : UITab
@export var logic_interface : UITab
@export var camera : Camera2D

var rdv_logic : Dictionary[StringName, Dictionary] = {}
var region_nodes : Dictionary[StringName, Control]
var world_data : Dictionary[StringName, Dictionary] = {}
var node_marker_map : Dictionary [NodeData, NodeMarker] = {}
var room_map : Dictionary[RoomData, Room] = {}
var start_node : NodeData = null

func _ready() -> void:
	inventory_interface.items_changed.connect(resolve_map)
	trick_interface.tricks_changed.connect(resolve_map)
	
	randovania_interface.settings_changed.connect(resolve_map)
	randovania_interface.rdvgame_loaded.connect(rdvgame_loaded)
	randovania_interface.rdvgame_cleared.connect(rdvgame_cleared)
	
	load_rdv_logic()
	init_map()
	init_nodes()

func load_rdv_logic() -> void:
	rdv_logic = game.get_region_data()

## Create region [Control] nodes and draw rooms
func init_map() -> void:
	for r in rdv_logic:
		var region := Control.new()
		region_nodes[r] = region
		#region.set_scale(Vector2(1, -1)) # Flip vertically
		region.set_name(r)
		add_child(region)
		region.set_position( game.get_region_offset(r) )
		
		if game.has_subregions(r):
			var offsets : Array[Vector2] = game.get_subregion_offsets(r)
			add_subregions(region, offsets.size(), offsets)
		
		world_data[r] = {}
		
		for j in rdv_logic[r]["areas"]:
			var room_data := RoomData.new()
			room_data.init(game, r, j, rdv_logic[r]["areas"][j])
			world_data[r][j] = room_data
			
			var room := draw_room(room_data)
			room_map[room_data] = room
			add_room_to_map(room)

func add_subregions(to_parent : Control, amount : int, offsets : Array[Vector2]) -> void:
	assert(offsets.size() == amount)
	
	for i in range(amount):
		var sub_region := Control.new()
		sub_region.name = "Level %d" % i
		to_parent.add_child(sub_region)
		sub_region.set_position(offsets[i])

func draw_room(room_data : RoomData) -> Room:
	const BASE_ROOM : PackedScene = preload("res://resources/base_room.tscn")
	
	var room := BASE_ROOM.instantiate()
	room.data = room_data
	room.double_clicked.connect(set_start_node)
	room.double_clicked.connect(camera.center_on_room.bind(room))
	room.started_hover.connect(ui.room_hover)
	room.stopped_hover.connect(ui.room_stop_hover)
	
	return room

func add_room_to_map(room : Room) -> void:
	var data := room.data
	var region_node := region_nodes[data.region]
	
	if not game.has_subregions(data.region):
		region_node.add_child(room)
		return
	
	# Add room as child of subregion node
	region_node.get_child( game.get_room_subregion_index(data.region, data.name) ).add_child(room)

func init_nodes() -> void:
	# Clear existing node markers and node data
	for key in node_marker_map:
		node_marker_map[key].queue_free()
	node_marker_map.clear()
	
	var rdvgame := RandovaniaInterface.get_rdvgame()
	var dock_weaknesses : Dictionary = {} if not rdvgame else rdvgame.get_dock_weaknesses()
	
	# Create new node data and add to respective room data
	for r in rdv_logic:
		for j in rdv_logic[r]["areas"]:
			var room_data : RoomData = world_data[r][j]
			room_data.clear_nodes()
			
			var default_node_name : String = ""#rdv_logic[r]["areas"][j]["default_node"]
			var nodes : Array[NodeData] = []
			for k in rdv_logic[r]["areas"][j]["nodes"]:
				if k == "Pickup (Items Every Room)":
					continue
				
				var node_data := NodeData.create_data_from_type(rdv_logic[r]["areas"][j]["nodes"][k]["node_type"])
				nodes.append(node_data)
				node_data.init(game, k, room_data, rdv_logic[r]["areas"][j]["nodes"][k])
				
				var node_marker := draw_node_marker(node_data)
				node_marker_map[node_data] = node_marker
				add_marker_to_map(node_marker)
				
				if node_data is EventNodeData:
					node_data.event_id = rdv_logic[r]["areas"][j]["nodes"][k]["event_name"]
				
				if rdvgame:
					var format_string : String = "%s/%s/%s" % [node_data.region, j, k]
					if format_string in dock_weaknesses:
						node_data.default_dock_weakness = dock_weaknesses[format_string]["name"]
				
				if k == default_node_name:
					room_data.default_node = node_data
			room_data.nodes = nodes
	
	# Fill out node data connections
	for r in rdv_logic:
		for j in rdv_logic[r]["areas"]:
			for k in rdv_logic[r]["areas"][j]["nodes"]:
				var node_data := get_node_data(r, j, k)
				if not node_data:
					continue
				
				var connections : Array[NodeData] = []
				for l in rdv_logic[r]["areas"][j]["nodes"][k]["connections"]:
					var new_connection := get_node_data(r, j, l)
					connections.append(new_connection)
				node_data.connections.assign(connections)
				
				var default_connection_data = rdv_logic[r]["areas"][j]["nodes"][k].get("default_connection", null)
				if default_connection_data and game.has_region(default_connection_data.region):
					node_data.default_connection = get_node_data(
						default_connection_data.region,
						default_connection_data.area,
						default_connection_data.node
					)
				
				add_node_connections.call_deferred(node_marker_map[node_data])
	
	map_drawn.emit( get_elevators(rdvgame) )

func get_node_data(region : StringName, room_name : String, node_name : String) -> NodeData:
	var room_data := get_room_data(region, room_name)
	for i in room_data.nodes:
		if i.name == node_name:
			return i
	
	return null

func get_room_data(region : StringName, room_name : String) -> RoomData:
	return world_data[region][room_name]

func draw_node_marker(node_data : NodeData) -> NodeMarker:
	const BASE_NODE_MARKER : PackedScene = preload("res://resources/node_marker.tscn")
	
	var node_marker := BASE_NODE_MARKER.instantiate()
	
	if node_data is PickupNodeData:
		if node_data.is_artifact():
			node_marker.set_script(load("res://scripts/node marker/artifact_node_marker.gd"))
		else:
			node_marker.set_script(load("res://scripts/node marker/pickup_node_marker.gd"))
	elif node_data is DockNodeData and node_data.is_door():
		node_marker.set_script(load("res://scripts/node marker/door_node_marker.gd"))
	
	node_marker.data = node_data
	node_marker.started_hover.connect(ui.node_hover)
	node_marker.stopped_hover.connect(ui.node_stop_hover)
	node_marker.node_clicked.connect(logic_interface.update_data)
	
	return node_marker

func add_marker_to_map(node_marker : NodeMarker) -> void:
	var data := node_marker.data
	var room := get_room_obj(data.region, data.room_name)
	room.add_child(node_marker)
	
	var pos : Vector2 = region_nodes[data.region].global_position
	pos += Vector2(data.coordinates.x, -data.coordinates.y)
	
	if game.has_subregions(data.region):
		var subregion : int = game.get_room_subregion_index(data.region, data.name)
		pos += game.get_subregion_offsets(data.region)[subregion] * Vector2(1, -1) # Regions are vertically flipped, flip again so math is right
	
	node_marker.global_position = pos

func get_room_obj(region : StringName, room_name : String) -> Room:
	var data : RoomData = get_room_data(region, room_name)
	return room_map[data]

func get_elevators(rdvgame : RDVGame) -> Dictionary[NodeMarker, NodeMarker]:
	var elevators : Dictionary[NodeMarker, NodeMarker] = {}
	
	# If there's an RDVGame, get elevator connections from it instead
	if rdvgame:
		var dock_connections := rdvgame.get_dock_connections()
		for key in dock_connections:
			var from_split : PackedStringArray = key.split("/")
			var to_split : PackedStringArray = dock_connections[key].split("/")
			if not game.has_region(from_split[0]) or not game.has_region(to_split[0]):
				continue
				
			var from_node := get_node_data(from_split[0], from_split[1], from_split[2])
			var to_node := get_node_data(to_split[0], to_split[1], to_split[2])
			
			# ALERT - This is probably a bad place to put this
			# Node data changes should be contained in init_nodes()
			from_node.default_connection = to_node
			to_node.default_connection = from_node
			
			var from_marker := node_marker_map[from_node]
			var to_marker := node_marker_map[to_node]
			elevators[from_marker] = to_marker
		
		return elevators
	
	for data in node_marker_map:
		if (
			data is DockNodeData and 
			data.is_teleporter() and
			data.default_connection
			):
			var from_marker := node_marker_map[data]
			var to_marker := node_marker_map[data.default_connection]
			
			if from_marker in elevators or to_marker in elevators:
				continue
			elevators[from_marker] = to_marker
	
	return elevators

func add_node_connections(marker : NodeMarker) -> void:
	var room := get_room_obj(marker.data.region, marker.data.room_name)
	for c in marker.data.connections:
		var to_marker := node_marker_map[c] as NodeMarker
		var node_connection := NodeConnection.new(
			marker,
			to_marker,
			rdv_logic[marker.data.region]["areas"][marker.data.room_name]["nodes"][marker.data.name]["connections"][c.name]
			)
		room.add_child(node_connection)
		marker.node_connections.append(node_connection)

func resolve_map() -> void:
	print("---Resolving map---")
	#print_stack()
	
	if not start_node:
		start_node = get_node_data("Main Deck", "Docking Bay Hangar", "Ship")
	
	set_all_unreachable()
	
	game.clear_events()
	
	var queue : Array[NodeData] = []
	var reached_nodes : Array[NodeData] = []
	var unreached_nodes := {}
	
	# Region name : Rooms
	var visited_rooms : Dictionary[StringName, Array] = {}
	for r in rdv_logic:
		visited_rooms[r] = []
	
	queue.append(start_node)
	reached_nodes.append(start_node)
	
	while len(queue) > 0:
		var node : NodeData = queue.pop_front()
		
		if not node.room_name in visited_rooms[node.region]:
			visited_rooms[node.region].append(node.room_name)
		
		var default_connection : NodeData = null if not node is DockNodeData else node.default_connection
		if (
			is_instance_valid(default_connection) and
			not default_connection in reached_nodes and
			can_reach_external(node, default_connection)
		):
			reached_nodes.append(default_connection)
			queue.append(default_connection)
		
		for n in node.connections:
			if n in reached_nodes:
				continue
			
			if can_reach_internal(node, n):
				reached_nodes.append(n)
				
				if n is EventNodeData:
					game.set_event(n.event_id, true)
					
					if unreached_nodes.has(n.event_id):
						queue.append_array(unreached_nodes[n.event_id])
						unreached_nodes.erase(n.event_id)
				
				queue.append(n)
				continue
			
			# Failed to reached
			if not game.last_failed_event_id.is_empty():
				if not unreached_nodes.has(game.last_failed_event_id):
					unreached_nodes[game.last_failed_event_id] = []
				unreached_nodes[game.last_failed_event_id].append(node)
	
	for r in visited_rooms:
		for n in visited_rooms[r]:
			var room_obj := get_room_obj(r, n)
			room_obj.set_state(game, Room.State.DEFAULT)
	
	for key in node_marker_map:
		var reached : bool = key in reached_nodes
		var marker : NodeMarker = node_marker_map[key]
		if marker is PickupNodeMarker or marker is ArtifactNodeMarker:
			marker.set_reachable(reached)
		marker.set_state(NodeMarker.State.DEFAULT if reached else NodeMarker.State.UNREACHABLE)
		for c in marker.node_connections:
			match c._to_marker.state:
				NodeMarker.State.DEFAULT:
					c.modulate = Color.GREEN
				NodeMarker.State.UNREACHABLE:
					c.modulate = Color.RED
	
	var starter_room := get_room_obj(start_node.region, start_node.room_name)
	starter_room.set_state(game, Room.State.STARTER)
	
	map_resolved.emit(reached_nodes)

func set_all_unreachable() -> void:
	for key in room_map:
		room_map[key].set_state(game, Room.State.UNREACHABLE)
		for node in room_map[key].node_markers:
			node.self_modulate = Room.UNREACHABLE_COLOR

func can_reach_external(from_node : DockNodeData, to_node : DockNodeData) -> bool:
	return (
		game.can_pass_dock(from_node.type, from_node.default_dock_weakness) and 
		game.can_pass_lock(from_node.type, from_node.default_dock_weakness)
		) and (
			game.can_pass_dock(from_node.type, from_node.default_dock_weakness) and 
			game.can_pass_lock(to_node.type, to_node.default_dock_weakness)
			)

func can_reach_internal(from_node : NodeData, to_node : NodeData) -> bool:
	#print("Checking %s (%s) to %s (%s)" % [from_node.display_name, from_node.room_name, to_node.display_name, to_node.room_name])
	game.last_failed_event_id = ""
	var logic : Dictionary = rdv_logic[from_node.region]["areas"][from_node.room_name]["nodes"][from_node.name]["connections"][to_node.name]
	return game.can_reach(logic)

func rdvgame_loaded() -> void:
	init_nodes()
	
	var rdvgame := RandovaniaInterface.get_rdvgame()
	set_start_node(get_node_data(
		rdvgame.get_start_region_name(),
		rdvgame.get_start_room_name(), 
		rdvgame.get_start_node_name()
		))

func set_start_node(new_node : NodeData) -> void:
	start_node = new_node
	camera.center_on_room(start_node, get_room_obj(start_node.region, start_node.room_name))
	resolve_map()

func rdvgame_cleared() -> void:
	start_node = null
	
	game.all()
	
	init_nodes()
	resolve_map()
	
	camera.center_on_room(start_node, get_room_obj(start_node.region, start_node.room_name))
