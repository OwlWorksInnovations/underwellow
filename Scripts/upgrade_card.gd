extends Button

@onready var title_label: Label = $MarginContainer/VBoxContainer/UpgradeTitle
@onready var description_label: Label = $MarginContainer/VBoxContainer/UpgradeDescription
@onready var stats_label: Label = $MarginContainer/VBoxContainer/UpgradeStats

var upgrade_data: Dictionary

func setup(data: Dictionary) -> void:
	upgrade_data = data
	title_label.text = data["title"]
	description_label.text = data["description"]
	stats_label.text = data["stats"]
