# MainSceneManager.gd - Manages multiplayer players in the main game scene
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

# Game Timer System
const GAME_DURATION = 60.0  # 1 minute for testing (eventually 10 minutes)
var game_time_remaining: float = GAME_DURATION
var game_timer: Timer
var is_game_active: bool = false
var game_ended: bool = false

# Timer UI
var timer_label: Label

func _ready():
	"""Initialize the main scene with multiplayer support"""
	print("MainSceneManager initializing...")
	
	# Setup multiplayer callbacks
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Connect to PlayerData signal for retry spawning
	PlayerData.player_registry_updated.connect(_on_player_registry_updated)
	
	# Setup game timer and UI
	setup_game_timer()
	setup_timer_ui()
	
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
	PlayerData.broadcast_player_registry()
	
	# Wait longer for the broadcast to reach all clients
	await get_tree().create_timer(0.2).timeout
	print("Player data broadcast complete, now spawning...")
	
	# Spawn all players locally on server
	for peer_id in all_players.keys():
		spawn_player_local(peer_id)
	
	# Tell all clients to spawn the same players
	spawn_all_players_on_clients.rpc()

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
		player_instance.initialize_player_with_id(peer_id)
		print("✅ ", node_type, " spawned player ", peer_id, " at position ", player_instance.global_position)

func create_fallback_host_player():
	"""Create a fallback host player for single-player mode"""
	print("Creating fallback host player...")
	PlayerData.register_player(1, "Host Player", "res://assets/characters/sean_spritesheet.png")
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

# === GAME TIMER SYSTEM ===

func setup_game_timer():
	"""Initialize the game timer system"""
	if multiplayer.is_server():
		print("🕒 Server: Setting up game timer for ", GAME_DURATION, " seconds")
		
		# Create and configure timer
		game_timer = Timer.new()
		game_timer.wait_time = 1.0  # Update every second
		game_timer.autostart = false
		game_timer.timeout.connect(_on_game_timer_tick)
		add_child(game_timer)
		
		# Start timer after players spawn
		call_deferred("start_game_timer")
	else:
		print("🕒 Client: Waiting for timer updates from server")

func setup_timer_ui():
	"""Create timer display UI"""
	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = format_time(GAME_DURATION)
	timer_label.position = Vector2(10, 10)
	timer_label.z_index = 100
	
	# Style the timer label
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	timer_label.add_theme_constant_override("outline_size", 3)
	
	add_child(timer_label)
	print("🖥️ Timer UI created")

func start_game_timer():
	"""Start the game timer (server only)"""
	if multiplayer.is_server() and not is_game_active and not game_ended:
		print("🚀 Starting game timer!")
		is_game_active = true
		game_timer.start()
		
		# Notify all clients that game has started
		game_started.rpc()

@rpc("authority", "reliable")
func game_started():
	"""Notify clients that the game has started"""
	is_game_active = true
	print("🎮 Game started notification received!")

func _on_game_timer_tick():
	"""Handle timer tick (server only)"""
	if not multiplayer.is_server() or game_ended:
		return
	
	game_time_remaining -= 1.0
	
	# Update server's own timer display
	update_timer_display()
	
	# Sync timer to all clients
	sync_timer.rpc(game_time_remaining)
	
	# Check if time is up
	if game_time_remaining <= 0.0:
		end_game()

@rpc("authority", "reliable")
func sync_timer(time_remaining: float):
	"""Sync timer from server to clients"""
	game_time_remaining = time_remaining
	update_timer_display()

func update_timer_display():
	"""Update the timer UI display"""
	if timer_label:
		timer_label.text = format_time(game_time_remaining)
		
		# Change color when time is running low
		if game_time_remaining <= 10.0:
			timer_label.add_theme_color_override("font_color", Color.RED)
		elif game_time_remaining <= 30.0:
			timer_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)

func format_time(seconds: float) -> String:
	"""Format seconds into MM:SS format"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]

func end_game():
	"""End the game and evaluate all players"""
	if game_ended:
		return
		
	print("⏰ Game time is up! Evaluating all players...")
	game_ended = true
	is_game_active = false
	
	if multiplayer.is_server():
		game_timer.stop()
	
	# Notify all clients that game has ended and trigger evaluation
	game_ended_notification.rpc()
	
	# Evaluate win/lose conditions for all players (on all clients)
	call_deferred("evaluate_all_players")

@rpc("authority", "reliable")
func game_ended_notification():
	"""Notify clients that the game has ended"""
	game_ended = true
	is_game_active = false
	print("🏁 Game ended notification received!")
	
	# Trigger evaluation on clients too
	call_deferred("evaluate_all_players")

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
	"""Get remaining game time"""
	return game_time_remaining

func is_game_running() -> bool:
	"""Check if game is currently active"""
	return is_game_active and not game_ended 