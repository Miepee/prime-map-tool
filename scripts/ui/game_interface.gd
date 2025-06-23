class_name GameInterface extends UITab

signal game_selected(game_id : StringName)

# NOTE - Game IDs are defined in multiple places now
#        Should reduce this to one source of truth/pull from available headers
const GAMES : Dictionary[StringName, StringName] = {
	&"Metroid Prime" : &"prime1",
	&"AM2R" :          &"am2r",
	&"Metroid Fusion": &"fusion",
}

@export var options : OptionButton

func _ready() -> void:
	super()
	
	# Create game options
	for key in GAMES:
		options.add_item(key)
	options.item_selected.connect(game_option_selected)

func game_option_selected(index : int) -> void:
	game_selected.emit( GAMES.values()[index] )
