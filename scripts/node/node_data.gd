class_name NodeData extends Resource

var game : Game = null
var region : StringName
var room_name : StringName
var name : StringName

# Set by [Game]
var type : StringName
var coordinates : Vector2
var color := Color.WHITE
var scale : Vector2
var hover_scale : Vector2
var extra : Dictionary = {}
var texture : Texture2D = null

# Set by [GameMap]
var connections : Array[NodeData]
var default_connection : NodeData

func _init(_game : Game, _room_data : RoomData, _name : String, _data : Dictionary) -> void:
	game = _game
	region = _room_data.region
	room_name = _room_data.name
	name = _name
	
	# AM2R has RoomData dependency
	# Add it to _data before passing to init_node_data
	# Dictionaries are passed by reference, so duplicate it for temporary use
	var tmp_data := _data.duplicate()
	tmp_data.room_data = _room_data
	
	game.init_node_data(self, tmp_data)

#region Accessor Methods
func set_type(_type : StringName) -> void:
	type = _type
func get_type() -> StringName:
	return type

func set_coords(_coords : Vector2) -> void:
	coordinates = _coords
func get_coords() -> Vector2:
	return coordinates

func set_color(_color : Color) -> void:
	color = _color
func get_color() -> Color:
	return color

func set_scale(_scale : Vector2) -> void:
	scale = _scale
func get_scale() -> Vector2:
	return scale

func set_hover_scale(_scale : Vector2) -> void:
	hover_scale = _scale
func get_hover_scale() -> Vector2:
	return hover_scale

func set_texture(_texture : Texture2D) -> void:
	texture = _texture
func get_texture() -> Texture2D:
	return texture
#endregion

#region Docks
func is_dock() -> bool:
	return get_type() == &"dock"

func is_door() -> bool:
	return is_dock() and ( get_dock_type() == &"door" )

func is_teleporter() -> bool:
	return is_dock() and ( 
		get_dock_type() in [&"teleporter", &"Elevator", &"area_transition"] 
	)

func set_dock_type(_type : StringName) -> void:
	extra.dock_type = _type
func get_dock_type() -> StringName:
	return extra.dock_type

func set_dock_weakness(weakness : StringName) -> void:
	extra.dock_weakness = weakness
func get_dock_weakness() -> StringName:
	return extra.dock_weakness

func set_dock_rotation(rotation : Vector3) -> void:
	extra.dock_rotation = rotation
func get_dock_rotation() -> Vector3:
	return extra.dock_rotation
#endregion

#region Pickups
func is_pickup() -> bool:
	return get_type() == &"pickup"

func set_item_name(_name : StringName) -> void:
	extra.item_name = _name
func get_item_name() -> StringName:
	return extra.item_name
#endregion

#region Generics
func is_generic() -> bool:
	return get_type() == &"generic"

func set_heal(_heal : bool) -> void:
	extra.heal = _heal
func get_heal() -> bool:
	return extra.heal

#region Events
func is_event() -> bool:
	return get_type() == &"event"

func set_event_id(id : StringName) -> void:
	extra.event_id = id
func get_event_id() -> StringName:
	return extra.event_id
#endregion
