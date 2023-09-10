extends GPUParticles2D
# Called when the node enters the scene tree for the first time.
@export var viewportTexture : bool
func _ready():
	if !viewportTexture:
		texture = get_parent().texture

func _physics_process(delta):
	if get_parent().flip_h:
		process_material.set_shader_parameter("flipx",-1.0)
	else:
		process_material.set_shader_parameter("flipx",1.0)
	process_material.set_shader_parameter("tex_anim_offset",(get_parent().frame+0.0)/(get_parent().hframes-1))
