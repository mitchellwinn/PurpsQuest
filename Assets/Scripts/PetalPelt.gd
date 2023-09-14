extends "res://Assets/Scripts/Enemy.gd"

var directionTimer = 3;
var variation = 1.0
var parts: Array
@export var petals: Array
var petalAttack = false
var amt = 1 

func _ready():
	initialize()
	variation = RandomNumberGenerator.new().randf_range(1,3)
	originLimit = 300
	lookWhenHit = true
	var hasEyes = false
	SPEED = 40.0
	JUMP_VELOCITY = -300.0
	aggroRange = 150
	deathLength = 7
	var variation
	direction = Vector2.ZERO
	var part = load("res://Assets/Enemies/petalPeltBody.tscn")
	for n in range(0,$Path2D.curve.point_count):
		var  thisPart = part.instantiate()
		#get_node("/root/World/Map").add_child(thisPart)
		add_child(thisPart)
		thisPart.global_position = $Path2D.global_position + $Path2D.curve.get_point_position ( n )
		thisPart.origin = thisPart.global_position
		parts.append(thisPart)
	for n in range(0,8):
		petals.append(get_node("Petal"+str(n+1)))
		#get_node("/root/World/Map").add_child(thisPart)
	print(petals.size())
	leafAttack()
func _physics_process(delta):
	SPEED = (player.global_position-global_position).length()/2
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
	if Keys.petalPeltFight == 1 and !dead:
		queue_free()
	nextFrame.emit()
	
	
func move(delta):
	var n = 0
	if stun>0:
		stun-=delta
		#print(stun)
	else:
		stun = 0
		
	for part in parts:
		#print(n)
		if($Stats.hp<=0):
			return
		part.global_position = lerp(part.origin, $Path2D.global_position + $Path2D.curve.get_point_position ( n ),(float(n)/((parts.size()-1))))
		n+=1
	for petal in petals:
		petal.reparent($Petals) 
	if !petalAttack:
		$Petals.rotation += delta * 6 * (1-($Stats.hp/$Stats.maxHP))
	else:
		$Petals.rotation += delta * 2 * (1-($Stats.hp/$Stats.maxHP))
	for petal in petals:
		petal.reparent(self)
		
	var wantedDirection = (-(Vector2(global_position.x,0.0) -  Vector2(origin.x,0.0)).normalized() + Vector2(sin(Time.get_ticks_msec()/200),sin(Time.get_ticks_msec()/400))*3).normalized()
	if aggro:
		if aggro.stun==0:
			wantedDirection = ((aggro.global_position-global_position)/10+(aggro.global_position-global_position).normalized()*sin(Time.get_ticks_msec()/200) + Vector2(sin(Time.get_ticks_msec()/200),sin(Time.get_ticks_msec()/400))).normalized()
	direction = lerp(direction,wantedDirection,variation*delta*SPEED)
	
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
		#$AnimationPlayer.play("hang")
	move_and_slide()
	
func leafAttack():
	if dead:
		return
	var timer = 0
	amt = 1
	while !dead and !petalAttack:
		$Petals.position = lerp($Petals.position,Vector2.ZERO,General.thisDelta*4)
		if timer>amt:
			timer = 0 
			var deadPetals = 0
			for petal in petals:
				if !petal.visible:
					deadPetals+=1
			if deadPetals>4:
				#petalAttack = true
				pass
		timer+=General.thisDelta
		await nextFrame
	timer = 0
	while !dead and petalAttack:
		if timer>5:
			petalAttack = false
			timer = 0
			amt = 5
		$Petals.global_position = lerp($Petals.global_position,player.global_position,General.thisDelta*2)
		timer+=General.thisDelta
		await nextFrame
	petalAttack = false 
	leafAttack()
	
func checkDamage():
	for petal in petals:
		if petal.get_overlapping_areas().size()>0:
			print("hi")
			for n in  petal.get_overlapping_areas():
				if n.collision_layer == 2:
					if player.usingAttack and General.itemResolved:
						petalDie(petal)
					elif !General.itemResolved:
						petalDie(petal)
	#print($Area2D.get_overlapping_areas().size())
	if stun<.25 and $HurtBox.get_overlapping_areas().size()>0 and !invul:
		for n in  $HurtBox.get_overlapping_areas():
			if n.collision_layer == 2:
				if player.usingAttack and General.itemResolved:
					takeDamage(player,player.currentAttack)
					#return
				elif !General.itemResolved:
					takeDamage(player,"throwItem")
					#return
	
func petalDie(petal):
	var  this = load("res://Assets/FX/leafDebris.tscn").instantiate()
	get_node("/root/World/Map").add_child(this)
	this.global_position = petal.global_position
	petal.visible = false
	petal.get_node("CollisionShape2D").disabled = true
	var relief = 7 * (1-($Stats.hp/$Stats.maxHP))
	await get_tree().create_timer(15-relief).timeout
	petal.get_node("CollisionShape2D").disabled = false
	petal.visible = true
	var timer = 0.0
	petal.scale = Vector2.ZERO
	while timer <1:
		petal.scale = petal.scale.lerp(Vector2.ONE,General.thisDelta*4)
		timer+=General.thisDelta
		await nextFrame

func die():
	if $Stats.hp<0 and !dead:
		print ("called die")
		var rng = RandomNumberGenerator.new()
		var explode = load(deathParticle)
		await nextFrame
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
			await get_tree().create_timer(.25).timeout
		for part in parts:
			General.screenImpact(.05)
			var thisexplode = explode.instantiate()
			get_node("/root/World").add_child(thisexplode)
			thisexplode.global_position = part.global_position
			thisexplode = explode.instantiate()
			get_node("/root/World").add_child(thisexplode)
			thisexplode.global_position = part.global_position+Vector2(rng.randi_range(-10,10)*deathLength,rng.randi_range(-10,10)*deathLength)
			await get_tree().create_timer(.1).timeout
			parts.erase(part)
			part.queue_free()
		for petal in parts:
			General.screenImpact(.04)
			var thisexplode = explode.instantiate()
			get_node("/root/World").add_child(thisexplode)
			thisexplode.global_position = petal.global_position
			thisexplode = explode.instantiate()
			get_node("/root/World").add_child(thisexplode)
			thisexplode.global_position = petal.global_position+Vector2(rng.randi_range(-10,10)*deathLength,rng.randi_range(-10,10)*deathLength)
			await get_tree().create_timer(.02).timeout
			petals.erase(petal)
			petal.queue_free()
		if get_node("Item"):
			var key = $Item
			dropItem(key)
		queue_free()
		
	
	
