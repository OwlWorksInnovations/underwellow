extends CharacterBody2D

@export var player_health: float = 100.0
@export var player_max_health: float = 100.0
@export var player_xp = 0.0
@export var player_required_xp = 10.0
@export var player_damage = 8.0
@export var speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1200.0
@export var fire_rate: float = 3
@export var dash_range: float = 150.0
@export var dash_time: float = 0.12
@onready var player_camera: Camera2D = $PlayerCamera
@onready var player_health_bar: ProgressBar = $PlayerHealthBar
@onready var xp_bar: ProgressBar = $"../HUDLayer/HUD/XPBar"
@onready var upgrade_screen: Control = $"../HUDLayer/UpgradeScreen"
const BULLET = preload("uid://dwip3ijh1koty")
var enemies_in_range: Array[Node2D] = []
var can_shoot: bool = true
var is_dashing := false

func add_xp(amount: float):
	player_xp += amount

func player_died() -> void:
	get_tree().call_deferred("reload_current_scene")

func take_damage(damage) -> void:
	player_health -= damage
	
	if player_health <= 0:
		player_died()
		
func shoot() -> void:
	if not can_shoot:
		return
		
	can_shoot = false
	var bullet = BULLET.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.bullet_damage = player_damage
	bullet.global_position = global_position

	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	bullet.direction = direction
	bullet.rotation = direction.angle()
	
	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_shoot = true

func dash() -> void:
	if is_dashing:
		player_camera.position_smoothing_speed = 1.0
		return
	
	is_dashing = true
	player_camera.position_smoothing_speed = 10.0
	
	var mouse_pos = get_global_mouse_position()
	var direction = global_position.direction_to(mouse_pos)
	
	var target_pos = global_position + direction * dash_range
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, dash_time)
	tween.finished.connect(func():
		is_dashing = false
	)
	
func level_up() -> void:
	get_tree().paused = true
	var upgrades := [
		{
			"title": "Damage Up",
			"description": "Bullets deal more damage.",
			"stats": "+200 Damage",
			"type": "damage",
			"amount": 200
		},
		{
			"title": "Fire Rate",
			"description": "Shoot faster.",
			"stats": "+20% Fire Rate",
			"type": "fire_rate",
			"amount": 0.2
		},
		{
			"title": "Health Up",
			"description": "Increase max health.",
			"stats": "+20 HP",
			"type": "health",
			"amount": 20
		}
	]

	upgrade_screen.show_upgrades(upgrades)

func _ready() -> void:
	player_health_bar.max_value = player_max_health
	player_health_bar.value = player_health
	
	xp_bar.max_value = player_required_xp
	xp_bar.value = player_xp
	
	upgrade_screen.upgrade_selected.connect(_on_upgrade_selected)

func _physics_process(delta: float) -> void:
	# update health & xp bar
	player_health_bar.value = player_health
	xp_bar.value = player_xp
	
	# shooting
	if enemies_in_range.size() > 0:
		shoot()
	
	# level up
	if player_xp >= player_required_xp:
		player_required_xp = player_required_xp * 2
		level_up()
	
	# debug
	if Input.is_action_just_pressed("ui_accept"):
		level_up()
	
	# dash
	if Input.is_action_just_pressed("dash"):
		dash()
	
	# movement
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move_and_slide()

func _on_player_auto_shoot_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and not enemies_in_range.has(body):
		enemies_in_range.append(body)

func _on_player_auto_shoot_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		enemies_in_range.erase(body)
		
func _on_upgrade_selected(upgrade: Dictionary) -> void:
	match upgrade["type"]:
		"damage":
			player_damage += upgrade["amount"]
		
		"fire_rate":
			fire_rate += upgrade["amount"]

		"max_health":
			player_max_health += upgrade["amount"]
	
	get_tree().paused = false
