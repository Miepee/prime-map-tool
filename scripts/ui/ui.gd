extends Control

@export var region_name_label : Label
@export var room_name_label : Label
@export var node_name_label : Label
@export var bg_color : ColorRect

var hovered_nodes : Array[NodeMarker] = []
var hovered_room : Room = null

func room_hover(room : Room) -> void:
	region_name_label.text = room.data.region
	room_name_label.text = room.name + " - DEBUG (" + str(room.position.x) + "," + str(room.position.y) + ")"
	
	hovered_room = room

func room_stop_hover(_room : Room) -> void:
	hovered_room = null
	
	if hovered_nodes.is_empty():
		region_name_label.text = ""
		room_name_label.text = ""
	else:
		region_name_label.text = hovered_nodes[-1].data.region
		room_name_label.text = hovered_nodes[-1].data.room_name

func node_hover(marker : NodeMarker) -> void:
	hovered_nodes.append(marker)
	
	set_node_name(marker)
	room_name_label.text = marker.data.room_name
	region_name_label.text = marker.data.region
	bg_color.set_default_cursor_shape(Control.CURSOR_POINTING_HAND)

func node_stop_hover(marker : NodeMarker) -> void:
	hovered_nodes.erase(marker)
	
	if hovered_nodes.is_empty():
		bg_color.set_default_cursor_shape(Control.CURSOR_CROSS)
		node_name_label.text = ""
		if not hovered_room:
			room_name_label.text = ""
			region_name_label.text = ""
		return
	
	set_node_name(hovered_nodes[-1])
	room_name_label.text = hovered_nodes[-1].data.room_name
	region_name_label.text = hovered_nodes[-1].data.region

func set_node_name(marker : NodeMarker) -> void:
	if marker is DoorNodeMarker:
		node_name_label.text = "%s (%s)" % [marker.data.name, marker.data.default_dock_weakness.split(" (", 1)[0]]
	else:
		node_name_label.text = marker.data.name
