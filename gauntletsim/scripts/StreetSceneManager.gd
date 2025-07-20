# StreetSceneManager.gd - Manages multiplayer players in the street scene
extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

# Spawn positions for different players on the street
var spawn_positions = [
	Vector2(100, 250),   # Host spawn position
	Vector2(120, 250),   # Player 2 spawn (offset right)
	Vector2(140, 250),   # Player 3 spawn (offset right more)
	Vector2(160, 250)    # Player 4 spawn (offset right most)
]

# Track if client failed to spawn initially due to missing data
var client_spawn_failed = false

func _ready():
	"""Initialize the street scene with multiplayer support"""
	print("StreetSceneManager initializing...")
	
	# Setup multiplayer callbacks
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Connect to PlayerData signal for retry spawning
	PlayerData.player_registry_updated.connect(_on_player_registry_updated)
	
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
	
	if player_instance and is_instance_valid(player_instance) and player_instance.has_method("initialize_player"):
		player_instance.initialize_player(peer_id, player_data)
		print("✅ Player ", peer_id, " initialized successfully in street")
	else:
		print("❌ Failed to initialize player ", peer_id, " in street")

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