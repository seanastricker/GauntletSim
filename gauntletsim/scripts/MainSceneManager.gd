# MainSceneManager.gd - Manages multiplayer players in the main game scene
# Now uses GameStateManager for timer and game state management
extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

# Spawn positions for different players
var spawn_positions = [
	Vector2(22, 306),   # Host spawn position
	Vector2(50, 306),   # Player 2 spawn (offset right)
	Vector2(78, 306),   # Player 3 spawn (offset right more)
	Vector2(106, 306)   # Player 4 spawn (offset right most)
]

# Track if client failed to spawn initially due to missing data
var client_spawn_failed = false

# Game End Window
var game_end_window: Control
const GAME_END_WINDOW_SCENE = preload("res://scenes/GameEndWindow.tscn")

# Scene transition tracking
var is_entering_from_transition: bool = false

func _ready():
	"""Initialize the main scene with multiplayer support"""
	print("MainSceneManager initializing...")
	
	# Check if this is a scene transition or new game start
	is_entering_from_transition = GameStateManager.is_session_active()
	
	if not is_entering_from_transition:
		# New game start - clear previous data and initialize
		PlayerData.clear_all_player_results()
		print("🧹 Cleared previous game results")
		
		# Initialize GameStateManager for new game
		GameStateManager.initialize_for_main_scene()
	else:
		# Scene transition - preserve existing game state
		print("🔄 Entering from scene transition - preserving game state")
		GameStateManager.initialize_for_scene_transition()
	
	# Setup multiplayer callbacks
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Connect to PlayerData signal for retry spawning
	PlayerData.player_registry_updated.connect(_on_player_registry_updated)
	
	# Connect to GameStateManager signals
	GameStateManager.game_timer_ended.connect(_on_game_ended)
	
	# Setup game end window
	setup_game_end_window()
	
	# Check if we have an active multiplayer session
	if multiplayer.has_multiplayer_peer() and PlayerData.get_all_players().size() > 0:
		# Multiplayer mode
		if multiplayer.is_server():
			print("Server: Spawning all players...")
			call_deferred("spawn_all_players")
		else:
			print("Client: Waiting for server...")
	else:
		# Single-player fallback mode
		print("Single-player mode - creating fallback player")
		call_deferred("create_fallback_host_player")

func spawn_all_players():
	"""Spawn all registered players on server and sync to all clients"""
	var all_players = PlayerData.get_all_players()
	print("Spawning players: ", all_players.keys())
	
	# CRITICAL: Broadcast player data to all clients first
	print("Broadcasting player registry to clients...")
	
	# Debug: Show what player data server is broadcasting
	print("🔍 SERVER PLAYER DATA DEBUG (before broadcast):")
	for peer_id in all_players.keys():
		var player_data = all_players[peer_id]
		print("  - Peer ", peer_id, ": ", player_data.get("name", "NO_NAME"), " (", player_data.get("sprite_path", "NO_SPRITE"), ")")
	
	PlayerData.broadcast_player_registry()
	
	# Wait longer for the broadcast to reach all clients
	await get_tree().create_timer(0.2).timeout
	print("Player data broadcast complete, now spawning...")
	
	# Spawn all players locally on server
	for peer_id in all_players.keys():
		spawn_player_local(peer_id)
	
	# Tell all clients to spawn the same players
	spawn_all_players_on_clients.rpc()
	
	# Start the game timer after players are spawned (if this is a new game)
	call_deferred("start_game_timer_if_needed")

@rpc("authority", "call_local", "reliable")
func spawn_all_players_on_clients():
	"""Spawn all registered players on clients"""
	var node_type = "server" if multiplayer.is_server() else "client"
	print("🌍 spawn_all_players_on_clients() called on ", node_type)
	
	var all_players = PlayerData.get_all_players()
	print("🌍 ", node_type, " has player data: ", all_players.keys())
	
	# On client: verify we have valid player data before spawning
	if not multiplayer.is_server():
		if all_players.is_empty():
			print("⚠️ Client has no player data yet, will retry when data arrives")
			client_spawn_failed = true
			return
		
		# Verify we have data for the host (Player 1)
		var host_data = PlayerData.get_player_data(1)
		if host_data.is_empty():
			print("⚠️ Client missing host player data, will retry when data arrives")
			client_spawn_failed = true
			return
		
		# Debug: Show what player data we actually have
		print("🔍 CLIENT PLAYER DATA DEBUG:")
		for peer_id in all_players.keys():
			var player_data = all_players[peer_id]
			print("  - Peer ", peer_id, ": ", player_data.get("name", "NO_NAME"), " (", player_data.get("sprite_path", "NO_SPRITE"), ")")
	
	# Spawn all players
	for peer_id in all_players.keys():
		spawn_player_local(peer_id)
	
	# Mark spawn as successful for client
	if not multiplayer.is_server():
		client_spawn_failed = false

func _on_player_registry_updated():
	"""Called when PlayerData registry is updated - retry spawning if it failed before"""
	if not multiplayer.is_server() and client_spawn_failed:
		print("🔄 Player registry updated, retrying spawn...")
		spawn_all_players_on_clients()

func spawn_player_local(peer_id: int):
	"""Spawn a specific player locally"""
	var node_type = "server" if multiplayer.is_server() else "client"
	print("🎭 spawn_player_local() called on ", node_type, " for peer ", peer_id)
	
	# Check if player already exists
	var existing_player = get_node_or_null("Player_" + str(peer_id))
	if existing_player:
		print("🎭 Player ", peer_id, " already exists on ", node_type, ", skipping")
		return
	
	# Get player data
	var player_data = PlayerData.get_player_data(peer_id)
	print("🎭 ", node_type, " player data for ", peer_id, ": ", player_data)
	if player_data.is_empty() and peer_id != 1:
		print("ERROR: No player data found for peer ", peer_id, " on ", node_type)
		return
	
	# Load and configure player
	var player_scene = preload("res://scenes/MultiplayerPlayer.tscn")
	var player_instance = player_scene.instantiate()
	player_instance.name = "Player_" + str(peer_id)
	
	# Set spawn position
	var spawn_index = 0
	var all_peer_ids = PlayerData.get_all_players().keys()
	all_peer_ids.sort()
	spawn_index = all_peer_ids.find(peer_id)
	
	if spawn_index >= 0 and spawn_index < spawn_positions.size():
		player_instance.global_position = spawn_positions[spawn_index]
	else:
		player_instance.global_position = spawn_positions[0]
	
	# Add to scene and initialize
	add_child(player_instance, true)
	
	# Initialize with peer_id
	if player_instance.has_method("initialize_player_with_id"):
		print("🎯 SPAWNING PLAYER - Peer ID: ", peer_id, " Position: ", player_instance.global_position)
		print("🎯 Current multiplayer unique ID: ", multiplayer.get_unique_id())
		print("🎯 Is this player local? ", peer_id == multiplayer.get_unique_id())
		player_instance.initialize_player_with_id(peer_id)
		
		# Restore complete state if this is a scene transition
		if is_entering_from_transition:
			call_deferred("restore_player_transition_state", player_instance, peer_id)
		
		print("✅ ", node_type, " spawned player ", peer_id, " at position ", player_instance.global_position)

func restore_player_transition_state(player_instance: Node, peer_id: int):
	"""Restore player state from scene transition data"""
	print("🔄 Restoring transition state for player ", peer_id, " in main scene")
	
	# Get the complete state data for this scene transition
	var complete_state = PlayerData.restore_player_state_for_scene(peer_id, "Main")
	
	if complete_state and not complete_state.is_empty():
		print("🔄 Found complete state data for player ", peer_id)
		print("🔄 State data: ", complete_state)
		
		# Restore all player properties
		if "health" in complete_state:
			player_instance.health = complete_state["health"]
			print("🔄 Restored health: ", complete_state["health"])
		if "social" in complete_state:
			player_instance.social = complete_state["social"]
			print("🔄 Restored social: ", complete_state["social"])
		if "ccat_score" in complete_state:
			player_instance.ccat_score = complete_state["ccat_score"]
			print("🔄 Restored ccat_score: ", complete_state["ccat_score"])
		if "position" in complete_state:
			player_instance.global_position = complete_state["position"]
			print("🔄 Restored position: ", complete_state["position"])
		if "name" in complete_state:
			player_instance.player_name = complete_state["name"]
			print("🔄 Restored name: ", complete_state["name"])
		if "sprite_path" in complete_state and complete_state["sprite_path"] != "":
			print("🎨 Restoring sprite: ", complete_state["sprite_path"])
			if player_instance.has_method("load_sprite"):
				player_instance.load_sprite(complete_state["sprite_path"])
				print("✅ Sprite restoration attempted")
			else:
				print("❌ Player instance does not have load_sprite method")
		else:
			print("⚠️  No sprite_path in state data or sprite_path is empty: ", complete_state.get("sprite_path", "MISSING"))
		if "is_eliminated" in complete_state:
			if "is_eliminated" in player_instance:
				player_instance.is_eliminated = complete_state["is_eliminated"]
		if "game_outcome" in complete_state:
			if "game_outcome" in player_instance:
				player_instance.game_outcome = complete_state["game_outcome"]
		if "ui_visible" in complete_state:
			if "ui_visible" in player_instance:
				player_instance.ui_visible = complete_state["ui_visible"]
		if "interaction_cooldowns" in complete_state:
			if "interaction_cooldowns" in player_instance:
				player_instance.interaction_cooldowns = complete_state["interaction_cooldowns"]
		if "last_direction" in complete_state:
			if "last_direction" in player_instance:
				player_instance.last_direction = complete_state["last_direction"]
		
		print("✅ Successfully restored complete state for player ", peer_id, " in main scene")
		print("📊 Player stats: H:", player_instance.health, " S:", player_instance.social, " C:", player_instance.ccat_score)
	else:
		print("⚠️  No transition state found for player ", peer_id, " - using basic data")

func create_fallback_host_player():
	"""Create a fallback host player for single-player mode"""
	print("Creating fallback host player for single-player mode...")
	# Use the current player's actual name if available, otherwise fallback
	var actual_name = PlayerData.player_name
	if actual_name.is_empty():
		actual_name = "Solo Player"
	print("Using player name for single-player: ", actual_name)
	PlayerData.register_player(1, actual_name, "res://assets/characters/sean_spritesheet.png")
	await get_tree().process_frame
	spawn_player_local(1)

func _on_peer_connected(peer_id: int):
	"""Handle new peer connection"""
	print("Peer connected: ", peer_id)

func _on_peer_disconnected(peer_id: int):
	"""Handle peer disconnection"""
	print("Peer disconnected: ", peer_id)
	var player_node = get_node_or_null("Player_" + str(peer_id))
	if player_node:
		player_node.queue_free()

func _on_server_disconnected():
	"""Handle server disconnection"""
	print("Server disconnected!")
	get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")

# === GAME STATE MANAGEMENT ===

func _on_game_ended():
	"""Handle game end signal from GameStateManager"""
	print("🏁 Game ended signal received in MainSceneManager")
	call_deferred("evaluate_all_players")

func trigger_game_start():
	"""Trigger game start through GameStateManager"""
	if not is_entering_from_transition and GameStateManager.is_session_active():
		print("🚀 Triggering game start from MainSceneManager")
		GameStateManager.start_game_timer()

func setup_game_end_window():
	"""Create and setup the game end window with proper top-right anchoring"""
	# Create a CanvasLayer for UI that stays on screen (same as timer)
	var game_end_canvas = CanvasLayer.new()
	game_end_canvas.name = "GameEndCanvas"
	add_child(game_end_canvas)
	
	# Create the game end window container (anchored to top-right)
	var game_end_container = Control.new()
	game_end_container.name = "GameEndContainer"
	game_end_container.layout_mode = 3
	game_end_container.anchors_preset = 2  # Top-right preset
	game_end_container.anchor_left = 1.0   # Right edge
	game_end_container.anchor_right = 1.0  # Right edge
	game_end_container.anchor_top = 0.0    # Top edge
	game_end_container.anchor_bottom = 0.0 # Top edge
	game_end_container.offset_left = -535.0   # 535px from right edge (2x larger: 520px + 15px margin)
	game_end_container.offset_top = 15.0      # 15px from top edge
	game_end_container.offset_right = -15.0   # 15px from right edge (negative)
	game_end_container.offset_bottom = 625.0  # 610px tall container (2x larger: 305*2 + 15px top margin)
	game_end_container.z_index = 100
	game_end_canvas.add_child(game_end_container)
	
	# Instantiate the GameEndWindow scene and add it to the container
	game_end_window = GAME_END_WINDOW_SCENE.instantiate()
	game_end_window.anchors_preset = 15  # Fill preset to fill the container
	game_end_window.anchor_left = 0.0
	game_end_window.anchor_right = 1.0
	game_end_window.anchor_top = 0.0
	game_end_window.anchor_bottom = 1.0
	game_end_window.offset_left = 0.0
	game_end_window.offset_top = 0.0
	game_end_window.offset_right = 0.0
	game_end_window.offset_bottom = 0.0
	game_end_container.add_child(game_end_window)
	
	print("🎯 GameEndWindow anchored to top-right corner using CanvasLayer")
	print("🎯 Container position - Left: ", game_end_container.anchor_left, " Top: ", game_end_container.anchor_top)
	print("🎯 Container offsets - Left: ", game_end_container.offset_left, " Right: ", game_end_container.offset_right)

func get_game_end_window() -> Control:
	"""Get reference to the GameEndWindow for elimination updates"""
	return game_end_window

func start_game_timer_if_needed():
	"""Start the game timer through GameStateManager if this is a new game"""
	if not is_entering_from_transition and GameStateManager.is_session_active():
		print("🚀 Starting game timer from MainSceneManager")
		GameStateManager.start_game_timer()



func evaluate_all_players():
	"""Evaluate win/lose conditions for all players"""
	print("📊 Evaluating all players for win/lose conditions...")
	
	# Get all player nodes
	var players = get_children().filter(func(child): return child.name.begins_with("Player_"))
	print("📊 Found ", players.size(), " player nodes to evaluate")
	
	for player in players:
		print("📊 Checking player: ", player.name)
		if player.has_method("evaluate_end_game_condition"):
			print("📊 Calling evaluate_end_game_condition for ", player.name)
			player.evaluate_end_game_condition()
		else:
			print("❌ Player ", player.name, " does not have evaluate_end_game_condition method")

func get_game_time_remaining() -> float:
	"""Get remaining game time from GameStateManager"""
	return GameStateManager.get_game_time_remaining()

func is_game_running() -> bool:
	"""Check if game is currently active via GameStateManager"""
	return GameStateManager.is_game_running()

# Compatibility methods for existing code
var GAME_DURATION: float:
	get:
		return GameStateManager.GAME_DURATION 