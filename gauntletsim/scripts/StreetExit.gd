# StreetExit.gd - Handles transition from office to street scene
extends Area2D

@onready var interaction_prompt: Label = $InteractionPrompt

func _ready():
	"""Initialize the street exit interaction"""
	# Style the interaction prompt
	interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1))
	interaction_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	interaction_prompt.add_theme_constant_override("outline_size", 4)
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	"""Show interaction prompt when player enters the exit area"""
	if body.is_in_group("player"):
		# Check if this is the local player (multiplayer-compatible)
		var is_local_player = true
		if body.has_method("get") and body.get("peer_id") != null:
			# This is a MultiplayerPlayer - check if it's the local player
			is_local_player = (body.peer_id == multiplayer.get_unique_id())
		
		if is_local_player:
			interaction_prompt.visible = true

func _on_body_exited(body):
	"""Hide interaction prompt when player exits the exit area"""
	if body.is_in_group("player"):
		# Check if this is the local player (multiplayer-compatible)
		var is_local_player = true
		if body.has_method("get") and body.get("peer_id") != null:
			# This is a MultiplayerPlayer - check if it's the local player
			is_local_player = (body.peer_id == multiplayer.get_unique_id())
		
		if is_local_player:
			interaction_prompt.visible = false

func _process(_delta):
	"""Handle interaction input"""
	if interaction_prompt.visible and Input.is_action_just_pressed("interact"):
		var bodies = get_overlapping_bodies()
		var local_player_found = false
		
		for body in bodies:
			if body.is_in_group("player"):
				# Check if this is the local player (multiplayer-compatible)
				var is_local_player = true
				if body.has_method("get") and body.get("peer_id") != null:
					# This is a MultiplayerPlayer - check if it's the local player
					is_local_player = (body.peer_id == multiplayer.get_unique_id())
				
				if is_local_player:
					local_player_found = true
					transition_to_street()
					break
		
		# Only proceed if the LOCAL player is the one interacting
		if local_player_found:
			interaction_prompt.visible = false

func transition_to_street():
	"""Handle the transition to the street scene"""
	print("Transitioning to street scene...")
	
	# Store current player data before transitioning
	var current_scene_manager = get_tree().current_scene.find_child("MainSceneManager")
	if current_scene_manager:
		# Collect all player data from current scene
		var players = current_scene_manager.get_children().filter(func(child): return child.name.begins_with("Player_"))
		for player in players:
			if player.has_method("get_player_data"):
				var peer_id = player.peer_id
				var player_data = {
					"name": player.player_name,
					"sprite_path": player.get("sprite_path", ""),
					"health": player.health,
					"social": player.social,
					"ccat_score": player.ccat_score
				}
				PlayerData.store_player_data(peer_id, player_data)
	
	# Change to street scene
	get_tree().change_scene_to_file("res://scenes/Street.tscn") 