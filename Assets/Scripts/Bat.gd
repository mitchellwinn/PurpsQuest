extends "res://Assets/Scripts/Enemy.gd"

var directionTimer = 3;
var variation = 1.0

func _ready():
	initialize()
	variation = RandomNumberGenerator.new().randf_range(1,3)
	originLimit = 300
	lookWhenHit = true
	var hasEyes = false
	SPEED = 80.0
	JUMP_VELOCITY = -300.0
	aggroRange = 150
	deathLength = 1
	var variation
	direction = Vector2.ZERO

func _physics_process(delta):
	if aggro and $AnimationPlayer.current_animation != "fly":
		$AnimationPlayer.play("fly")
	checkAggro()
	checkDamage()
	if stun>0:
		if Time.get_ticks_msec()%10<5:
			$Sprite.visible = false
		else:
			$Sprite.visible = true
			$Sprite.modulate = Color(1,0,0,1)
	else:
		$Sprite.visible = true
		$Sprite.modulate = Color(1,1,1,1)
	move(delta)
	nextFrame.emit()
	
func move(delta):
	var wantedDirection = -(Vector2(global_position.x,0.0) -  Vector2(origin.x,0.0)).normalized()
	if aggro:
		if aggro.stun==0:
			wantedDirection = (aggro.global_position-global_position).normalized()
	direction = lerp(direction,wantedDirection,variation*delta*10)
	
	if dead:
		return
	
	if stun>0:
		stun-=delta
	else:
		stun = 0
	if suspension>0:
		suspension-=delta
	else:
		suspension = 0
	

	if stun>0 or suspension > 0:
		velocity.x = move_toward(velocity.x, 0, 2)
	elif aggro:
		velocity = direction * SPEED
	elif (origin-global_position).length()>2:
		
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
		global_position = origin
		$AnimationPlayer.play("hang")
	move_and_slide()
	

	


