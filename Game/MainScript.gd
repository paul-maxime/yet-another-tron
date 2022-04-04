extends Node2D

const SQUARE_SIZE = 10

var socket: WebSocketClient = WebSocketClient.new()
var is_connected: bool = false
var last_direction: int = -1

var squares: Array
var square_scene = preload("res://Square.tscn")

var my_id = 0

var colors = [
	Color("F40404"),
	Color("0C48CC"),
	Color("2CB494"),
	Color("88409C"),
	Color("F88C14"),
	Color("703014"),
	Color("CCE0D0"),
	Color("FCFC38"),
	Color("088008"),
	Color("FCFC7C"),
	Color("ECC4B0"),
	Color("4068D4"),
]

func _ready():
	var _result
	_result = socket.connect("connection_closed", self, "_closed")
	_result = socket.connect("connection_error", self, "_closed")
	_result = socket.connect("connection_established", self, "_connected")
	_result = socket.connect("data_received", self, "_on_data")
	connect_to_server()
	$MusicPlayer.play()

func connect_to_server():
	var _err = socket.connect_to_url("ws://127.0.0.1:8080" if OS.is_debug_build() else "wss://tron.paulmaxime.fr/ws")

func _process(_delta: float):
	process_inputs()
	socket.poll()

func _connected(_proto = ""):
	print("Connected")
	is_connected = true
	my_id = 0

func _closed(_was_clean = false):
	print("Disconnected")
	is_connected = false
	connect_to_server()

func _on_data():
	var raw_string = socket.get_peer(1).get_packet().get_string_from_utf8()
	var message = JSON.parse(raw_string)
	if message.result.type == "map":
		for square in $Squares.get_children():
			square.queue_free()
		for x in range(0, message.result.map.size()):
			for y in range(0, message.result.map[x].size()):
				if message.result.map[x][y] != 0:
					create_square(message.result.map[x][y], x, y)
	if message.result.type == "move":
		create_square(message.result.id, message.result.x, message.result.y)
	if message.result.type == "clear":
		for square in $Squares.get_children():
			if square.get_meta("id") == message.result.id:
				square.fadeout_and_destroy()
	if message.result.type == "spawn":
		if my_id != 0:
			restart_music()
			$BoomPlayer.play()
		last_direction = -1
		my_id = message.result.id

func process_inputs():
	var _result
	if Input.is_action_pressed("move_up") && last_direction != 0:
		last_direction = 0
		_result = socket.get_peer(1).put_packet("{\"direction\":0}".to_utf8())
		return
	if Input.is_action_pressed("move_down") && last_direction != 1:
		last_direction = 1
		_result = socket.get_peer(1).put_packet("{\"direction\":1}".to_utf8())
		return
	if Input.is_action_pressed("move_left") && last_direction != 2:
		last_direction = 2
		_result = socket.get_peer(1).put_packet("{\"direction\":2}".to_utf8())
		return
	if Input.is_action_pressed("move_right") && last_direction != 3:
		last_direction = 3
		_result = socket.get_peer(1).put_packet("{\"direction\":3}".to_utf8())
		return

func create_square(id: int, x: int, y: int):
	var square: Node2D = square_scene.instance()
	square.set_meta("id", id)
	square.position = Vector2(x * SQUARE_SIZE, y * SQUARE_SIZE)
	square.modulate = colors[id % colors.size()]
	$Squares.add_child(square)

func restart_music():
	$MusicPlayer.volume_db = -36
	$MusicPlayer/Tween.interpolate_property($MusicPlayer, "volume_db", -36, -6, 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$MusicPlayer/Tween.start()
