extends Node

#abilities
var canWalljump = false
var canBackdash = false
var canDiveKick = false
var slimeBossFight = 0
var swords = [0,0,0,0,0,0,0,0,0,0]
var items = [1,0,0,0,0]
var stickyGlove = false
var sahagin = 0
#item 0 : Chakram
#item 1 : Axe
#item 2 : Knife
#item 3 : Bow & Arrow
#item 4 : Tether Shot

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func swordStrength():
	var str = 0
	for s in swords:
		str = str + s
	return str
