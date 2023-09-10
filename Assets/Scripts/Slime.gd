extends "res://Assets/Scripts/Enemy.gd"

var directionTimer = 3;

func _ready():
	initialize()
	originLimit = 300
	lookWhenHit = true
	var hasEyes = false
	SPEED = 50.0
	JUMP_VELOCITY = -300.0
	aggroRange = 300
	deathLength = 1
	decideDirection()
	attackPattern()

func _physics_process(delta):
	if !usingAttack:
		animate(1.5)
	checkAggro()
	checkDamage()
	move(delta)
	nextFrame.emit()
	
	
	
func decideDirection():
	var time = 0
	if aggro:
		directionTimer = rng.randf_range(0.5,2.0)
		randomizeDirection()
	else:
		directionTimer = rng.randf_range(1.0,4.0)
		randomizeDirection()
		#print(direction)
	while time<directionTimer:
		if aggro:
			pass
		if !is_on_floor():
			await nextFrame
			continue
		if usingAttack:
			await nextFrame
			continue
		time+=General.thisDelta
		await nextFrame
	decideDirection()
	
func attackPattern():
	var time = 0
	var waitTimer = rng.randf_range(1.0,3.0)
	while time<waitTimer:
		if aggro:
			pass
		if usingAttack:
			pass
		time+=General.thisDelta
		await nextFrame
	if aggro and !usingAttack and is_on_floor():
		jumpAttack()
	attackPattern()
	
func jumpAttack():
	usingAttack = true
	SPEED = SPEED/2
	$AnimationPlayer.play("prejump")
	var timer = 0
	var randomWait = rng.randf_range(0.5,2.0)
	while timer < randomWait and is_on_floor() and usingAttack:
		$Sprite.visible = true
		$Sprite.modulate = Color(1,1,1,1)
		timer+=General.thisDelta
		await nextFrame
	timer = 0
	invul = true
	while timer < .4 and is_on_floor() and usingAttack:
		if Time.get_ticks_msec()%10<5:
			$Sprite.visible = false
		else:
			$Sprite.visible = true
			$Sprite.modulate = Color(0,1,1,1)
		timer+=General.thisDelta
		await nextFrame
	$AnimationPlayer.play("jump")
	velocity.y = JUMP_VELOCITY
	SPEED = SPEED*2
	usingAttack = false
	timer = 0
	while timer < .4 and usingAttack:
		if Time.get_ticks_msec()%10<5:
			$Sprite.visible = false
		else:
			$Sprite.visible = true
			$Sprite.modulate = Color(0,1,1,1)
		timer+=General.thisDelta
		await nextFrame
	$Sprite.visible = true
	$Sprite.modulate = Color(1,1,1,1)
	invul = false
	usingAttack = false
