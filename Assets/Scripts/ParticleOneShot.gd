extends GPUParticles2D


var timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	emitting = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer>2:
		queue_free()
