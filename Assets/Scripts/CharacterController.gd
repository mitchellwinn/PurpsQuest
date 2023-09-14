extends CharacterBody2D

signal nextFrame

const SPEED = 100.0
const JUMP_VELOCITY = -250.0
const KNOCKBACK_VELOCITY = 200

var distance_to_floor = 0.0
var direction
var facingVector
var facingString
var jumpDir
var crouching = false
var lastMoveVector
var usingSpecialMove = false
var usingAttack = false
var currentSpecialMove = ""
var currentAttack = ""
var onFloorLastFrame = false
var stun = 0.0
var hitConfirm = false
var dead = false
var hpShowFrame = 20.0
var mpShowFrame = 20.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var waterSlowdown = 1.0
var iframes = 0

func _ready():
	$Guy/Afterimage.emitting = false
	facingVector = Vector2(1,0)
	lastMoveVector = Vector2(1,0)
	facingString = "right"
	hpShowFrame = 20.0
	mpShowFrame = 20.0
	
func isCrouching():
	if is_on_floor() and PlayerInputs.down and hasControl():
		return true
	else:
		return false
	
func _physics_process(delta):
	crouching = isCrouching()
	move(delta)
	if General.animatorOn:
		animate(delta)
	nextFrame.emit()
	if abs(velocity.x)>1:
		lastMoveVector = velocity
	#print(jumpDir)

func move(delta):
	if stun>0:
		stun-=delta
	else:
		stun=0
	if iframes>0:
		iframes-=delta
	else:
		iframes=0
	if not is_on_floor():
		if onFloorLastFrame:
			jumpDir = velocity.normalized().x
		if is_on_wall() and velocity.y>10 and facingString == whichWall() and Keys.canWalljump:
			velocity.y += gravity/5 * delta
			if velocity.y>50:
				velocity.y=50
		elif !(usingAttack and currentAttack == "diveKick" and !is_on_wall()):
			velocity.y += gravity * delta * waterSlowdown
			if velocity.y>80 and waterSlowdown<1:
				velocity.y=80
		distance_to_floor = get_distance_to_floor()
	else:
		distance_to_floor = 0
	lerp_camera_offset()
	onFloorLastFrame = is_on_floor()
	# Handle Jump.
	if PlayerInputs.tapJump and is_on_floor() and hasControl():
		velocity.y = JUMP_VELOCITY
		if velocity:
			jumpDir = velocity.normalized().x
		else:
			jumpDir = 0
	elif PlayerInputs.tapJump and is_on_wall() and hasControl() && velocity.y>10 and Keys.canWalljump:
		PlayerInputs.tapJump = false
		velocity.y = JUMP_VELOCITY
		if velocity:
			jumpDir = velocity.normalized().x*.15-facingVector.x*.8
		else:
			jumpDir = 0
	
	# Handle Special Moves.
	specialMove(delta)
	# Handle Regular Attacks.
	attack(delta)
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if hasControl():
		direction = Input.get_axis("left", "right")
	else:
		direction = 0
	if !jumpDir:
		jumpDir = velocity.normalized().x
	if !usingSpecialMove and !usingAttack:
		if stun>0:
				velocity.x = move_toward(velocity.x, 0, 2)
		elif direction and is_on_floor() and hasControl():
				velocity.x = direction * SPEED * waterSlowdown
		elif !is_on_floor():
			#print (direction)
			jumpDir = move_toward(jumpDir, direction, .2*delta)
			velocity.x = (direction * SPEED)/2 + (jumpDir * SPEED)/2
		else:
			velocity.x = move_toward(velocity.x, 0, 5)
	
	if crouching:
		velocity.x = 0
	
	move_and_slide()
	if true:
		if velocity.x<-0.1 and PlayerInputs.left:
			$Guy.flip_h = true
			facingVector = Vector2(-1,0)
			facingString = "left"
			#$Guy/Cape.scale = Vector2(-1,1)
			$Guy/CapeHolder/Cape.flip_h = false
		elif velocity.x>0.1 and PlayerInputs.right:
			$Guy.flip_h = false
			facingVector = Vector2(1,0)
			facingString = "right"
			#$Guy/Cape.scale = Vector2(1,1)
			$Guy/CapeHolder/Cape.flip_h = true
		#$Guy/CapeHolder.scale.x = facingVector.x
		$SlashHitbox.scale.x= facingVector.x*.7
		$LungeHitbox.scale.x= facingVector.x
		$DiveHitbox.scale.x= facingVector.x
		$SlashHitbox/CollisionShape2D.disabled = true
		$LungeHitbox/CollisionShape2D.disabled = true
		$DiveHitbox/CollisionShape2D.disabled = true
		$SlideHitbox/CollisionShape2D.disabled = true

func get_distance_to_floor():
	var distance = 0
	if $RayCast2D.is_colliding():
		distance = ($RayCast2D.get_collision_point()-$RayCast2D.position).length()
	return clamp(distance,0,100)
	
func whichWall():
	if $WallTop.is_colliding() or $WallBot.is_colliding():
		return "right"
	else:
		return "left"

func lerp_camera_offset():
		General.playerCam.position.y = lerp(General.playerCam.position.y,float(distance_to_floor/10)-50,.05)
	
func hasControl():
	if !TextEngine.messageStatus and !usingSpecialMove and !usingAttack and stun<=0 and !dead and !General.cutsceneActive:
		return true
	else:
		if stun:
			usingAttack = false
		return false

func specialMove(delta):
	if PlayerInputs.extraAction:
		moonwalk(delta)
	return usingSpecialMove
	
func attack(delta):
	if PlayerInputs.attack:
		if PlayerInputs.up:
				throwItem(delta)
		if !is_on_floor():
				airSlash(delta)
		elif crouching and Keys.canSlideKick:
			slideKick(delta)
		elif !usingSpecialMove:
			slash(delta)
		elif currentSpecialMove == "moonwalk" && usingSpecialMove:
			lunge(delta)
	elif PlayerInputs.tapJump:
		if !is_on_floor() and distance_to_floor>5 and Keys.canDiveKick:
			diveKick(delta)
	return usingAttack
	
func throwItem(delta):
	if !hasControl():
		return
	if General.currentItem == "none":
		return
	if !General.itemResolved:
		return
	if $Stats.mp<General.inGameItems[General.currentItemIndex].cost:
		return
	$Stats.mp-=General.inGameItems[General.currentItemIndex].cost
	currentAttack = "throwItem"
	usingAttack = true
	var dir = facingVector
	var timer = 0
	var decaySpeed = SPEED
	var initialFacing = facingVector
	var initialFlip = $Guy.flip_h
	while(timer<.3 and usingAttack):
		$Guy/Afterimage.emitting = true
		if timer>.1 and timer<.2:
			if General.itemResolved:
				General.inGameItems[General.currentItemIndex].go()
		velocity.x = dir.x * decaySpeed/70
		timer+=delta*(1+Keys.swordStrength()/4)
		decaySpeed-=(delta*SPEED/3)
		if decaySpeed<0:
			decaySpeed = 0
		await nextFrame
	$Guy/Afterimage.emitting = false
	direction = velocity.normalized().x
	jumpDir = velocity.normalized().x
	usingAttack = false
	hitConfirm = false

func moonwalk(delta):
	if !Keys.canBackdash:
		return
	if !is_on_floor():
		return
	elif !hasControl():
		return
	currentSpecialMove = "moonwalk"
	usingSpecialMove = true
	var dir = -facingVector
	var timer = 0
	var decaySpeed = SPEED
	var jumpBooster = 1
	var initialFacing = facingVector
	var initialFlip = $Guy.flip_h
	while(timer<1 && usingSpecialMove):
		$Guy/Afterimage.emitting = true
		if is_on_floor():
			jumpBooster = 1
		else:
			jumpBooster = 4
		velocity.x = dir.x * decaySpeed *3
		timer+=delta*2
		decaySpeed-=(delta*SPEED/jumpBooster*2)
		#move_and_slide()
		if timer>0.8 and PlayerInputs.extraAction and is_on_floor():
			timer = 0
			decaySpeed = SPEED
			$AnimationPlayer.seek(0)
		if PlayerInputs.tapJump and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if timer>0.4:
			if is_on_floor():
				$Guy.flip_h = initialFlip
				facingVector = initialFacing
			elif Input.get_axis("left", "right")==-initialFacing.x:
				$Guy.flip_h = !initialFlip
				facingVector = -initialFacing
		await nextFrame
	$Guy/Afterimage.emitting = false
	direction = velocity.normalized().x
	jumpDir = velocity.normalized().x
	usingSpecialMove = false
	
func slash(delta):
	if !hasControl():
		return
	currentAttack = "slash"
	usingAttack = true
	var dir = facingVector
	var timer = 0
	var decaySpeed = SPEED
	var jumpBooster = 1
	var initialFacing = facingVector
	var initialFlip = $Guy.flip_h
	while(timer<.75 and usingAttack):
		$Guy/Afterimage.emitting = true
		if timer>.05 and timer<.5:
			#$SlashHitbox.scale.x = $SlashHitbox.scale.x*700
			$SlashHitbox/CollisionShape2D.disabled = false
		timer+=delta
		velocity.x = dir.x * decaySpeed/10
		decaySpeed-=(delta*SPEED/3)
		if decaySpeed<0:
			decaySpeed = 0
		if timer>.5 and hitConfirm and PlayerInputs.attack:
			timer = 0
			hitConfirm = false
			decaySpeed = SPEED
			$AnimationPlayer.seek(0)
		await nextFrame
		#move_and_slide()
	$Guy/Afterimage.emitting = false
	direction = velocity.normalized().x
	jumpDir = velocity.normalized().x
	usingAttack = false
	hitConfirm = false

func lunge(delta):
	usingSpecialMove = false
	if !hasControl:
		return
	await nextFrame
	$Guy/Afterimage.emitting = true
	currentAttack = "lunge"
	usingAttack = true
	var dir = facingVector
	var timer = 0
	var decaySpeed = SPEED
	var jumpBooster = 1
	var initialFacing = facingVector
	var initialFlip = $Guy.flip_h
	while(timer<.75 and usingAttack):
		velocity.x = dir.x * decaySpeed
		timer+=delta
		decaySpeed-=(delta*SPEED/3)
		#$LungeHitbox.scale.x = $LungeHitbox.scale.x*1000
		$LungeHitbox/CollisionShape2D.disabled = false
		if timer>.4 and hitConfirm and PlayerInputs.attack:
			timer = 0
			hitConfirm = false
			decaySpeed = SPEED
			$AnimationPlayer.seek(0)
		await nextFrame
	$Guy/Afterimage.emitting = false
	direction = velocity.normalized().x
	jumpDir = velocity.normalized().x
	usingAttack = false
	hitConfirm = false

func slideKick(delta):
	usingSpecialMove = false
	if !hasControl:
		return
	await nextFrame
	$Guy/Afterimage.emitting = true
	currentAttack = "slideKick"
	usingAttack = true
	var dir = facingVector
	var timer = 0
	var decaySpeed = SPEED
	var jumpBooster = 1
	var initialFacing = facingVector
	var initialFlip = $Guy.flip_h
	var dir2 = 1
	velocity.x = dir.x * decaySpeed * 3 * dir2
	while((timer<.75 or $CrouchCast.is_colliding()) and usingAttack and ((PlayerInputs.down or $CrouchCast.is_colliding()) or timer<.3)):
		$SlideHitbox/CollisionShape2D.disabled = false
		if velocity.x==0:
			dir2=dir2*-1
			facingVector.x = facingVector.x*-1
			direction = direction*-1
			$Guy.flip_h = !$Guy.flip_h
		velocity.x = dir.x * decaySpeed * 3 * dir2
		timer+=delta
		decaySpeed-=(delta*SPEED)
		#$LungeHitbox.scale.x = $LungeHitbox.scale.x*1000
		if $CrouchCast.is_colliding():
			velocity.x = dir.x * SPEED * 3 * dir2
		if timer>.5 and (PlayerInputs.attack or $CrouchCast.is_colliding()):
			timer = 0
			decaySpeed = SPEED
			hitConfirm = false
			$AnimationPlayer.seek(0)
		await nextFrame
	$Guy/Afterimage.emitting = false
	$AnimationPlayer.play("crouch")
	$AnimationPlayer.seek(1)
	direction = velocity.normalized().x
	jumpDir = velocity.normalized().x
	usingAttack = false
	hitConfirm = false

func airSlash(delta):
	if currentSpecialMove == "moonwalk":
		usingSpecialMove = false
	if !hasControl():
		return
	currentAttack = "airSlash"
	usingAttack = true
	var timer = 0
	while(timer<.75 and usingAttack and !is_on_floor()):
		$Guy/Afterimage.emitting = true
		if timer>.1 and timer<.4:
			#$SlashHitbox.scale.x = $SlashHitbox.scale.x*700
			$SlashHitbox/CollisionShape2D.disabled = false
		timer+=delta*(1+Keys.swordStrength()/4)
		if timer>0.25:
			$Guy/Afterimage.emitting = false
		if timer>.4 and hitConfirm and PlayerInputs.attack:
			timer = 0
			hitConfirm = false
			$AnimationPlayer.seek(0)
		await nextFrame
	$Guy/Afterimage.emitting = false
	direction = velocity.normalized().x
	jumpDir = velocity.normalized().x
	usingAttack = false
	hitConfirm = false

func diveKick(delta):
	if currentSpecialMove == "moonwalk":
		usingSpecialMove = false
	if !hasControl():
		return
	currentAttack = "diveKick"
	usingAttack = true
	var dir = facingVector
	var timer = 0
	while(usingAttack and !is_on_floor() and timer<1 and !is_on_wall()):
		timer += delta
		$Guy/CapeHolder/Cape.rotation= abs($Guy/CapeHolder/Cape.rotation)*facingVector.x
		$Guy/CapeHolder/Cape.skew= abs($Guy/CapeHolder/Cape.skew)*facingVector.x
		$Guy/Afterimage.emitting = true
		velocity = Vector2(dir.x,abs(dir.x))*200
		#$DiveHitbox.scale.x = $DiveHitbox.scale.x*1000
		$DiveHitbox/CollisionShape2D.disabled = false
		if hitConfirm:
			velocity = Vector2(dir.x/2,-abs(dir.x))*100
			break
		await nextFrame
	$Guy/Afterimage.emitting = false
	direction = velocity.normalized().x
	jumpDir = velocity.normalized().x
	usingAttack = false
	hitConfirm = false

func animate(delta):
	
	var capeMoveVector = lastMoveVector.normalized().x
	if $Guy/CapeHolder/Cape.rotation>1.6:
		capeMoveVector = 1
	elif $Guy/CapeHolder/Cape.rotation<-1.6:
		capeMoveVector = -1
	if velocity.length()>1:
		$Guy/CapeHolder/Cape/AnimationPlayer.play("wave")
		$Guy/CapeHolder/Cape/AnimationPlayer.speed_scale=velocity.length()/80+.2
	$Guy/CapeHolder/Cape.rotation = lerp($Guy/CapeHolder/Cape.rotation,clamp(velocity.x/550+capeMoveVector*clamp(velocity.y/20,0,3000),-3.14159/2,3.14159/2),delta*2)
	#print(velocity.y)
	#print($Guy/Cape.rotation) 
	$Guy/CapeHolder/Cape.skew = $Guy/CapeHolder/Cape.rotation/4
	$Guy.visible = true
	$Guy.modulate = Color(1,1,1,1)
	if iframes>0 and stun<=0:
		if Time.get_ticks_msec()%10<5:
			$Guy.visible = false
		else:
			$Guy.visible = true
			$Guy.modulate = Color(1,1,1,1)
	if dead:
		$AnimationPlayer.play("stun")
	elif stun>0:
		if Time.get_ticks_msec()%10<5:
			$Guy.visible = false
		else:
			$Guy.visible = true
			$Guy.modulate = Color(1,0,0,1)
		$AnimationPlayer.play("stun")
	elif is_on_wall() and velocity.y>10 and Keys.canWalljump:
		if facingString == whichWall():
			$AnimationPlayer.play("onWall")
	elif usingSpecialMove && is_on_floor():
		if $AnimationPlayer.current_animation!=currentSpecialMove && currentSpecialMove == "moonwalk":
			$AnimationPlayer.play(currentSpecialMove)
			$AnimationPlayer.speed_scale = 2
	elif usingAttack:
		if currentAttack == "diveKick":
			$AnimationPlayer.play("fall")
			$AnimationPlayer.speed_scale = 1.5
		elif $AnimationPlayer.current_animation!=currentAttack:
			$AnimationPlayer.play(currentAttack)
			$AnimationPlayer.speed_scale = .5*(1+Keys.swordStrength()/4)
			if currentAttack == "airSlash":
				$AnimationPlayer.speed_scale = .5*(1+Keys.swordStrength()/4)
	elif is_on_floor():
		if velocity.length()>.1:
			$AnimationPlayer.play("walk")
			$AnimationPlayer.speed_scale = abs(velocity.x)/100
		elif velocity.length()<.1 and crouching and $AnimationPlayer.current_animation != "crouch":
			$AnimationPlayer.speed_scale = 2
			$AnimationPlayer.play("crouch")
		elif velocity.length()<.1 and !crouching:
			if $AnimationPlayer.current_animation == "crouch":
				$AnimationPlayer.play("uncrouch")
				$AnimationPlayer.speed_scale = 2
			elif $AnimationPlayer.current_animation != "uncrouch":
				$AnimationPlayer.play("stand")
	else:
		if velocity.y<=0:
			$AnimationPlayer.play("jump")
			$AnimationPlayer.speed_scale = 1
		elif velocity.y>0:
			$AnimationPlayer.play("fall")
			$AnimationPlayer.speed_scale = 1
			
	#hp ui
	
	var ui = get_node("/root/World/UI")
	var hptargetFrame = clamp((20-round((float($Stats.hp)/float($Stats.maxHP))*20)),0,20)
	var mptargetFrame = clamp((20-round((float($Stats.mp)/float($Stats.maxMP))*20)),0,20)
	mpShowFrame = move_toward(mpShowFrame,mptargetFrame,delta*60)
	hpShowFrame = move_toward(hpShowFrame,hptargetFrame,delta*60)
	ui.get_node("HP").frame = round(hpShowFrame)
	ui.get_node("MP").frame = round(mpShowFrame)
	#print(round(hpShowFrame))

func _on_hurt_box_area_entered(area):
	if !area.get_parent().get_node("Stats"):
		return
	if area.get_parent().dead or dead or iframes>0 or area.get_parent().stun>0 or area.get_parent().suspension>0 or General.cutsceneActive:
		return
	takeDamage(area)

func takeDamage(area):
	$Stats.hp-=area.get_parent().get_node("Stats").damage
	usingSpecialMove = false
	usingAttack = false
	direction = 0
	stun = 0.5
	iframes = 1
	var horizontalKB = Vector2(2,0)
	if global_position.x<area.get_parent().global_position.x:
		horizontalKB = Vector2(-2,0)
	velocity = ((position-area.get_parent().position).normalized()+horizontalKB+Vector2(0,1.3)).normalized()*KNOCKBACK_VELOCITY+Vector2.UP*KNOCKBACK_VELOCITY*(.75)
	if $Stats.hp<0:
		die()
		
func die():
	if dead:
		return
	if $Stats.hp<0:
		General.resetWorld()
		get_node("/root/World/TextPrinter").stream = load("res://Assets/SFX/firetext.mp3")
		get_node("/root/World/UI/TextBox/Text").self_modulate = Color(0,0,0,1)
		dead=true
		var timer = 0
		get_node("/root/World/Map").visible = false
		General.activeCam.get_node("flames/AnimationPlayer").play("burn")
		while timer< 1 : 
			General.bg1.visible = false
			General.bg2.visible = false
			if Time.get_ticks_msec()%10<5:
				$Guy.visible = false
				if RandomNumberGenerator.new().randi_range(0,10)>7:
					General.activeCam.get_node("flames").visible = true
			else:
				$Guy.visible = true
				General.activeCam.get_node("flames").visible = false
				$Guy.modulate = Color(1,0,1,1)
			timer += General.thisDelta
			await nextFrame
		General.activeCam.get_node("flames").visible = true
		$Guy.modulate = Color(1,1,1,1)
		$Guy.self_modulate = Color(0,0,0,1)
		var confirm = false
		timer = 0
		get_node("/root/World/GeneralText").dialogueTreeKey = 0
		get_node("/root/World/GeneralText").interaction = 0
		get_node("/root/World/UI/TextBox/Text").get_material().set_shader_parameter("Strength",2)
		get_node("/root/World/GeneralText").interaction = 0
		get_node("/root/World/GeneralText").dialogueTreeKey= 0
		TextEngine.go(get_node("/root/World/GeneralText"))
		while !confirm or timer< 2:
			if PlayerInputs.attack or PlayerInputs.jump:
				confirm = true
			await nextFrame
			timer+=General.thisDelta
		$Guy.visible = true
		$Guy.self_modulate = Color(1,1,1,1)
		#global_position = General.saveLocation
		$Stats.hp = $Stats.maxHP
		dead=false
		get_node("/root/World/Map").visible = true
		General.activeBG = General.saveLocationBG
		General.updateBackgrounds()
		get_node("/root/World/UI/TextBox/Text").get_material().set_shader_parameter("Strength",0)
		get_node("/root/World/UI/TextBox/Text").self_modulate = Color(1,1,1,1)
		General.activeCam.get_node("flames").visible = false
		confirm = false
		General.data.load(General.SAVE_PATH)
		General.loadData(General.data)


func _on_slime_boss_arena_body_entered(body):
	if body != self:
		return
	Keys.canWalljump = true
	


func _on_slime_boss_arena_body_exited(body):
	if body !=self:
		return
	if !Keys.stickyGlove:
		Keys.canWalljump = false
