extends Sprite2D


var selection = 0
var hasData = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if General.checkData():
		hasData = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if PlayerInputs.tapUp:
		$menusound.play()
		selection -=1
		if !hasData and selection ==1:
			selection -=1
	elif PlayerInputs.tapDown:
		$menusound.play()
		selection +=1
		if !hasData and selection ==1:
			selection +=1
	if selection >2:
		selection = 0
	elif selection<0:
		selection = 2
		
	if PlayerInputs.attack:
		$menusound2.play()
		if selection == 0:
			General.clearData()
			get_tree().change_scene_to_file("res://Assets/Scenes/world.tscn")
			General.getReady()
		if selection == 1:
			get_tree().change_scene_to_file("res://Assets/Scenes/world.tscn")
			General.getReady()
		if selection == 2:
			get_tree().quit()
	
	match selection:
		0:
			$New.modulate = Color(1,1,1,1)
			$Continue.modulate = Color(1,1,1,.4)
			$Quit.modulate = Color(1,1,1,.4)
		1:
			$New.modulate = Color(1,1,1,.4)
			$Continue.modulate = Color(1,1,1,1)
			$Quit.modulate = Color(1,1,1,.4)
		2:
			$New.modulate = Color(1,1,1,.4)
			$Continue.modulate = Color(1,1,1,.4)
			$Quit.modulate = Color(1,1,1,1)	
			
	if !hasData:
		$Continue.modulate = Color(1,1,1,.14)
		
