extends CharacterBody2D

signal died()

@export var enemy_health: float = 30.0
@export var enemy_max_health: float = 30.0
@export var enemy_attack_damage: float = 10.0
@export var enemy_attack_cooldown: float = 1.0
@export var speed: float = 100.0
@export var acceleration: float = 400.0
@export var friction: float = 1200.0
@export var stop_distance: float = 24.0
@onready var player: CharacterBody2D = $"../Player"
@onready var enemy_healthbar: ProgressBar = $EnemyHealthbar
const XP_ORB = preload("uid://7k8licgp0her")
var player_in_range: CharacterBody2D = null
var can_attack: bool = true

func take_damage(damage: float) -> void:
	enemy_health -= damage
	
	if enemy_health <= 0:
		die()

func die() -> void:
	var xp_orb = XP_ORB.instantiate()
	get_tree().current_scene.add_child(xp_orb)
	xp_orb.global_position = global_position
	xp_orb.orb_xp_value = enemy_max_health / 10
	
	died.emit()
	queue_free()
	
func attack(body: Node2D) -> void:
	if not can_attack:
		return
	
	if body.is_in_group("Player"):
		body.take_damage(enemy_attack_damage)
		can_attack = false
		await get_tree().create_timer(enemy_attack_cooldown).timeout
		can_attack = true
		
		if player_in_range != null:
			attack(player_in_range)

func _ready() -> void:
	enemy_healthbar.max_value = enemy_max_health
	enemy_healthbar.value = enemy_health

func _physics_process(delta: float) -> void:
	# update health bar
	enemy_healthbar.value = enemy_health
	
	# movement
	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance <= stop_distance:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		var direction = to_player.normalized()
		var target_velocity = direction * speed
		
		velocity = velocity.move_toward(
			target_velocity,
			acceleration * delta
		)

	move_and_slide()


func _on_enemy_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = body
		attack(player_in_range)

func _on_enemy_attack_range_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
