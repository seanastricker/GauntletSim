extends CharacterBody2D

@export var npc_name: String = "NPC"
@export var dialogue: String = "Hello, player!"

@onready var name_label = $NameLabel
@onready var dialogue_label = $DialogueLabel
@onready var interaction_prompt = $InteractionPrompt
@onready var area = $Area2D
@onready var animated_sprite = $AnimatedSprite2D

var player_in_range = false
var dialogue_timer = Timer.new()
var direction = Vector2(0, 1) # Default to facing down

func _ready():
	name_label.text = npc_name
	dialogue_label.text = dialogue
	interaction_prompt.visible = false
	dialogue_label.visible = false
	
	# Add outlines
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 4)
	
	dialogue_label.add_theme_color_override("font_color", Color(1, 1, 1))
	dialogue_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	dialogue_label.add_theme_constant_override("outline_size", 4)

	interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1))
	interaction_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	interaction_prompt.add_theme_constant_override("outline_size", 4)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	dialogue_timer.wait_time = 3.0
	dialogue_timer.one_shot = true
	dialogue_timer.timeout.connect(_on_dialogue_timer_timeout)
	add_child(dialogue_timer)

func _physics_process(_delta):
	update_animation()

func update_animation():
	var current_velocity = velocity
	
	if current_velocity.length() > 0:
		direction = current_velocity.normalized()
	
	var animation_str = "idle_down" # Default animation
	
	if current_velocity.length() > 0:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animation_str = "walk_right"
			else:
				animation_str = "walk_left"
		else:
			if direction.y > 0:
				animation_str = "walk_down"
			else:
				animation_str = "walk_up"
	else:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animation_str = "idle_right"
			else:
				animation_str = "idle_left"
		else:
			if direction.y > 0:
				animation_str = "idle_down"
			else:
				animation_str = "idle_up"

	# Check for idle animations that might not exist in every spritesheet
	if not animated_sprite.sprite_frames.has_animation(animation_str):
		if "idle" in animation_str:
			# If specific idle animation doesn't exist, fall back to a default idle
			if animated_sprite.sprite_frames.has_animation("idle_down"):
				animation_str = "idle_down"
			elif animated_sprite.sprite_frames.has_animation("idle_up"):
				animation_str = "idle_up"
			else:
				# If no idle animations exist, try a walk animation as a last resort
				animation_str = "walk_down"
		
	animated_sprite.play(animation_str)


func _on_body_entered(body):
	if body.is_in_group("player"):
		# Check if this is the local player (multiplayer-compatible)
		var is_local_player = true
		if body.has_method("get") and body.get("peer_id") != null:
			# This is a MultiplayerPlayer - check if it's the local player
			is_local_player = (body.peer_id == multiplayer.get_unique_id())
		
		if is_local_player:
			player_in_range = true
			interaction_prompt.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		# Check if this is the local player (multiplayer-compatible)
		var is_local_player = true
		if body.has_method("get") and body.get("peer_id") != null:
			# This is a MultiplayerPlayer - check if it's the local player
			is_local_player = (body.peer_id == multiplayer.get_unique_id())
		
		if is_local_player:
			player_in_range = false
			interaction_prompt.visible = false
			dialogue_label.visible = false
			dialogue_timer.stop()

func _unhandled_input(_event):
	if player_in_range and Input.is_action_just_pressed("interact"):
		# Check if the LOCAL player is the one near this NPC (multiplayer-compatible)
		var overlapping_bodies = area.get_overlapping_bodies()
		var local_player_found = false
		
		for body in overlapping_bodies:
			if body.is_in_group("player"):
				# In multiplayer, only respond if the local player is the one interacting
				var is_local_player = true
				if body.has_method("get") and body.get("peer_id") != null:
					# This is a MultiplayerPlayer - check if it's the local player
					is_local_player = (body.peer_id == multiplayer.get_unique_id())
				
				if is_local_player:
					local_player_found = true
					break
		
		# Only show dialogue if the LOCAL player is the one interacting
		if local_player_found:
			dialogue_label.visible = true
			dialogue_timer.start()

func _on_dialogue_timer_timeout():
	dialogue_label.visible = false 