# StreetSceneManager.gd - Manages multiplayer players in the street scene
# Uses GameStateManager for consistent game state across scenes
extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

# Game End Window
var game_end_window: Control
const GAME_END_WINDOW_SCENE = preload("res://scenes/GameEndWindow.tscn")

# Spawn positions for different players on the street
var spawn_positions = [
	Vector2(100, 250),   # Host spawn position
	Vector2(120, 250),   # Player 2 spawn (offset right)
	Vector2(140, 250),   # Player 3 spawn (offset right more)
	Vector2(160, 250)    # Player 4 spawn (offset right most)
]

# Track if client failed to spawn initially due to missing data
var client_spawn_failed = false

# Scene transition tracking
var is_entering_from_transition: bool = false

func _ready():
	"""Initialize the street scene with multiplayer support"""
	print("StreetSceneManager initializing...")
	
	# This should always be a scene transition since street isn't the starting scene
	is_entering_from_transition = true
	
	# Initialize GameStateManager for scene transition
	print("🔄 Entering street scene from transition - preserving game state")
	GameStateManager.initialize_for_scene_transition()
	
	# Setup game end window for player elimination tracking
	setup_game_end_window()
	
	# Setup multiplayer callbacks
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Connect to PlayerData signal for retry spawning
	PlayerData.player_registry_updated.connect(_on_player_registry_updated)
	
	# Connect to GameStateManager signals
	GameStateManager.game_timer_ended.connect(_on_game_ended)
	
	# Check if we have an active multiplayer session
	if multiplayer.has_multiplayer_peer() and PlayerData.get_all_players().size() > 0:
		# Multiplayer mode
		if multiplayer.is_server():
			print("Server: Spawning all players in street...")
			call_deferred("spawn_all_players")
		else:
			print("Client: Waiting for server in street...")
	else:
		# Single-player fallback mode
		print("Single-player mode - creating fallback player in street")
		call_deferred("create_fallback_host_player")

func spawn_all_players():
	"""Spawn all registered players on server and sync to all clients"""
	var all_players = PlayerData.get_all_players()
	print("Spawning players in street: ", all_players.keys())
	
	# CRITICAL: Broadcast player data to all clients first
	print("Broadcasting player registry to clients...")
	PlayerData.broadcast_player_registry()
	
	# Wait for the broadcast to reach all clients
	await get_tree().create_timer(0.2).timeout
	print("Player data broadcast complete, now spawning in street...")
	
	# Spawn all players locally on server
	for peer_id in all_players.keys():
		spawn_player_local(peer_id)
	
	# Tell all clients to spawn the same players
	spawn_all_players_on_clients.rpc()

@rpc("authority", "call_local", "reliable")
func spawn_all_players_on_clients():
	"""Spawn all registered players on clients"""
	var node_type = "server" if multiplayer.is_server() else "client"
	print("🌍 spawn_all_players_on_clients() called on ", node_type, " in street")
	
	var all_players = PlayerData.get_all_players()
	
	# Debug: Show what player data client has before spawning
	print("🔍 CLIENT PLAYER DATA DEBUG (before spawning in street):")
	for peer_id in all_players.keys():
		var player_data = all_players[peer_id]
		print("  - Peer ", peer_id, ": ", player_data.get("name", "NO_NAME"), " (", player_data.get("sprite_path", "NO_SPRITE"), ")")
	
	# Only clients should spawn here (server already spawned)
	if not multiplayer.is_server():
		for peer_id in all_players.keys():
			spawn_player_local(peer_id)
		print("✅ All players spawned successfully on client in street")
	else:
		print("✅ Server: spawn_all_players_on_clients completed")

func spawn_player_local(peer_id: int):
	"""Spawn a single player locally"""
	print("🎮 Spawning player locally for peer_id: ", peer_id, " in street")
	
	# Check if player already exists
	var existing_player = get_node_or_null("Player_" + str(peer_id))
	if existing_player:
		print("⚠️  Player ", peer_id, " already exists in street, skipping spawn")
		return
	
	# Get player data
	var player_data = PlayerData.get_player_data(peer_id)
	if not player_data:
		print("❌ No player data found for peer_id: ", peer_id, " in street")
		return
	
	# Load the player scene
	var player_scene = preload("res://scenes/MultiplayerPlayer.tscn")
	var player_instance = player_scene.instantiate()
	
	# Set unique name and basic properties
	player_instance.name = "Player_" + str(peer_id)
	player_instance.set_multiplayer_authority(peer_id)
	
	# Determine spawn position
	var spawn_index = PlayerData.get_all_players().keys().find(peer_id)
	if spawn_index == -1:
		spawn_index = 0
	spawn_index = spawn_index % spawn_positions.size()
	player_instance.position = spawn_positions[spawn_index]
	
	# Add to scene tree
	add_child(player_instance)
	
	print("✅ Player spawned for peer_id: ", peer_id, " at position: ", player_instance.position, " in street")
	
	# Initialize the player with their data
	call_deferred("initialize_spawned_player", player_instance, peer_id, player_data)

func initialize_spawned_player(player_instance: Node, peer_id: int, player_data: Dictionary):
	"""Initialize a spawned player with their data"""
	print("🔧 Initializing spawned player ", peer_id, " with data in street")
	
	# Wait a frame to ensure the player is fully in the scene tree
	await get_tree().process_frame
	
	if player_instance and is_instance_valid(player_instance):
		# First use basic initialization
		if player_instance.has_method("initialize_player_with_id"):
			player_instance.initialize_player_with_id(peer_id)
			print("✅ Basic initialization completed for player ", peer_id)
		
		# Then restore complete state if this is a scene transition
		if is_entering_from_transition:
			restore_player_transition_state(player_instance, peer_id)
		
		print("✅ Player ", peer_id, " fully initialized in street")
	else:
		print("❌ Failed to initialize player ", peer_id, " in street")

func restore_player_transition_state(player_instance: Node, peer_id: int):
	"""Restore player state from scene transition data"""
	print("🔄 Restoring transition state for player ", peer_id, " in street")
	
	# Get the complete state data for this scene transition
	var complete_state = PlayerData.restore_player_state_for_scene(peer_id, "Street")
	
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
		
		print("✅ Successfully restored complete state for player ", peer_id, " in street")
		print("📊 Player stats: H:", player_instance.health, " S:", player_instance.social, " C:", player_instance.ccat_score)
	else:
		print("⚠️  No transition state found for player ", peer_id, " - using basic data")

func create_fallback_host_player():
	"""Create a fallback player for single-player mode"""
	print("🎮 Creating fallback host player in street...")
	
	# Create basic player data
	var fallback_data = {
		"name": "Host Player",
		"sprite_path": "res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_01.png",
		"health": 50,
		"social": 50,
		"ccat_score": 50
	}
	
	# Store in PlayerData
	PlayerData.store_player_data(1, fallback_data)
	
	# Spawn the player
	spawn_player_local(1)

func _on_peer_connected(peer_id: int):
	"""Handle when a new peer connects"""
	print("Peer ", peer_id, " connected to street scene")

func _on_peer_disconnected(peer_id: int):
	"""Handle when a peer disconnects"""
	print("Peer ", peer_id, " disconnected from street scene")
	
	# Remove the disconnected player
	var player_node = get_node_or_null("Player_" + str(peer_id))
	if player_node:
		player_node.queue_free()

func _on_server_disconnected():
	"""Handle when server disconnects"""
	print("Server disconnected from street scene")
	# Could return to main menu or lobby here
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_player_registry_updated():
	"""Handle when PlayerData registry is updated"""
	print("Player registry updated in street, checking for failed spawns...")
	
	if client_spawn_failed and not multiplayer.is_server():
		print("Retrying failed client spawn in street...")
		client_spawn_failed = false
		call_deferred("spawn_all_players")

func _on_game_ended():
	"""Handle game end signal from GameStateManager"""
	print("🏁 Game ended signal received in StreetSceneManager")
	call_deferred("evaluate_all_players")

func evaluate_all_players():
	"""Evaluate win/lose conditions for all players when game ends"""
	print("📊 Evaluating all players for win/lose conditions in street...")
	
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

# Compatibility methods for existing code that expects these methods
func get_game_time_remaining() -> float:
	"""Get remaining game time from GameStateManager"""
	return GameStateManager.get_game_time_remaining()

func is_game_running() -> bool:
	"""Check if game is currently active via GameStateManager"""
	return GameStateManager.is_game_running()

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

var GAME_DURATION: float:
	get:
		return GameStateManager.GAME_DURATION 