# NPC.gd
extends CharacterBody2D

export var npc_name = "NPC"
export var dialogue = "Hello, player!"

onready var name_label = $NameLabel
onready var interaction_area = $InteractionArea

var player_in_range = false
var dialogue_showing = false
var interaction_label = Label.new()
var dialogue_label = Label.new()
var dialogue_timer = 0

func _ready():
	name_label.text = npc_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 2)

	interaction_label.text = "[E] to talk"
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.position = Vector2(name_label.position.x, name_label.position.y + 30)
	interaction_label.rect_size.x = name_label.rect_size.x
	interaction_label.visible = false
	interaction_label.add_theme_color_override("font_color", Color(1, 1, 1))
	interaction_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	interaction_label.add_theme_constant_override("outline_size", 2)
	add_child(interaction_label)

	dialogue_label.text = dialogue
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_label.position = Vector2(name_label.position.x - 50, name_label.position.y - 30)
	dialogue_label.rect_size.x = 200
	dialogue_label.visible = false
	dialogue_label.add_theme_color_override("font_color", Color(1, 1, 1))
	dialogue_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	dialogue_label.add_theme_constant_override("outline_size", 2)
	add_child(dialogue_label)
	
	interaction_area.connect("body_entered", self, "_on_InteractionArea_body_entered")
	interaction_area.connect("body_exited", self, "_on_InteractionArea_body_exited")

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		show_dialogue()
	
	if dialogue_showing:
		dialogue_timer += delta
		if dialogue_timer > 3:
			hide_dialogue()

func show_dialogue():
	dialogue_showing = true
	dialogue_label.visible = true
	interaction_label.visible = false
	dialogue_timer = 0
	
func hide_dialogue():
	dialogue_showing = false
	dialogue_label.visible = false

func _on_InteractionArea_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if not dialogue_showing:
			interaction_label.visible = true

func _on_InteractionArea_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		interaction_label.visible = false
		hide_dialogue()