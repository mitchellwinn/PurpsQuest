extends Area2D

signal nextFrame

@export var swordIndex: int
@export var item: String

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	nextFrame.emit()


func _on_body_entered(body):
	if body.name == "Player" and get_parent().name=="SwordUpgrades":
		Keys.swords[swordIndex]=1
		itemGetCutscene("Receive")
		await get_tree().create_timer(4).timeout
		General.animatorOn = false
		body.get_node("AnimationPlayer").play("swordUpgrade")
		await get_tree().create_timer(1.0).timeout
		General.cutsceneActive = false
		General.animatorOn = true
	elif body.name == "Player" and item=="StickyGlove":
		Keys.stickyGlove=true
		itemGetCutscene("ReceiveGlove")
		await get_tree().create_timer(3.5).timeout
		General.cutsceneActive = false
	elif body.name == "Player" and item=="Axe":
		Keys.items[1]=1
		itemGetCutscene("ReceiveAxe")
		await get_tree().create_timer(3.5).timeout
		General.cutsceneActive = false
	elif body.name == "Player" and item=="Chakram":
		Keys.items[0]=1
		itemGetCutscene("ReceiveChakram")
		await get_tree().create_timer(3.5).timeout
		General.cutsceneActive = false
	if General.checkNoItems():
		General.iterateCurrentItem()
	if Keys.itemCount()==1 and item != "SitckyGlove" and get_parent().name!="SwordUpgrades":
		get_node("/root/World/GeneralText").interaction = 0
		get_node("/root/World/GeneralText").dialogueTreeKey= 1
		get_node("/root/World/TextPrinter").stream = load("res://Assets/SFX/signText.wav")
		TextEngine.go(get_node("/root/World/GeneralText"))
	if Keys.swordStrength()==1 and get_parent().name=="SwordUpgrades":
		get_node("/root/World/GeneralText").interaction = 0
		get_node("/root/World/GeneralText").dialogueTreeKey= 2
		get_node("/root/World/TextPrinter").stream = load("res://Assets/SFX/signText.wav")
		TextEngine.go(get_node("/root/World/GeneralText"))
	queue_free()
		
func itemGetCutscene(itemAnimation):
	#print("OKAY")
		General.cutsceneActive = true
		var timer = 0
		while timer < 1:
			$Sprite2D.position.y-=(1-timer)*.75
			timer+=General.thisDelta
			await nextFrame
		General.ui.get_node("AnimationPlayer").play(itemAnimation)
		await nextFrame
		General.updateSwordColor()
		$Sprite2D.visible = false
		print("gp")
		
