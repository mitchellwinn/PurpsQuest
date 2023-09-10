extends Area2D

signal nextFrame

var target
var returnTo = false
@onready var parent = get_parent()
var cost = 3

func _physics_process(delta):
	if !General.itemResolved:
		$Sprite2D.rotate(delta*40)
	nextFrame.emit()

# Called when the node enters the scene tree for the first time.
func go():
	$CollisionShape2D.disabled = false
	parent = General.player
	reparent(get_node("/root/World"))
	global_position = parent.global_position
	General.itemResolved = false
	$Sprite2D.self_modulate = Color(1,1,1,1)
	returnTo = false
	target = parent.facingVector*150+global_position
	var timer = 0
	var origin = global_position
	while timer<3 and !General.itemResolved:
		if (global_position - parent.global_position).length()>20:
			$Sprite2D/Afterimage.emitting = true
		#reparent(parent)
		global_position.x = move_toward(global_position.x, origin.x+(target.x-origin.x)*(timer/3), General.thisDelta*300)
		global_position.y = move_toward(global_position.y,-sin((timer/3)*3.14)*90+origin.y, General.thisDelta*500)
		timer+=General.thisDelta*5
		await nextFrame
		reparent(get_node("/root/World"))
	while !General.itemResolved:
		if (global_position - parent.global_position).length()>20:
			$Sprite2D/Afterimage.emitting = true
		#reparent(parent)
		global_position.y = move_toward(global_position.y, (timer-3)*500+origin.y, General.thisDelta*500)
		timer+=General.thisDelta
		if timer>5:
			General.itemResolved = true
		await nextFrame
		reparent(get_node("/root/World"))
	position = Vector2.ZERO
	$Sprite2D/Afterimage.emitting = false
	$Sprite2D.self_modulate = Color(0,0,0,0)
	General.itemResolved = true
	global_position = parent.global_position
	reparent(parent)
	position = Vector2(0,0)
	$CollisionShape2D.disabled = true


func _on_body_entered(body):
	if body.name=="TileMap":
		print("hit")
		General.itemResolved = true
