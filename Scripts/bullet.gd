extends Area2D

@export var bullet_damage: float = 8.0
@export var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		body.take_damage(bullet_damage)
		queue_free()

func _on_bullet_visible_on_screen_notifier_screen_exited() -> void:
	queue_free()
