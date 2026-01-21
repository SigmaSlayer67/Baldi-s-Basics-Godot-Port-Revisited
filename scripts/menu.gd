extends Control

var loadingStatus : int
var progress : Array[float]

func _ready() -> void:
	Options.closed.connect(_on_options_back_pressed)
	Global.unlock_mouse()

func _on_menu_pressed() -> void:
	$Title.hide()
	$Menu.show()

func _on_back_pressed() -> void:
	$Menu.hide()
	$Title.show()


func _on_how_play_pressed() -> void:
	$Menu.hide()
	$HowToPlay.show()

func _on_how_back_pressed() -> void:
	$Menu.show()
	$HowToPlay.hide()


func _on_options_pressed() -> void:
	$Menu.hide()
	Options.show()

func _on_options_back_pressed() -> void:
	$Menu.show()

func _on_credits_pressed() -> void:
	$Credits.show()
	$Menu.hide()
	

func _on_credits_back_pressed() -> void:
	$Credits.hide()
	$Menu.show()


func _on_play_back_pressed() -> void:
	$PlayMenu.hide()
	$Title.show()


func _on_start_pressed() -> void:
	$PlayMenu.show()
	$Title.hide()


func _on_story_pressed() -> void:
	$PlayMenu.hide()
	$Loading.show()
	Global.endless = false
	load_scene()


func _on_endless_pressed() -> void:
	$PlayMenu.hide()
	$Loading.show()
	Global.endless = true
	load_scene()

func load_scene() -> void:
	var scene_path : String = "res://scenes/school_house.tscn"
	ResourceLoader.load_threaded_request(scene_path)
	while true:
		loadingStatus = ResourceLoader.load_threaded_get_status(scene_path, progress)
		match  loadingStatus:
			ResourceLoader.THREAD_LOAD_LOADED:
				get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_path))
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				printerr("Could not load Resource: "+str(scene_path))
				break
		await get_tree().process_frame
	


func _on_exit_pressed():
	get_tree().quit()
