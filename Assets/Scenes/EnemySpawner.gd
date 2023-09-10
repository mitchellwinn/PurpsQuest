extends Node2D

@export var toSpawn:String
var toSpawnLoad
@export var maximumAmount: int
@export var alwaysSpawn: bool
var player
var spawns: Array

func _ready():
	player = get_node("/root/World/Player")
	toSpawnLoad = load(toSpawn)

func _physics_process(delta):
	if !alwaysSpawn:
		var i = 0
		for obj in spawns:
				if obj.dead:
					spawns.remove_at(i)
				i+=1
		if (player.global_position-global_position).length()>300 and (player.global_position-global_position).length()<310 and spawns.size()<maximumAmount:
			spawn()
	else:
		var i = 0
		for obj in spawns:
			if obj.dead:
				spawns.remove_at(i)
			i+=1
		if spawns.size()<maximumAmount:
			spawn()

func spawn():
	var thisSpawn = toSpawnLoad.instantiate()
	spawns.append(thisSpawn)
	get_node("/root/World/Map").add_child(thisSpawn)
	thisSpawn.global_position = global_position
	thisSpawn.origin = global_position
