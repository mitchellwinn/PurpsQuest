extends "res://Assets/Scripts/Enemy.gd"

var directionTimer = 3;
@export var warp1: Node2D
@export var warp2: Node2D
@export var warp3: Node2D
@export var warp4: Node2D
var lastWarp = false

func _ready():
	initialize()
	defendArea =  Vector2(701,757)
	originLimit = 100
	lookWhenHit = true
	var hasEyes = false
	SPEED = 50.0
	JUMP_VELOCITY = -350.0
	aggroRange = 100
	deathLength = 3
	decideDirection()
	attackPattern()
	

func _physics_process(delta):
	if !usingAttack:
		animate(1.5)
	checkAggro()
	move(delta)
	checkWarp()
	checkDamage()
	nextFrame.emit()
	SPEED = 150.0* (1-($Stats.hp/$Stats.maxHP))
	if dead and Keys.sahagin< 1:
		Keys.sahagin = 1
	if Keys.sahagin == 1 and !dead:
		queue_free()
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
	if usingAttack:
		return
	usingAttack = true
	SPEED = SPEED/2
	#$AnimationPlayer.play("prejump")
	var timer = 0
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
	invul = false
	
func checkWarp():
	if $Area2D.get_overlapping_areas().size()>0 and !lastWarp:
		if $Area2D.get_overlapping_areas()[0].collision_layer==8:
			lastWarp = true
			var pick = RandomNumberGenerator.new().randi_range(0,3)
			var pickposition = Vector2.ZERO
			match pick:
				0: 
					pickposition = warp1.global_position
				1: 
					pickposition = warp2.global_position
				2: 
					pickposition = warp3.global_position
				3: 
					pickposition = warp4.global_position
			global_position = global_position+Vector2(0,300)
			await get_tree().create_timer(RandomNumberGenerator.new().randi_range(1,3)).timeout
			General.screenImpact(.5)
			var splash = load("res://Assets/FX/splash1.tscn").instantiate()
			splash.global_position = pickposition+Vector2(0,20)
			get_node("/root/World/Map").add_child(splash)
			await get_tree().create_timer(.2).timeout
			splash = load("res://Assets/FX/splash1.tscn").instantiate()
			splash.global_position = pickposition+Vector2(0,20)
			get_node("/root/World/Map").add_child(splash)
			await get_tree().create_timer(.2).timeout
			splash = load("res://Assets/FX/splash1.tscn").instantiate()
			splash.global_position = pickposition+Vector2(0,20)
			get_node("/root/World/Map").add_child(splash)
			global_position =  pickposition
		elif $Area2D.get_overlapping_areas().size() == 0:
			lastWarp = false
