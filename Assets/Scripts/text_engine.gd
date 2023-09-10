extends Node2D

signal done
signal next
var messageStatus = false
var target = null
@onready var currentTrack = get_node("/root/World/Music").stream
var NPC
@onready var ui = get_node("/root/World/UI")
@onready var defaultTextWidth = ui.get_node("TextBox/Text").size
@onready var defaultTextPos = ui.get_node("TextBox/Text").position
var face = null


func _physics_process(delta):
	if target:
		if PlayerInputs.attack && !messageStatus:
			go(target)
		elif (PlayerInputs.attack or PlayerInputs.jump) && messageStatus:
			next.emit()
	elif (PlayerInputs.attack or PlayerInputs.jump) && messageStatus:
			next.emit()

func go(npc):
	if !face:
			ui.get_node("TextBox/Face").visible = false
			ui.get_node("TextBox/Text").size = defaultTextWidth
			ui.get_node("TextBox/Text").position = defaultTextPos 
	currentTrack = get_node("/root/World/Music").stream
	NPC = npc
	messageStatus = true
	npc.talking = true
	ui.get_node("TextBox/Text").visible_ratio = 0
	await ui.get_node("TextBox").appear(.2)
	var tree = npc.dialogueTrees[npc.dialogueTreeKey]
	for i in tree.size():
		if checkForCommands(tree[i],npc):
			continue
		if face:
			ui.get_node("TextBox/Face").texture = load("res://Assets/2D/"+face+".png")
			ui.get_node("TextBox/Face").visible = true
			ui.get_node("TextBox/Text").size.x = 390
			ui.get_node("TextBox/Text").position.x = -160
		else:
			ui.get_node("TextBox/Face").visible = false
			ui.get_node("TextBox/Text").size = defaultTextWidth
			ui.get_node("TextBox/Text").position = defaultTextPos 
		ui.get_node("TextBox/Text").text = tree[i]
		ui.get_node("TextBox/Text").visible_ratio = 0
		await get_tree().create_timer(.02).timeout
		while ui.get_node("TextBox/Text").visible_ratio<1:
			ui.get_node("TextBox/Text").visible_ratio += 0.02
			if !get_node("/root/World/TextPrinter").playing:
				get_node("/root/World/TextPrinter").play()
			await get_tree().create_timer(.02).timeout
		await next
	await ui.get_node("TextBox").disappear(.2)
	npc.talking = false
	messageStatus = false
	if get_node("/root/World/Music").stream != General.currentTrack:
		get_node("/root/World/Music").stream = General.currentTrack
		get_node("/root/World/Music").play()
	
func checkForCommands(line,npc):
	if line.substr(0,5)=="/song":
		var songName = line.substr(6,-1)
		get_node("/root/World/Music").stream = load(songName)
		get_node("/root/World/Music").seek(0)
		get_node("/root/World/Music").play()
		return true
	elif line.substr(0,5)=="/cuts":
		var cutscene = line.substr(6,-1)
		get_node("/root/World/Cutscenes").play(cutscene)
		return true
	elif line.substr(0,5)=="/gold":
		var amount = int(line.substr(6,-1))
		#give player 200 gold
		return true
	elif line.substr(0,5)=="/tree":
		var index = int(line.substr(6,-1))
		npc.dialogueTreeKey = index
		return true
	elif line.substr(0,5)=="/face":
		var linee= str(line.substr(6,-1))
		if linee=="none":
			face = null
		else:
			face = linee
		return true
	elif line.substr(0,5)=="/keyt":
		var linee= str(line.substr(6,-1))
		if linee=="canDiveKick":
			Keys.canDiveKick = true
		return true
	return false
	
func _ready():
	awaitDone()
	

func awaitDone():
	await done
	await ui.get_node("TextBox").disappear(.2)
	if !messageStatus:
		return
	messageStatus = false
	if NPC:
		NPC.talking = false
	if get_node("/root/Game/Music").stream != General.currentTrack:
		get_node("/root/Game/Music").stream = General.currentTrack
		get_node("/root/Game/Music").play()
	awaitDone()
