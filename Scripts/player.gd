extends CharacterBody2D

@export var player_health: float = 100.0
@export var player_max_health: float = 100.0
@export var player_health_regeneration: float = 10.0
@export var player_xp = 0.0
@export var player_required_xp = 10.0
@export var player_damage = 8.0
@export var speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1200.0
@export var fire_rate: float = 3
@export var dash_range: float = 150.0
@export var dash_time: float = 0.12
@export var aim_cursor_distance: float = 80.0

@onready var player_camera: Camera2D = $PlayerCamera
@onready var player_health_bar: ProgressBar = $PlayerHealthBar
@onready var xp_bar: ProgressBar = $"../HUDLayer/HUD/XPBar"
@onready var upgrade_screen: Control = $"../HUDLayer/UpgradeScreen"
@onready var aim_cursor: Sprite2D = $CursorSprite

const BULLET = preload("uid://dwip3ijh1koty")

var enemies_in_range: Array[Node2D] = []
var can_shoot: bool = true
var is_dashing := false
var can_dash: bool = true
var player_level = 1
var player_can_take_damage: bool = true

var using_controller := false
var last_mouse_pos: Vector2
var mouse_move_deadzone := 0.5
var controller_deadzone := 0.35
var last_aim_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	last_mouse_pos = get_global_mouse_position()

	player_health_bar.max_value = player_max_health
	player_health_bar.value = player_health

	xp_bar.max_value = player_required_xp
	xp_bar.value = player_xp

	upgrade_screen.upgrade_selected.connect(_on_upgrade_selected)

func _physics_process(delta: float) -> void:
	update_aim_input_method()
	update_aim_cursor()

	player_health_bar.value = player_health
	xp_bar.max_value = player_required_xp
	xp_bar.value = player_xp

	if enemies_in_range.size() > 0:
		shoot()

	if player_xp >= player_required_xp:
		player_xp -= player_required_xp
		player_required_xp *= 2
		level_up()
	
	if player_health < player_max_health:
		player_health += player_health_regeneration * delta
		player_health = min(player_health, player_max_health)
	
	if Input.is_action_just_pressed("ui_accept"):
		level_up()

	if Input.is_action_just_pressed("dash"):
		if can_dash:
			dash()

	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

func get_controller_aim() -> Vector2:
	var aim = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)

	if aim.length() < controller_deadzone:
		return Vector2.ZERO

	return aim.normalized()

func update_aim_input_method() -> void:
	var current_mouse_pos = get_global_mouse_position()

	if current_mouse_pos.distance_to(last_mouse_pos) > mouse_move_deadzone:
		using_controller = false

	last_mouse_pos = current_mouse_pos

	var aim = get_controller_aim()

	if aim != Vector2.ZERO:
		using_controller = true
		last_aim_direction = aim

func get_aim_direction() -> Vector2:
	if using_controller:
		return last_aim_direction

	return (get_global_mouse_position() - global_position).normalized()

func update_aim_cursor() -> void:
	var direction = get_aim_direction()

	aim_cursor.visible = true

	if using_controller:
		aim_cursor.global_position = global_position + direction * aim_cursor_distance
	else:
		aim_cursor.global_position = get_global_mouse_position()

func add_xp(amount: float):
	player_xp += amount

func player_died() -> void:
	get_tree().call_deferred("reload_current_scene")

func take_damage(damage) -> void:
	if player_can_take_damage:
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

	var direction = get_aim_direction()

	bullet.direction = direction
	bullet.rotation = direction.angle()

	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_shoot = true

func dash_iframe():
	player_can_take_damage = false
	await get_tree().create_timer(1.0).timeout
	player_can_take_damage = true

func dash() -> void:
	if is_dashing:
		player_camera.position_smoothing_speed = 1.0
		return
	
	dash_iframe()
	is_dashing = true
	player_camera.position_smoothing_speed = 10.0

	var direction = get_aim_direction()
	var target_pos = global_position + direction * dash_range

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, dash_time)
	tween.finished.connect(func():
		is_dashing = false
	)
	
	can_dash = false
	await get_tree().create_timer(1).timeout
	can_dash = true

func level_up() -> void:
	player_level += 1
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
			"type": "max_health",
			"amount": 20
		}
	]

	upgrade_screen.show_upgrades(upgrades)

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
			player_health = player_max_health

	get_tree().paused = false
