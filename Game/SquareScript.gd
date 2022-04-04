extends Sprite

var is_fading_out: bool = false

func _ready():
	modulate.a = 2.0

func _process(delta):
	if is_fading_out:
		modulate.a -= delta * 2
		if modulate.a < 0:
			set_process(false)
			queue_free()
	else:
		modulate.a -= delta
		if modulate.a < 1:
			modulate.a = 1
			set_process(false)

func fadeout_and_destroy():
	modulate.a = 1.0
	is_fading_out = true
	set_process(true)
