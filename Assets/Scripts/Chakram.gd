extends Area2D

signal nextFrame

var target
var returnTo = false
@onready var parent = get_parent()
var cost = 5


# Called when the node enters the scene tree for the first time.
func go():
	$CollisionShape2D.disabled = false
	parent = get_parent()
	reparent(get_node("/root/World"))
	global_position = parent.global_position
	print("test")
	General.itemResolved = false
	$Sprite2D.self_modulate = Color(1,1,1,1)
	returnTo = false
	target = parent.facingVector*150+parent.global_position
	while (global_position - target).length()>10 and !returnTo:
		if (global_position - parent.global_position).length()>20:
			$Sprite2D/Afterimage.emitting = true
		reparent(parent)
		global_position = lerp(global_position, target, General.thisDelta*10)
		await nextFrame
		reparent(get_node("/root/World"))
	returnTo = true
	var timer=0
	while (global_position - parent.global_position).length()>20:
		timer+=General.thisDelta
		reparent(parent)
		global_position = lerp(global_position, parent.global_position, General.thisDelta*(6+timer*5))
		await nextFrame
		reparent(get_node("/root/World"))
	$Sprite2D/Afterimage.emitting = false
	$Sprite2D.self_modulate = Color(0,0,0,0)
	General.itemResolved = true
	global_position = parent.global_position
	reparent(parent)
	position = Vector2(0,0)
	$CollisionShape2D.disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	nextFrame.emit()


func _on_body_entered(body):
	if body.name=="TileMap":
		returnTo = true
