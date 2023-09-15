extends Area2D

@export var bgm : String


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	General.markSaveLocation()
	if General.saveTimer<=0:
		General.saveData()
		General.saveTimer=15
	General.bgm = load(bgm)
