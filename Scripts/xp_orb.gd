extends Sprite2D

var orb_xp_value: float = 1.0

func _on_xp_orb_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.add_xp(orb_xp_value)
		queue_free()
