extends Node2D

@export var spawn_distance: float = 100.0

var wave_count: int = 1
var enemy_count: int = 1
var enemies_alive: Array = []

@onready var player: CharacterBody2D = $Player
@onready var wave_count_label: Label = $HUDLayer/HUD/WaveCount

const ENEMY = preload("uid://hcqr7kri8smf")

func spawn_wave():
	enemy_count = int(
		5 +
		wave_count * 1.5 +
		pow(wave_count, 1.2) +
		player.player_level * 2
	)
		
	for i in range(enemy_count):
		var enemy_scene = ENEMY.instantiate()
		enemy_scene.died.connect(_on_enemy_died.bind(enemy_scene))
		get_tree().current_scene.add_child(enemy_scene)
		
		var viewport_size = get_viewport_rect().size
		var camera = get_viewport().get_camera_2d()
		var center = camera.global_position
		var left = center.x - viewport_size.x / 2
		var right = center.x + viewport_size.x / 2
		var top = center.y - viewport_size.y / 2
		var bottom = center.y + viewport_size.y / 2
		var side = randi() % 4
		
		var spawn_pos = Vector2.ZERO
		match side:
			0:
				spawn_pos.x = randf_range(left, right)
				spawn_pos.y = top - spawn_distance
			1:
				spawn_pos.x = randf_range(left, right)
				spawn_pos.y = bottom + spawn_distance
			2:
				spawn_pos.x = left - spawn_distance
				spawn_pos.y = randf_range(top, bottom)
			3:
				spawn_pos.x = right + spawn_distance
				spawn_pos.y = randf_range(top, bottom)
		enemy_scene.global_position = spawn_pos
		
		enemies_alive.append(enemy_scene)
	

func _ready() -> void:
	spawn_wave()

func _process(delta: float) -> void:
	if enemies_alive.size() <= 0:
		wave_count += 1
		spawn_wave()
	
	wave_count_label.text = str(wave_count)

func _on_enemy_died(enemy):
	enemies_alive.erase(enemy)
	
	if enemies_alive.is_empty():
		wave_count += 1
		spawn_wave()
