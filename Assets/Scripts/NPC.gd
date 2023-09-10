extends Node2D


@export var interaction = 0 #0:Dialogue,
@export var dialogueTreeKey = 0
@export var dialogueTrees = {}
@export var printSound = ""
var talking = false
@export var targetOnTouch: bool

signal nextFrame

func _ready():
	if get_parent().name=="Zorloro":
		get_parent().get_node("AnimationPlayer").play("stand")
	
func _physics_process(delta):
	if name ==  "GeneralText":
		return
	if  get_parent().get_overlapping_bodies().size()==0 and TextEngine.target:
		if TextEngine.target == self:
			print("left")
			TextEngine.target = null
	elif get_parent().get_overlapping_bodies().size()>0 and !TextEngine.target:
		if get_parent().get_overlapping_bodies()[0].name!="Player":
			print("bitcalsfdasdfjk")
			return
		if get_parent().name == "SlimeBoss" and Keys.slimeBossFight==0:
			print("gocut")
			slimeBossEnter(General.player)
			return
		if targetOnTouch:
			TextEngine.target = self
		get_node("/root/World/TextPrinter").stream = load("res://Assets/SFX/signText.wav")
		get_node("/root/World/TextPrinter").stream = load(printSound)
	nextFrame.emit()

func slimeBossEnter(body):
	print("enter arena")
	if body.name=="Player" and Keys.slimeBossFight == 0:
		Keys.slimeBossFight=1
		get_node("/root/World/TextPrinter").stream = load("res://Assets/SFX/signText.wav")
		General.cutsceneActive = true
		General.switchCameraTo(get_parent().get_node("Camera2D"),2)
		await get_tree().create_timer(.8).timeout
		TextEngine.go(self)
		while (TextEngine.messageStatus):
			await nextFrame
		General.cutsceneActive = false

