# StreetExit.gd - Handles transition from office to street scene
extends Area2D

# Interaction prompt
@onready var interaction_prompt: Label = $InteractionPrompt

# Visibility tracking
var player_in_area: bool = false
var prompt_visible: bool = false

func _ready():
	"""Initialize the street exit interaction"""
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Hide prompt initially
	interaction_prompt.visible = false

func _input(event):
	"""Handle input for street exit"""
	if event.is_action_pressed("interact") and player_in_area:
		print("Street exit activated!")
		transition_to_street()

func _on_body_entered(body):
	"""Show interaction prompt when player enters"""
	if body.name.begins_with("Player_"):
		print("Player entered street exit area")
		player_in_area = true
		show_prompt()

func _on_body_exited(body):
	"""Hide interaction prompt when player exits"""
	if body.name.begins_with("Player_"):
		print("Player left street exit area")
		player_in_area = false
		hide_prompt()

func show_prompt():
	"""Show the interaction prompt"""
	if not prompt_visible:
		interaction_prompt.visible = true
		prompt_visible = true
		print("Street exit prompt shown")

func hide_prompt():
	"""Hide the interaction prompt"""
	if prompt_visible:
		interaction_prompt.visible = false
		prompt_visible = false
		print("Street exit prompt hidden")

func transition_to_street():
	"""Handle transition to street scene with complete state preservation"""
	print("🚪 Transitioning to street...")
	
	# Find the current scene manager
	var current_scene_manager = get_scene_manager()
	
	# Store complete player state before transitioning
	if current_scene_manager:
		# Collect complete player state from current scene
		var players = current_scene_manager.get_children().filter(func(child): return child.name.begins_with("Player_"))
		for player in players:
			if "peer_id" in player and player.peer_id != null:
				var peer_id = player.peer_id
				
				# Get decay timer remaining time if it exists and is active
				var decay_timer_remaining = 0.0
				if "decay_timer" in player and player.decay_timer != null:
					# Store the remaining time on the timer
					decay_timer_remaining = player.decay_timer.time_left
					print("💾 Storing decay timer remaining time: ", decay_timer_remaining, " seconds for player ", peer_id)
				
				var player_data = {
					"name": player.player_name,
					"sprite_path": player.sprite_path if "sprite_path" in player else "",
					"health": player.health,
					"social": player.social,
					"ccat_score": player.ccat_score,
					"position": player.global_position,
					"scene": "Main",
					"is_eliminated": player.is_eliminated if "is_eliminated" in player else false,
					"game_outcome": player.game_outcome if "game_outcome" in player else "",
					"ui_visible": player.ui_visible if "ui_visible" in player else false,
					"decay_timer_active": player.decay_timer != null if "decay_timer" in player else false,
					"decay_timer_remaining": decay_timer_remaining,  # Store remaining time
					"interaction_cooldowns": player.interaction_cooldowns if "interaction_cooldowns" in player else {},
					"last_direction": player.last_direction if "last_direction" in player else Vector2(0, 1)
				}
				# Store in enhanced system
				PlayerData.store_complete_player_state(peer_id, player_data)
				print("💾 Stored complete state for player ", peer_id, " transitioning to street")
	
	# Sync transition to all players if in multiplayer
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		sync_scene_transition.rpc("Street")
	
	# Change to street scene
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/Street.tscn")
	else:
		print("❌ Error: Cannot access scene tree for transition")

@rpc("authority", "call_local", "reliable")
func sync_scene_transition(target_scene: String):
	"""Sync scene transition to all clients"""
	print("📡 Syncing street transition to all clients")
	
	# Clients should also transition to the street scene
	if not multiplayer.is_server():
		var tree = get_tree()
		if tree:
			tree.change_scene_to_file("res://scenes/Street.tscn")

func get_scene_manager() -> Node:
	"""Find and return the scene manager for the current scene"""
	var scene_root = get_tree().current_scene
	if not scene_root:
		return null
	
	# Look for scene manager nodes
	for child in scene_root.get_children():
		if child.name.ends_with("SceneManager"):
			return child
	
	return null 