extends CharacterBody2D

signal nextFrame

var SPEED = 100.0
var JUMP_VELOCITY = -250.0
var KNOCKBACK_VELOCITY = 200.0

var direction = Vector2.ZERO
var usingAttack = false
var aggro = null
var player: CharacterBody2D
var aggroRange
var rng
var stun = 0
var suspension = 0
var dead = false
var invul
var origin
var lookWhenHit 
var hasEyes
var originLimit
var deathLength = 0
var deathParticle = "res://Assets/FX/explosion1.tscn"
var defendArea


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Called when the node enters the scene tree for the first time.

func initialize():
	player = get_node("/root/World/Player")
	rng = RandomNumberGenerator.new()
	direction = Vector2.ZERO
	invul = false
	origin = global_position
	
func dropItem(item):
	item.visible = true
	item.get_node("Area2D/CollisionShape2D").disabled = false
	item.reparent(get_node("/root/World/Map"))
	item.velocity = Vector2(RandomNumberGenerator.new().randf_range(400,0)-global_position.x,0)+ Vector2(0,-400)	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func move(delta):
	if defendArea and abs((General.player.global_position-defendArea).x)<150:
		direction = -(Vector2(global_position.x,0.0) -  Vector2(defendArea.x,0.0)).normalized()
	elif (origin-global_position).length()>originLimit:
		direction = -(Vector2(global_position.x,0.0) -  Vector2(origin.x,0.0)).normalized()
	
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
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if false==true:
		velocity.y = JUMP_VELOCITY

	if stun>0 or suspension > 0:
		velocity.x = move_toward(velocity.x, 0, 2)
	elif direction:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if direction.x>0:
		$Sprite.flip_h=true
		if hasEyes:
			$Sprite/Socket1.position.x = 9
			$Sprite/Socket2.position.x = 39
			$LaunchPoint.position.x = 22
	elif direction.x<0:		
		$Sprite.flip_h=false
		if hasEyes:
			$Sprite/Socket1.position.x = -39
			$Sprite/Socket2.position.x = -9
			$LaunchPoint.position.x = -22
	if hasEyes:
			$Sprite/Socket1/Eye.offset = (player.global_position - global_position).normalized()*5
			$Sprite/Socket2/Eye.offset = (player.global_position - global_position).normalized()*5
			$LaunchPoint.position.x = 22
	move_and_slide()

func animate(multiplier):
	$Sprite.visible = true
	$Sprite.modulate = Color(1,1,1,1)
	if stun>0:
		if Time.get_ticks_msec()%10<5:
			$Sprite.visible = false
		else:
			$Sprite.visible = true
			$Sprite.modulate = Color(1,0,0,1)
	if usingAttack or !hasControl():
		return
	if is_on_floor():
		if velocity.length()<10 and $AnimationPlayer.current_animation!="stand":
			$AnimationPlayer.play("stand")
			$AnimationPlayer.speed_scale = 1*multiplier
		elif velocity.length()>=10 and $AnimationPlayer.current_animation!="walk":
			$AnimationPlayer.play("walk")
			$AnimationPlayer.speed_scale = 1*multiplier
		
	elif velocity.y>=0:
			$AnimationPlayer.play("fall")
			$AnimationPlayer.speed_scale = 1*multiplier
	elif velocity.y<0:
			$AnimationPlayer.play("jump")
			$AnimationPlayer.speed_scale = 1*multiplier
			
func hasControl():
	if !usingAttack and stun<=0 and suspension<=0 and !General.cutsceneActive:
		return true
	else:
		return false
		
func randomizeDirection():
	var random = RandomNumberGenerator.new().randi_range(0,3)
	if random<1:
		direction = Vector2(-1,0)
	elif random<2:
		if aggro:
			direction = Vector2(aggro.global_position.x-global_position.x,0).normalized()
			#print(str(direction) + " :: aggro dir")
		else:
			direction = Vector2(0,0)
	else:
		direction = Vector2(1,0)
		
func checkAggro():
	if !hasControl():
		return
	if (player.global_position-global_position).length()<aggroRange and !aggro:
		aggro = player
	elif (player.global_position-global_position).length()>aggroRange*1.2 and aggro:
		aggro = null
	
func checkDamage():
	#print($Area2D.get_overlapping_areas().size())
	if stun<.25 and $Area2D.get_overlapping_areas().size()>0 and !invul:
		for n in  $Area2D.get_overlapping_areas():
			if n.collision_layer == 2:
				if player.usingAttack and General.itemResolved:
					takeDamage(player,player.currentAttack)
					return
				elif !General.itemResolved:
					takeDamage(player,"throwItem")
					return
	
			
func takeDamage(attacker,attack):
	#print("Took damage from "+attack)
	if attack != "diveKick" and attack != "slideKick":
		$Stats.hp-=attacker.get_node("Stats").damage*(Keys.swordStrength()+1)/3+ceil(attacker.get_node("Stats").damage/2)
	else:
		$Stats.hp-=ceil(attacker.get_node("Stats").damage/2)
	attacker.get_node("SFXslash").play()
	attacker.hitConfirm=true
	usingAttack = false
	if lookWhenHit:
		direction = Vector2(attacker.facingVector.x*-1,0)
	stun = 0.5
	if attacker.name == "Player":
		General.screenImpact(.2)
	var horizontalKB = Vector2(2,0)
	if global_position.x<attacker.global_position.x:
		horizontalKB = Vector2(-2,0)
	velocity = ((global_position-attacker.global_position).normalized()+horizontalKB+Vector2(0,1.3)).normalized()*KNOCKBACK_VELOCITY+Vector2.UP*KNOCKBACK_VELOCITY*(.75)
	if attack == "diveKick":
		attacker.velocity = .7*(((attacker.position-position).normalized()+horizontalKB+Vector2(0,1.3)).normalized()*KNOCKBACK_VELOCITY+Vector2.UP*KNOCKBACK_VELOCITY*(1.75))
	if $Stats.hp<=0:
		die()

func die():
	if $Stats.hp<0 and !dead:
		var rng = RandomNumberGenerator.new()
		var explode = load(deathParticle)
		dead=true
		await get_tree().create_timer(.1*deathLength).timeout
		for n in range(deathLength):
			General.screenImpact(.08)
			var thisexplode = explode.instantiate()
			get_node("/root/World").add_child(thisexplode)
			thisexplode.global_position = global_position+RandomNumberGenerator.new().randi_range(-10,10)*deathLength*Vector2(1,1)
			thisexplode = explode.instantiate()
			get_node("/root/World").add_child(thisexplode)
			thisexplode.global_position = global_position+Vector2(rng.randi_range(-10,10)*deathLength,rng.randi_range(-10,10)*deathLength)
			await get_tree().create_timer(.1).timeout
		if get_node("Item"):
			var key = $Item
			dropItem(key)
		queue_free()
		
	
	
