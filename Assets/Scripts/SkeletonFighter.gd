extends "res://Assets/Scripts/Enemy.gd"

var directionTimer = 3;
@export var warp1: Node2D
@export var warp2: Node2D
@export var warp3: Node2D
@export var warp4: Node2D
var lastWarp = false

func _ready():
	KNOCKBACK_VELOCITY = 150
	initialize()
	defendArea =  Vector2(701,757)
	originLimit = 100
	lookWhenHit = true
	var hasEyes = false
	SPEED = 0
	JUMP_VELOCITY = -350.0
	aggroRange = 200
	deathLength = 2
	#decideDirection()
	attackPattern()
	

func _physics_process(delta):
	if !usingAttack:
		move(delta)
	animate(1.5)
	checkAggro()
	checkDamage()
	if aggro:
		if (aggro.global_position-global_position).x>0:
			direction = Vector2(1,0)
		elif (aggro.global_position-global_position).x<0:
			direction = Vector2(-1,0)
	nextFrame.emit()
	if direction.x<0:
		$HitBox.scale.x = 1
		$BounceBox.scale.x = 1
		$Sprite.flip_h=false
	elif direction.x>0:
		$HitBox.scale.x = -1
		$BounceBox.scale.x = -1
		$Sprite.flip_h=true
	
func decideDirection():
	var time = 0
	if aggro:
		directionTimer = rng.randf_range(0.1,0.5)
		direction = (aggro.global_position-global_position).normalized()
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
		lungeAttack()
	attackPattern()

func checkDamage():
	#print($Area2D.get_overlapping_areas().size())
	if stun==0 and suspension == 0 and $BounceBox.get_overlapping_areas().size()>0 and !invul:
		if General.player.usingAttack or !General.itemResolved:
			General.player.usingAttack = false
			General.itemResolved = true
			if (General.player.global_position-global_position).length()<30:
				General.player.stun = .3
			General.screenImpact(.2)
			$Bounce.play()
			General.player.velocity = 100*(General.player.global_position-global_position).normalized()
	elif suspension>0 and stun<.25 and $HurtBox.get_overlapping_areas().size()>0 and !invul:
		if General.player.usingAttack or !General.itemResolved:
			takeDamage(General.player,General.player.currentAttack)
			return
	elif stun<.25 and $HurtBox.get_overlapping_areas().size()>0 and !invul:
		if General.player.usingAttack or !General.itemResolved:
			takeDamage(General.player,General.player.currentAttack)

func lungeAttack():
	if usingAttack:
		return
	invul = false
	usingAttack = true
	var timer = 0
	var random = 1
	while timer < random:
		usingAttack = true
		timer+=General.thisDelta
		if $AnimationPlayer.current_animation!=("raise"):
			$AnimationPlayer.play("raise")
		await nextFrame
	timer = 0
	invul = true
	while timer < .8 and usingAttack:
		velocity.x = -(aggro.global_position-global_position).normalized().x*(100*(.8-timer))
		velocity.y += gravity * General.thisDelta
		if Time.get_ticks_msec()%10<5:
			$Sprite.visible = false
		else:
			$Sprite.visible = true
			$Sprite.modulate = Color(0,1,1,1)
		timer+=General.thisDelta
		if $AnimationPlayer.current_animation!=("wiggle"):
			$AnimationPlayer.play("wiggle")
		move_and_slide()
		await nextFrame
	$AnimationPlayer.play("lunge")
	velocity.y = 0
	timer = 0
	$Sprite.visible = true
	$Sprite.modulate = Color(1,1,1,1)
	invul = false
	stun = 0
	while timer < .75 and usingAttack:
		velocity.x = (aggro.global_position-global_position).normalized().x*(400*(.75-timer))
		velocity.y += gravity * General.thisDelta
		if timer<.3 and timer>.1:
			$HitBox/CollisionShape2D.disabled = false
		else:
			$HitBox/CollisionShape2D.disabled = true
		timer+=General.thisDelta
		if $AnimationPlayer.current_animation!=("lunge"):
			$AnimationPlayer.play("lunge")
		move_and_slide()
		await nextFrame
	usingAttack = false
	$HitBox/CollisionShape2D.disabled = true
	
