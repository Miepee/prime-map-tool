class_name PrimeInventoryInterface extends UITab

signal items_changed()

const ON_COLOR := Color("aaffaa")
const OFF_COLOR := Color("ffaaaa")

const ETANK_MAX : int = 14
const ENERGY_PER_TANK : int = 100

const MISSILE_EXPANSION_MAX : int = 49
const MISSILE_VALUE : int = 5

const PB_MAX : int = 8
const PB_EXPANSION_MAX : int = 4
const PB_EXPANSION_VALUE : int = 1
const MAIN_PB_VALUE : int = 4

const ARTIFACT_NAMES : Array[String] = ["Truth", "Strength", "Elder", "Wild", "Lifegiver", "Warrior", "Chozo", "Nature", "Sun", "World", "Spirit", "Newborn"]

@export var randovania_interface : RandovaniaInterface
@export var missile_label : Label
@export var missile_slider : HSlider
@export var pb_label : Label
@export var pb_slider : HSlider
@export var has_launcher_button : Button
@export var has_main_pb_button : Button
@export var etank_label : Label
@export var etank_slider : HSlider
@export var artifact_label : Label
@export var artifact_slider : HSlider
@export var artifact_container : ArtifactContainer
@export var item_buttons : Array[Button]
@export var all_button : Button
@export var none_button : Button

func _ready() -> void:
	super()
	return
	connect_signals()
	init_item_buttons()
	update()

func connect_signals() -> void:
	return
	missile_slider.value_changed.connect(missile_slider_changed)
	missile_slider.drag_ended.connect(dragged_slider.bind(missile_slider, "Missile"))
	pb_slider.value_changed.connect(pb_slider_changed)
	pb_slider.drag_ended.connect(dragged_slider.bind(pb_slider, "PowerBomb"))
	etank_slider.value_changed.connect(etank_slider_changed)
	etank_slider.drag_ended.connect(dragged_slider.bind(etank_slider, "EnergyTank"))
	artifact_slider.value_changed.connect(artifact_slider_changed)
	artifact_slider.drag_ended.connect(dragged_artifact_slider)
	
	has_launcher_button.pressed.connect(has_launcher_toggled)
	has_main_pb_button.pressed.connect(has_main_pb_toggled)
	
	all_button.pressed.connect(all_pressed)
	none_button.pressed.connect(none_pressed)
	
	randovania_interface.rdvgame_loaded.connect(
		func():
			await get_tree().process_frame
			update()
	)

func all_pressed() -> void:
	GameMap.get_game().all()
	update()

func none_pressed() -> void:
	GameMap.get_game().set_items([])
	update()

func init_item_buttons() -> void:
	var game := GameMap.get_game()
	# HACK
	# I don't like relying on node names, but it's what I could come up with at the time
	for btn in item_buttons:
		var item := game.get_item(btn.name)
		change_button_border_color(item, btn)
		item.changed.connect(change_button_border_color.bind(btn))
		btn.pressed.connect(
			func(): 
				item.set_capacity(0 if item.has() else 1)
				items_changed.emit()
		)
		

func update() -> void:
	return
	var game := GameMap.get_game()
	
	update_missle_pb_settings()
	
	# Sliders and Labels
	missile_slider.set_value_no_signal(game.get_item("Missile").get_capacity())
	update_missile_count()
	pb_slider.set_value_no_signal(game.get_item("PowerBomb").get_capacity())
	update_pb_count()
	etank_slider.set_value_no_signal(game.get_item("EnergyTank").get_capacity())
	update_etank_count()
	artifact_slider.set_value_no_signal(get_total_artifact_count())
	update_artifact_info()
	
	items_changed.emit()

func dragged_slider(changed : bool, slider : HSlider, item_name : String) -> void:
	return
	if not changed:
		return
	
	var value := int(slider.get_value())
	GameMap.get_game().get_item(item_name).set_capacity(value)
	items_changed.emit()

func missile_slider_changed(_new_value : float) -> void:
	update_missile_count()

func pb_slider_changed(_new_value : float) -> void:
	update_pb_count()

func update_missile_count() -> void:
	var expansions := int(missile_slider.get_value())
	var launcher : int = GameMap.get_game().get_item("MissileLauncher").get_capacity()
	var total : int = expansions + launcher
	var game_total : int = (expansions * MISSILE_VALUE) + (launcher * MISSILE_VALUE)
	var text := "%d/%d (%d)" % [total, MISSILE_EXPANSION_MAX + 1, game_total]
	missile_label.set_text(text)

func update_pb_count() -> void:
	var expansions := int(pb_slider.get_value())
	var main : int = 1 if GameMap.get_game().get_item("MainPB").has() else 0
	var current : int = expansions + (main * MAIN_PB_VALUE)
	var text := "%d/%d" % [current, PB_MAX]
	pb_label.set_text(text)

func update_missle_pb_settings() -> void:
	var game := GameMap.get_game()
	set_button_color(has_launcher_button, game.get_item("MissileLauncher").has())
	set_button_color(has_main_pb_button, game.get_item("MainPB").has())

func set_button_color(button : Button, enabled : bool) -> void:
	button.self_modulate = ON_COLOR if enabled else OFF_COLOR

func has_launcher_toggled() -> void:
	var item := GameMap.get_game().get_item("MissileLauncher")
	item.set_capacity(0 if item.has() else 1)
	set_button_color(has_launcher_button, item.has())
	update_missile_count()
	items_changed.emit()

func has_main_pb_toggled() -> void:
	var item := GameMap.get_game().get_item("MainPB")
	item.set_capacity(0 if item.has() else 1)
	set_button_color(has_main_pb_button, item.has())
	update_pb_count()
	items_changed.emit()

func etank_slider_changed(_new_value : float) -> void:
	update_etank_count()

func update_etank_count() -> void:
	var value := int(etank_slider.get_value())
	etank_label.set_text("%d/%d" % [value, ETANK_MAX])

func artifact_slider_changed(_new_value : float) -> void:
	update_artifact_info()

func dragged_artifact_slider(changed : bool) -> void:
	if not changed:
		return
	
	var game := GameMap.get_game()
	var value := int(artifact_slider.get_value())
	for i in range(ArtifactContainer.Artifact.MAX):
		var item := game.get_item(ARTIFACT_NAMES[i])
		item.set_capacity_no_signal(i < value)
	
	items_changed.emit()

func get_total_artifact_count() -> int:
	var game := GameMap.get_game()
	var total : int = 0
	for n in ARTIFACT_NAMES:
		total += game.get_item(n).get_capacity()
	return total

func update_artifact_info() -> void:
	var value := int(artifact_slider.get_value())
	for i in range(ArtifactContainer.Artifact.MAX):
		artifact_container.set_artifact_color(i, ArtifactContainer.ORANGE if i < value else ArtifactContainer.BLUE)
	artifact_label.set_text("%d/%d" % [value, ArtifactContainer.Artifact.MAX])

func change_button_border_color(item : Game.Item, button : Button) -> void:
	var normal := button.get_theme_stylebox("normal").duplicate()
	var hover := button.get_theme_stylebox("hover").duplicate()
	var hover_pressed := button.get_theme_stylebox("hover_pressed").duplicate()
	var pressed := button.get_theme_stylebox("pressed").duplicate()
	
	var on : bool = item.has()
	var color := ON_COLOR if on else OFF_COLOR
	normal.border_color = color
	hover.border_color = color
	hover_pressed.border_color = color
	pressed.border_color = color
	
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("hover", hover_pressed)
	button.add_theme_stylebox_override("pressed", pressed)
