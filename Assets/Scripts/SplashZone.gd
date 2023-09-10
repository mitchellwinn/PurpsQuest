extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	var splash = load("res://Assets/FX/splash1.tscn").instantiate()
	splash.global_position = body.global_position+Vector2(0,20)
	get_node("/root/World/Map").add_child(splash)
	if body.collision_layer==2:
		body.waterSlowdown = .5


func _on_body_exited(body):
	var splash = load("res://Assets/FX/splash1.tscn").instantiate()
	splash.global_position = body.global_position+Vector2(0,20)
	get_node("/root/World/Map").add_child(splash)
	if body.collision_layer==2:
		body.waterSlowdown = 1
