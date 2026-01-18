extends CanvasLayer
@export var warnings:PackedStringArray = [
"[center][wave]Hello![/wave] This is a fanmade recreation of the original [color=green]Baldi's Basics[/color] for [color=0AF]Godot 4.4[/color].
The idea is to create an easier was to create fangames for people that prefer Godot over Unity.
This was created using the fanmade Baldi's Basics Classic and Birthday bash decompiles by Jumpman25 and Porky Powers.

Continue to see the original warnings for the original and decompilations.
(Press to continue)",
"[center]WARNING!
In case you haven't figured it out yet, this game is intended to be a horror game. As such, it has some things that might scare players and is generally pretty spoopy. (Well, at least it's supposed to be...) If you downloaded this thinking it would be great edutainment for your kid or something. don't let them play it!... Unless, of course, they enjoy horror games.

YOU HAVE BEEN WARNED
(Press to continue)",
"[center]Baldi and all characters are property of mystman12. All code, assets, and music are owned by mystman12. We have nothing to do with mystman12, this is a fanmade decompile of the game. We are not responsible for anything made with said decompile, but you may not use this decompile for commercial purposes. This includes ads, ingame-purchases etc. By using this tool or playing any mods created with this tool you agree to the conditions above.

(Press to continue)",
]
var warningID = 0

func _ready():
	update_text()

func update_text():
	$Label.text = warnings[warningID]

func _input(event):
	if "pressed" in event and not (event is InputEventKey and event.echo) and not event is InputEventScreenTouch: # Remove touch because it simulates mouse too
		if event.pressed:
			if warningID < warnings.size()-1:
				warningID += 1
				update_text()
			else:
				get_tree().change_scene_to_file("res://scenes/menu.tscn")
