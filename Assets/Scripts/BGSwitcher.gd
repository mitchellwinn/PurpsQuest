extends Area2D


@export var vertical: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_exited(body):
	if body.name=="Player":
		if vertical:
			if body.global_position.y>global_position.y:
				General.activeBG = General.bg2
			else:
				General.activeBG = General.bg1
		else:
			if body.global_position.x>global_position.x:
				General.activeBG = General.bg1
			else:
				General.activeBG = General.bg2
		General.updateBackgrounds()

