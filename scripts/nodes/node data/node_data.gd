class_name NodeData extends Resource

@export var region : StringName
@export var room_name : String
@export var data : RoomData
@export var name : String
@export var coordinates : Vector3
@export var connections : Array[NodeData]

static func create_data_from_type(type : String) -> NodeData:
	var data : NodeData = null
	
	match type:
		"dock":
			data = DockNodeData.new()
		"pickup":
			data = PickupNodeData.new()
		"generic":
			data = GenericNodeData.new()
		"event":
			data = EventNodeData.new()
		"hint":
			data = GenericNodeData.new()
		_:
			assert(false, "Unhandled NodeData type: %s" % type)
	
	return data

func init(_game : Game, _name : String, _room_data : RoomData, _data : Dictionary) -> void:
	region = _room_data.region
	room_name = _room_data.name
	data = _room_data
	name = _name
	
	coordinates = Vector3(_data["coordinates"]["x"], _data["coordinates"]["y"], 0)
	if _game is Prime:
		coordinates = Vector3(
			_data.extra.world_position[0],
			_data.extra.world_position[1],
			_data.extra.world_position[2]
		)

func get_color() -> Color:
	return Color.WHITE

func get_texture() -> Texture2D:
	return null

func get_scale() -> Vector2:
	const SCALE := Vector2(0.1, 0.1)
	return SCALE

func get_hover_scale() -> Vector2:
	const HOVER_SCALE := Vector2(0.15, 0.15)
	return HOVER_SCALE
