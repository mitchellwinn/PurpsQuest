extends Node

@export var maxHP: int
@export var hp: int
@export var maxMP: int
@export var mp: float
@export var damage: int

func _physics_process(delta):
	
	mp+=delta
	if mp>maxMP:
		mp = maxMP
	if mp<0:
		mp = 0
