extends Node

var right = false
var left = false
var jump = false
var up = false
var down = false
var tapUp = false
var tapDown = false
var tapJump = false
var attack = false
var extraAction = false
var swap = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var inputs = ""
	if Input.is_action_pressed("right"):
		right = true
		inputs += "right, "
	else:
		right = false
	if Input.is_action_pressed("left"):
		left = true
		inputs += "left, "
	else:
		left = false	
	if Input.is_action_pressed("up"):
		up = true
		inputs += "up, "
	else:
		up = false	
	if Input.is_action_pressed("down"):
		down = true
		inputs += "down, "
	else:
		down = false	
	if Input.is_action_just_pressed("up"):
		tapUp = true
		inputs += "tapUp, "
	else:
		tapUp = false	
	if Input.is_action_just_pressed("down"):
		tapDown = true
		inputs += "tapDown, "
	else:
		tapDown = false	
	if Input.is_action_pressed("jump"):
		jump = true
		inputs += "jump, "
	else:
		jump = false	
	if Input.is_action_just_pressed("jump"):
		tapJump = true
		inputs += "tapJump, "
	else:
		tapJump = false	
	if Input.is_action_just_pressed("attack"):
		attack = true
		inputs += "attack, "
	else:
		attack = false	
	if Input.is_action_just_pressed("extraAction"):
		extraAction = true
		inputs += "extraAction, "
	else:
		extraAction = false	
	if Input.is_action_just_pressed("swap"):
		swap = true
		inputs += "swap, "
	else:
		swap = false	
	#print("Inputs: "+inputs)

