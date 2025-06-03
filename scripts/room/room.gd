class_name Room extends TextureButton

signal started_hover
signal stopped_hover
signal clicked
signal double_clicked(node_data : NodeData)

enum State {
	DEFAULT,
	HOVERED,
	UNREACHABLE,
	STARTER,
}

const OUTLINE_SHADER := preload("res://resources/highlight_shader.tres")
const OUTLINE_THICKNESS := 2
const COLOR_CHANGE_DURATION : float = 0.2
const HOVER_COLOR := Color.WHITE
const UNREACHABLE_COLOR := Color("#4b7ea3") # Map Blue from Game
const UNREACHABLE_OUTLINE_COLOR := Color("#62a5d4")

var region : StringName
var data : RoomData = null
var state := State.DEFAULT
var prev_state := State.DEFAULT ## Used to return to after hovering
var _is_hovered : bool = false:
	set(value):
		if value == _is_hovered:
			return
		
		_is_hovered = value
		if _is_hovered:
			started_hover.emit(self)
			return
		stopped_hover.emit(self)
var room_color_tween : Tween = null
var outline_tween : Tween = null
var node_markers : Array[NodeMarker] = []

func _gui_input(event: InputEvent) -> void:
	if _is_hovered and event.is_action("press") and event.is_pressed():
		if not event.double_click:
			room_clicked()
		else:
			double_clicked.emit(data.default_node)

func _ready() -> void:
	var game := GameMap.get_game()
	mouse_entered.connect(
		func():
			set_state(game, State.HOVERED)
			_is_hovered = true
	)
	mouse_exited.connect(
		func():
			set_state(game, prev_state)
			_is_hovered = false
	)
	
	if data:
		init_room()

func init_room():
	var game := GameMap.get_game()
	
	set_name(data.name) # Set name in SceneTree
	set_texture_normal(data.texture)
	set_z_index( 0 if not game else game.get_room_z_index(data.name) )
	region = data.region
	
	if game is Prime or true:
		create_bitmap_from_room_image(data.texture.get_image(), false, true)
		
		var all_x = []
		var all_y = []
		for ele in data.json["extra"]["minimap_coordinates"]:
			all_x.append(ele["x"])
			all_y.append(ele["y"])
		all_x.sort()
		all_y.sort()
		
		var x1 : float = 10
		var y1 : float = 10
		var x2 : float = 20
		var y2 : float = 20
		
		if len(all_x) > 0:
			position.x = all_x[0] * 24
			position.y = all_y[0] * 16
		else:
			position.x = 10
			position.y = 10
		
		custom_minimum_size.x = data.texture.get_width() / 10
		custom_minimum_size.y = data.texture.get_height() / 10
		
		material = OUTLINE_SHADER.duplicate()
		material.set_shader_parameter(&"pattern", 1)
		material.set_shader_parameter(&"inside", true)
	
	set_state(game, State.DEFAULT)

func create_bitmap_from_room_image(image : Image, flip_x : bool = false, flip_y : bool = false) -> void:
	if flip_x: image.flip_x()
	if flip_y: image.flip_y()
	
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.1)
	set_click_mask(bitmap)

func set_state(game : Game, new_state : State) -> void:
	prev_state = state
	state = new_state
	
	match state:
		State.DEFAULT:
			if game is Prime:
				var color : Color = game.get_region_color(region)
				change_to_color(color)
				set_outline(color, OUTLINE_THICKNESS)
		State.HOVERED:
			if game is Prime:
				if prev_state == State.STARTER:
					set_outline(Color.GREEN, OUTLINE_THICKNESS + 1)
				else:
					set_outline(Color.WHITE, OUTLINE_THICKNESS + 1)
		State.UNREACHABLE:
			if game is Prime:
				change_to_color(UNREACHABLE_COLOR)
				set_outline(UNREACHABLE_OUTLINE_COLOR, OUTLINE_THICKNESS)
		State.STARTER:
			if game is Prime:
				prev_state = State.STARTER
				change_to_color( game.get_region_color(region) )
				set_outline(Color.GREEN, OUTLINE_THICKNESS * 4)

func change_to_color(new_color : Color, duration := COLOR_CHANGE_DURATION) -> void:
	if room_color_tween and room_color_tween.is_valid():
		room_color_tween.kill()
	
	room_color_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	room_color_tween.tween_property(self, "self_modulate", new_color, duration)

func room_clicked() -> void:
	print_debug(data.name)
	clicked.emit()

func set_outline(color : Color, width : float) -> void:
	const DURATION : float = 0.2
	
	if outline_tween and outline_tween.is_running():
		outline_tween.kill()
	
	outline_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	outline_tween.tween_method(set_outline_color, get_outline_color(), color, DURATION)
	outline_tween.tween_method(set_outline_width, get_outline_width(), width, DURATION)

func set_outline_color(value : Color) -> void:
	material.set_shader_parameter(&"color", value)
func get_outline_color() -> Color:
	return material.get_shader_parameter(&"color")

func set_outline_width(value : float) -> void:
	material.set_shader_parameter(&"width", value)
func get_outline_width() -> float:
	return material.get_shader_parameter(&"width")

func get_global_center() -> Vector2:
	var tmp = size
	tmp.y *= -1
	return global_position + (tmp * 0.5)
