extends "res://Assets/Scripts/Enemy.gd"

var directionTimer = 3;
var spawns: Array
var  toSpawnLoad

func _ready():
	toSpawnLoad = load("res://Assets/Enemies/slime.tscn")
	initialize()
	lookWhenHit = false
	hasEyes = true
	SPEED = 0
	JUMP_VELOCITY = -500.0
	aggroRange = 300
	originLimit = 270
	deathLength = 10
	
	decideDirection()
	attackPattern()

func _physics_process(delta):
	var i =0
	if stun>0 or suspension>0:
		usingAttack = false
	for obj in spawns:
		if obj.dead:
			spawns.remove_at(i)
		i+=1
	if !usingAttack:
		animate(1.5)
	checkAggro()
	checkDamage()
	move(delta)
	if dead and Keys.slimeBossFight != 2:
		General.switchCameraTo(General.playerCam,10)
		Keys.slimeBossFight = 2
	if Keys.slimeBossFight == 2 and !dead:
		queue_free()
	nextFrame.emit()
	
	
	
	
func decideDirection():
	var time = 0
	if aggro:
		directionTimer = rng.randf_range(0.25,.75)
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
	var waitTimer = rng.randf_range(1.0,2.0)
	while time<waitTimer:
		if aggro:
			pass
		if usingAttack:
			pass
		time+=General.thisDelta
		await nextFrame
	if aggro and !usingAttack and is_on_floor() and hasControl():
		var decision = rng.randf_range(0.0,1.0)
		if decision >0.3 and spawns.size()<4:
			slimeSpit()
		else:
			jumpAttack()
		pass
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
	
func randomizeDirection():
	if !aggro:
		direction = Vector2(0,0)
		return
	var random = RandomNumberGenerator.new().randi_range(0,3)
	if random<1:
		direction = Vector2(-1,0)
	elif random<2:
		if aggro:
			direction = Vector2(aggro.position.x-position.x,0).normalized()
			print(str(direction) + " :: aggro dir")
		else:
			direction = Vector2(0,0)
	else:
		direction = Vector2(1,0)
		
func checkDamage():
	#print($Area2D.get_overlapping_areas().size())
	if suspension>0 and stun<.25 and $HurtBox.get_overlapping_areas().size()>0 and !invul:
		if General.player.usingAttack or !General.itemResolved:
			takeDamage(General.player,General.player.currentAttack)
			SPEED = (($Stats.maxHP+1)/((abs($Stats.hp)+1))*10)+30
			return
	elif stun<.25 and $HurtBox.get_overlapping_areas().size()>0 and !invul:
		if General.player.usingAttack or !General.itemResolved:
			takeDamage(General.player,General.player.currentAttack)
			SPEED = (($Stats.maxHP+1)/((abs($Stats.hp)+1))*10)+30
	elif stun==0 and suspension == 0 and $BounceBox.get_overlapping_areas().size()>0 and !invul:
		if General.player.usingAttack or !General.itemResolved:
			General.player.usingAttack = false
			General.itemResolved = true
			if (General.player.global_position-global_position).length()<30:
				General.player.stun = .3
			General.screenImpact(.2)
			$Bounce.play()
			General.player.velocity = 200*(General.player.global_position-global_position).normalized()
	
func slimeSpit():
	usingAttack = true
	var i = 0
	$AnimationPlayer.play("spit")
	await get_tree().create_timer(1).timeout
	var timer = 0
	while timer < .4:
		if Time.get_ticks_msec()%20<10:
			$Sprite.visible = false
		else:
			$Sprite.visible = true
			$Sprite.modulate = Color(.5,.5,.5,1)
		timer+=General.thisDelta
		await nextFrame
	$Sprite.visible = true
	$Sprite.modulate = Color(.5,.5,1,1)
	var sizer = spawns.size()
	while spawns.size()<clamp(sizer,1,3) and usingAttack:
		spawn()
		await get_tree().create_timer(.5).timeout
	if spawns.size()<4 and usingAttack:
		spawn()
		await get_tree().create_timer(.5).timeout
	usingAttack = false
	
func spawn():
	$Spawn.play()
	var thisSpawn = toSpawnLoad.instantiate()
	spawns.append(thisSpawn)
	get_node("/root/World/Map").add_child(thisSpawn)
	thisSpawn.global_position = $LaunchPoint.global_position
	thisSpawn.origin = $LaunchPoint.global_position
	if aggro:
		thisSpawn.velocity = 400* Vector2(aggro.global_position.x-global_position.x,0).normalized()+ Vector2(0,-400)
	else:
		return
	thisSpawn.suspension = .5
