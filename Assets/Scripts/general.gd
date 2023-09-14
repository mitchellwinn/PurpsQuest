extends Node

const SAVE_PATH = "user://save_data.ini"

var thisDelta = 0
var shaking = 0

@onready var currentTrack = get_node("/root/World/Music").stream
@onready var player = get_node("/root/World/Player")
@onready var playerCam = player.get_node("Camera2D")
@onready var activeCam = playerCam
@onready var slimeBossCam = get_node("/root/World/Map/SlimeBoss/Camera2D")
@onready var bg1 = playerCam.get_node("Bg1")
@onready var bg2 = playerCam.get_node("Bg2")
@onready var flames = playerCam.get_node("flames")
var cutsceneActive = false
@onready var activeBG = bg1
@onready var ui = get_node("/root/World/UI")
var animatorOn = true
var itemResolved = true
var switchingCamera = false
var fileExists = false
var saveLocation = Vector3.ZERO
var saveLocationBG
var swordColors = [Color("fdfdfd"),Color("a73700"),Color("e2e600"),Color("42d1f5")]
var currentItem = "Chakram"
var currentItemIndex = 0
var inGameItems: Array
var data := ConfigFile.new()

signal nextFrame

func _ready():
	inGameItems.append(player.get_node("Chakram"))
	inGameItems.append(player.get_node("Axe"))
	#inGameItems.append(player.get_node("Knife"))
	#inGameItems.append(player.get_node("BowArrow"))
	#inGameItems.append(player.get_node("TetherShot"))
	data.load(SAVE_PATH)
	if (data.has_section("player")):
		#loadData(data)
		pass
	updateSwordColor()
	if checkNoItems():
		currentItem = "none"
	updateCurrentItem()
	markSaveLocation()

func _physics_process(delta):
	thisDelta = delta
	nextFrame.emit()
	#print(activeCam.get_parent().name)
	if activeCam.get_parent().name=="SlimeBoss":
		activeCam.global_position.x = player.global_position.x
	bg1.offset = -player.position/100
	bg2.offset = -player.position/100
	if player.hasControl():
		if PlayerInputs.swap:
			iterateCurrentItem()

func saveData():
	var data := ConfigFile.new()
	data.set_value("environment", "bg", General.activeBG.name)
	data.set_value("environment", "saveLocationBG", General.saveLocationBG.name)
	data.set_value("player", "position", player.global_position)
	data.set_value("player", "saveLocation", saveLocation)
	data.set_value("keys", "canWalljump", Keys.canWalljump)
	data.set_value("keys", "canBackdash", Keys.canBackdash)
	data.set_value("keys", "canDiveKick", Keys.canDiveKick)
	data.set_value("keys", "canSlideKick", Keys.canSlideKick)
	data.set_value("keys", "slimeBossFight", Keys.slimeBossFight)
	data.set_value("keys", "swords", Keys.swords)
	data.set_value("keys", "currentItem", General.currentItem)
	data.set_value("keys", "currentItemIndex", General.currentItemIndex)
	data.set_value("npcs", "zorloro", get_node("/root/World/Map/Zorloro/NPC").dialogueTreeKey)
	data.set_value("keys", "stickyGlove", Keys.stickyGlove)
	data.set_value("keys", "sahagin", Keys.sahagin)
	data.set_value("keys", "petalPeltFight", Keys.petalPeltFight)
	data.save(SAVE_PATH)
	ui.get_node("AnimationPlayer").play("GameSaved")
	
func loadData(data):
	General.activeBG = activeCam.get_node(str(data.get_value("environment", "bg")))
	General.saveLocationBG = activeCam.get_node(str(data.get_value("environment", "saveLocationBG")))
	player.global_position = data.get_value("player", "position")
	saveLocation = data.get_value("player", "saveLocation")
	Keys.canWalljump = data.get_value("keys", "canWalljump")
	Keys.canBackdash = data.get_value("keys", "canBackdash")
	Keys.canDiveKick = data.get_value("keys", "canDiveKick")
	Keys.canDiveKick = data.get_value("keys", "canSlideKick")
	Keys.slimeBossFight = data.get_value("keys", "slimeBossFight")
	Keys.swords = data.get_value("keys", "swords")
	General.currentItem = data.get_value("keys", "currentItem")
	General.currentItemIndex = data.get_value("keys", "currentItemIndex")
	get_node("/root/World/Map/Zorloro/NPC").dialogueTreeKey = data.get_value("npcs", "zorloro")
	Keys.stickyGlove = data.get_value("keys", "stickyGlove")
	Keys.sahagin = data.get_value("keys", "sahagin")
	Keys.petalPeltFight = data.get_value("keys", "petalPeltFight")
	updateBackgrounds()
	
func screenImpact(shakeTime):
	#print("impact")
	shaking+=1
	var time = 0
	var Camera = playerCam
	await nextFrame
	Engine.time_scale = .1
	while  time<shakeTime and shaking == 1:
		if time>0.025:
			Engine.time_scale = 1.0
		Camera.position.x = move_toward(Camera.position.x,sin(time*75)*2,2)
		time+=thisDelta
		await nextFrame
	while  time<shakeTime+shakeTime/4 and shaking == 1:
		Camera.position.x = move_toward(Camera.position.x,0,2)
		time+=thisDelta
		await nextFrame
	shaking-=1
	Engine.time_scale = 1
		
func switchCameraTo(camTo,speed):
	if switchingCamera:
		return
	switchingCamera = true
	var origin = activeCam.global_position
	var originalParent
	if activeCam.get_parent():
		originalParent = activeCam.get_parent()
		var pos = activeCam.global_position
		#activeCam.get_parent().remove_child(activeCam)
		#get_node("/root/World").add_child(activeCam)
		#activeCam.global_position = pos
	while cutsceneActive:
		activeCam.global_position = lerp(activeCam.global_position,camTo.global_position,thisDelta*speed/6)
		await nextFrame
	activeCam.global_position = camTo.global_position
	activeCam.enabled = false
	camTo.enabled = true
	activeCam.global_position = origin
	activeCam = camTo
	bg1.get_parent().remove_child(bg1)
	bg2.get_parent().remove_child(bg2)
	flames.get_parent().remove_child(flames)
	activeCam.add_child(bg1)
	activeCam.add_child(bg2)
	activeCam.add_child(flames)
	bg1.position = Vector2.ZERO
	bg2.position = Vector2.ZERO
	flames.position = Vector2.ZERO
	switchingCamera = false
	
		
func markSaveLocation():
	saveLocation = player.global_position
	saveLocationBG = activeBG
	
func resetWorld():
	get_node("/root/World/Map/ElectricPost").charged=30
	get_node("/root/World/Map/ElectricPost2").charged=30
	switchCameraTo(playerCam,100)
	slimeBossCam.position = Vector2(-358,-23)
	activeBG.visible = false
	saveLocationBG.visible = true
	activeBG = saveLocationBG
	if Keys.slimeBossFight==1:
		Keys.slimeBossFight = 0
		get_node("/root/World/Map/Slimecore").usingAttack = false
		get_node("/root/World/Map/Slimecore/Stats").hp = get_node("/root/World/Map/Slimecore/Stats").maxHP
		get_node("/root/World/Map/Slimecore").global_position = get_node("/root/World/Map/Slimecore").origin
		for slime in get_node("/root/World/Map/Slimecore").spawns:
			slime.queue_free()
		get_node("/root/World/Map/Slimecore").spawns.clear()
		get_node("/root/World/Map/Slimecore").aggro = null
		get_node("/root/World/Map/Slimecore").SPEED = 0
	if Keys.sahagin<1:
		get_node("/root/World/Map/Sahagin1").usingAttack = false
		get_node("/root/World/Map/Sahagin1/Stats").hp = get_node("/root/World/Map/Sahagin1/Stats").maxHP
	if Keys.petalPeltFight<1:
		for petal in get_node("/root/World/Map/PetalPelt").petals:
			petal.visible = true
			petal.scale = Vector2.ONE
		get_node("/root/World/Map/PetalPelt/Stats").hp = get_node("/root/World/Map/PetalPelt/Stats").maxHP
	
func updateSwordColor():
	for obj in get_node("/root/World/Map/SwordUpgrades").get_children():
		obj.get_node("Sprite2D").material.set_shader_parameter("T1",swordColors[Keys.swordStrength()+1])
	player.get_node("Guy").material.set_shader_parameter("T1",swordColors[Keys.swordStrength()])
	ui.get_node("ReceiveCloseup/Receive3").material.set_shader_parameter("T1",swordColors[Keys.swordStrength()]+Color(.1,.1,.1,0))
	ui.get_node("ReceiveCloseup/Receive3").material.set_shader_parameter("T2",swordColors[Keys.swordStrength()])
	ui.get_node("ReceiveCloseup/Receive3").material.set_shader_parameter("T3",swordColors[Keys.swordStrength()]+Color(.05,.05,.05,0))
	ui.get_node("ReceiveCloseup/Receive3").material.set_shader_parameter("T4",swordColors[Keys.swordStrength()]-Color(.1,.1,.1,0))
	ui.get_node("ReceiveCloseup/Receive3").material.set_shader_parameter("T5",swordColors[Keys.swordStrength()]-Color(.5,.5,.5,0))

func updateCurrentItem():
	ui.get_node("Chakram").visible = false
	ui.get_node("Axe").visible = false
	ui.get_node("Knife").visible = false
	ui.get_node("BowArrow").visible = false
	ui.get_node("TetherShot").visible = false
	if currentItem != "none":
		ui.get_node(currentItem).visible = true
	else:
		pass

func checkNoItems():
	var noItems = true
	for n in Keys.items:
		if n == 1:
			noItems = false
			return false
	return true

func iterateCurrentItem():
	if checkNoItems():
		currentItem = "none"
		updateCurrentItem()
		return
	currentItemIndex+=1
	if currentItemIndex>=Keys.items.size():
		currentItemIndex = 0
	if Keys.items[currentItemIndex] == 1:
		match currentItemIndex:
			0:
				currentItem = "Chakram"
			1:
				currentItem = "Axe"
			2:
				currentItem = "Knife"
			3:
				currentItem = "BowArrow"
			4:
				currentItem = "TetherShot"
		print("item found, matched to "+currentItem)
		updateCurrentItem()
	else:
		iterateCurrentItem()

func updateBackgrounds():
	bg1.visible = false
	bg2.visible = false
	activeBG.visible = true
