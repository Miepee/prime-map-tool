class_name GameFactory extends RefCounted
## Creates Game objects

static func create_from_game_name(name : String):
	var path : StringName = &"res://data/games/%s/header.json" % name
	assert( ResourceLoader.exists(path, "JSON") )
	var rdv_header : Dictionary = load(path).data
	
	match name:
		"prime1":
			return Prime.new(rdv_header)
		"fusion":
			return Game.new(rdv_header)
		_:
			push_error("Failed to create game: %s" % name)
	
	return null
