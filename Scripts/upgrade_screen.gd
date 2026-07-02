extends Control

signal upgrade_selected(upgrade_data: Dictionary)

@onready var cards := [
	$PanelContainer/VBoxContainer/HBoxContainer/UpgradeCard1,
	$PanelContainer/VBoxContainer/HBoxContainer/UpgradeCard2,
	$PanelContainer/VBoxContainer/HBoxContainer/UpgradeCard3
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	for card in cards:
		card.pressed.connect(_on_card_pressed.bind(card))

func show_upgrades(upgrades: Array) -> void:
	visible = true

	for i in cards.size():
		cards[i].setup(upgrades[i])

func _on_card_pressed(card) -> void:
	visible = false
	upgrade_selected.emit(card.upgrade_data)
