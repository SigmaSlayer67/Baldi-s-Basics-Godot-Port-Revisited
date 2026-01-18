extends Control

var loadingStatus : int
var progress : Array[float]

func _ready():
	Options.closed.connect(_on_options_back_pressed)
	Global.unlock_mouse()

func _on_menu_pressed():
	$Title.hide()
	$Menu.show()

func _on_back_pressed():
	$Menu.hide()
	$Title.show()


func _on_how_play_pressed():
	$Menu.hide()
	$HowToPlay.show()

func _on_how_back_pressed():
	$Menu.show()
	$HowToPlay.hide()


func _on_options_pressed():
	$Menu.hide()
	Options.show()

func _on_options_back_pressed():
	$Menu.show()

func _on_credits_pressed():
	$Credits.show()
	$Menu.hide()
	

func _on_credits_back_pressed():
	$Credits.hide()
	$Menu.show()


func _on_play_back_pressed():
	$PlayMenu.hide()
	$Title.show()


func _on_start_pressed():
	$PlayMenu.show()
	$Title.hide()


func _on_story_pressed():
	$PlayMenu.hide()
	$Loading.show()
	Global.endless = false
	load_scene()


func _on_endless_pressed():
	$PlayMenu.hide()
	$Loading.show()
	Global.endless = true
	load_scene()

func load_scene():
	var scene = "res://scenes/school_house.tscn"
	ResourceLoader.load_threaded_request(scene)
	while true:
		loadingStatus = ResourceLoader.load_threaded_get_status(scene, progress)
		match  loadingStatus:
			ResourceLoader.THREAD_LOAD_LOADED:
				get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene))
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				printerr("Error. Could not load Resource: "+str(scene))
				break
		await get_tree().process_frame
	


func _on_exit_pressed():
	get_tree().quit()
