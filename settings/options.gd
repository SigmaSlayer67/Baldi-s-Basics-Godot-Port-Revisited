extends CanvasLayer

signal closed

func _ready():
	Global.load_settings()
	$Options/Menu/Sensativity.value = Global.sensativity
	$Options/Menu/Rumble.button_pressed = Global.analog
	$Options/Menu/Analog.button_pressed = Global.rumble


func _on_controls_pressed():
	$Options/Controls.show()

func _on_controls_back_pressed():
	$Options/Controls.hide()

func _on_back_pressed():
	hide()
	emit_signal("closed")

func _on_sensativity_value_changed(value):
	Global.sensativity = max(0.1,value)
	$Options/Menu/Sensativity/SensBar.value = value

func _input(event):
	# close on pause pressed
	if event.is_action_pressed("gm_pause") && visible && get_tree().paused:
		_on_back_pressed()

func _on_rumble_toggled(toggled_on):
	Global.rumble = toggled_on

func _on_analog_toggled(toggled_on):
	Global.analog = toggled_on


func _on_to_menu_pressed():
	_on_back_pressed()
	# Reset values when quitting game instead of when exiting options
	Global.save_settings()
	Global.reset_values()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

# determine if to show the menu button if not in the menu scene (do a name check, if you change the main menu node name then you'll have to change this too)
func _on_visibility_changed():
	$Options/ToMenu.visible = get_tree().current_scene.name != "Menu"
