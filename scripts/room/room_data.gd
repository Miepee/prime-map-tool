class_name RoomData extends Resource

@export var region : StringName
@export var name : String
@export var texture : Texture2D
@export var json : Dictionary
@export var aabb : Array[float]

@export var nodes : Array[NodeData]
@export var default_node : NodeData

func init(_game : Game, _region : StringName, _name : String, _data : Dictionary) -> void:
	region = _region
	name = _name
	json = _data
	texture = get_room_texture()
	
	if _game is Prime:
		aabb = [
			_data.extra.aabb[0],
			_data.extra.aabb[1],
			_data.extra.aabb[2],
			_data.extra.aabb[3],
			_data.extra.aabb[4],
			_data.extra.aabb[5]
			]

func get_room_texture() -> Texture2D:
	return load("res://data/games/fusion/room_images/%s.png" % [json["extra"]["map_name"]])

func clear_nodes() -> void:
	nodes.clear()
	default_node = null
