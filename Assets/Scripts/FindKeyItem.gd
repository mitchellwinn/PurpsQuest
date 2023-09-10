extends Area2D

signal nextFrame

@export var itemIndex: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	nextFrame.emit()




func _on_body_entered(body):
	if body.name == "Player":
		#print("OKAY")
		General.cutsceneActive = true
		var timer = 0
		body.animate(General.thisDelta)
		while timer < 1:
			$Sprite2D.position.y-=(1-timer)*.75
			timer+=General.thisDelta
			await nextFrame
		General.ui.get_node("AnimationPlayer").play("Receive")
		await nextFrame
		Keys.items[itemIndex]=1
		$Sprite2D.visible = false
		await get_tree().create_timer(3.5).timeout
		General.animatorOn = false
		body.get_node("AnimationPlayer").play("findItem"+str(itemIndex))
		await get_tree().create_timer(1.0).timeout
		General.cutsceneActive = false
		General.animatorOn = true
		queue_free()
