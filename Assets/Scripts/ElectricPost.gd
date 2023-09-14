extends Sprite2D

@export var target: CharacterBody2D
var charged = 30

signal nextFrame
 
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if charged<30:
		visible = true
		charged+=delta
		modulate = Color(1,1,1,1)
	else:
		$Lightning.visible=false
		if Time.get_ticks_msec()%20<10:
			visible = false
		else:
			visible = true
			modulate = Color(1,.3,.6,1)
		$Energy.visible=true
	
	nextFrame.emit()


func _on_area_2d_area_entered(area):
	if charged>=30:
		$Lightning.visible=true
		$Energy.visible = false
		charged = 0
		General.screenImpact(.2)
		area.get_parent().get_node("SFXslash").play()
		
		while charged<10 and get_node("/root/World/Map/Slimecore"):
			get_node("/root/World/Map/Slimecore/Shock").play()
			get_node("/root/World/Map/Slimecore").global_position = get_node("/root/World/Map/Slimecore").origin
			get_node("/root/World/Map/Slimecore").stun = .25
			get_node("/root/World/Map/Slimecore").suspension = 1
			get_node("/root/World/Map/Slimecore/AnimationPlayer").play("jump")
			await get_tree().create_timer(.25).timeout
			if !get_node("/root/World/Map/Slimecore"):
				$Lightning.visible=false
				return
			get_node("/root/World/Map/Slimecore/AnimationPlayer").play("stand")
			await get_tree().create_timer(.25).timeout
		$Lightning.visible=false
