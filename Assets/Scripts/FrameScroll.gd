extends Sprite2D

@export var delay: float
# Called when the node enters the scene tree for the first time.
func _ready():
	anim()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func anim():
	while true:
		if frame<hframes-1:
			frame+=1
		else:
			frame = 0
		await get_tree().create_timer(delay).timeout
