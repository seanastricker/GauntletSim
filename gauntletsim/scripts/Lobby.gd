# Lobby.gd - Multiplayer lobby scene controller
# Handles hosting and joining multiplayer games
extends Control

@onready var host_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/JoinButton
@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPInput
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var players_list: ItemList = $CenterContainer/VBoxContainer/PlayersList
@onready var start_game_button: Button = $CenterContainer/VBoxContainer/StartGameButton

const DEFAULT_PORT = 7000
var multiplayer_peer: ENetMultiplayerPeer

func _ready():
	"""Initialize the lobby interface and connect signals"""
	print("🎮 Lobby _ready() function called!")
	
	print("🎮 Connecting button signals...")
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_game_button.pressed.connect(_on_start_game_pressed)
	start_game_button.visible = false
	print("🎮 Button signals connected!")
	
	print("🎮 Connecting multiplayer signals...")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	print("🎮 Multiplayer signals connected!")
	
	status_label.text = "Choose Host or Join"
	ip_input.placeholder_text = "localhost"
	
	print("🎮 Lobby initialization complete!")

func _on_host_pressed():
	"""Start hosting a multiplayer game"""
	print("🏠 HOST BUTTON PRESSED!")
	print("🏠 Creating ENetMultiplayerPeer...")
	
	multiplayer_peer = ENetMultiplayerPeer.new()
	print("🏠 Peer created, attempting to create server...")
	
	var error = multiplayer_peer.create_server(DEFAULT_PORT, 4)  # Max 4 players
	print("🏠 Server creation result: ", error)
	
	if error == OK:
		print("🏠 Server created successfully!")
		multiplayer.multiplayer_peer = multiplayer_peer
		status_label.text = "Hosting on port " + str(DEFAULT_PORT)
		start_game_button.visible = true
		host_button.disabled = true
		join_button.disabled = true
		ip_input.editable = false
		
		print("🏠 Registering host player...")
		# Register host player
		PlayerData.register_player(1, PlayerData.player_name, PlayerData.player_sprite_path)
		add_player_to_list(1, PlayerData.player_name + " (Host)")
		print("🏠 Host setup complete!")
	else:
		print("❌ Failed to host with error: ", error)
		status_label.text = "Failed to host: " + str(error)

func _on_join_pressed():
	"""Join an existing multiplayer game"""
	var ip = ip_input.text if ip_input.text else "localhost"
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_client(ip, DEFAULT_PORT)
	
	if error == OK:
		multiplayer.multiplayer_peer = multiplayer_peer
		status_label.text = "Connecting to " + ip + "..."
		host_button.disabled = true
		join_button.disabled = true
		ip_input.editable = false
	else:
		status_label.text = "Failed to connect: " + str(error)

func _on_start_game_pressed():
	"""Host starts the game for all players"""
	print("🎮 Start Game button pressed!")
	if multiplayer.is_server():
		print("🎮 Is server - calling start_game.rpc()...")
		status_label.text = "Starting game..."
		start_game.rpc()
	else:
		print("🎮 Not server - ignoring button press")

func _on_connected_to_server():
	"""Called when successfully connected to server as client"""
	status_label.text = "Connected! Waiting for game to start..."
	send_player_data.rpc_id(1, PlayerData.player_name, PlayerData.player_sprite_path)

func _on_connection_failed():
	"""Called when connection to server fails"""
	status_label.text = "Connection failed!"
	reset_lobby_ui()

func _on_server_disconnected():
	"""Called when the server/host disconnects"""
	status_label.text = "Host disconnected! Returning to lobby..."
	print("Server disconnected! Cleaning up...")
	
	# Clean up multiplayer state
	PlayerData.players_data.clear()
	players_list.clear()
	
	# Reset UI after a short delay so user can see the message
	await get_tree().create_timer(2.0).timeout
	reset_lobby_ui()

func reset_lobby_ui():
	"""Reset the lobby UI to initial state"""
	host_button.disabled = false
	join_button.disabled = false
	ip_input.editable = true
	start_game_button.visible = false
	status_label.text = "Choose Host or Join"
	players_list.clear()
	
	# Close multiplayer connection
	if multiplayer_peer:
		multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

@rpc("call_local", "reliable")
func start_game():
	"""Transition all players to the main game scene"""
	print("🚀 start_game() called - transitioning to Main scene...")
	print("🚀 About to call get_tree().change_scene_to_file()...")
	
	var result = get_tree().change_scene_to_file("res://scenes/Main.tscn")
	print("🚀 Scene transition result: ", result)
	
	if result != OK:
		print("❌ Scene transition FAILED with error: ", result)

func _on_peer_connected(id: int):
	"""Called when a new peer connects to the server"""
	print("Player connected: ", id)

func _on_peer_disconnected(id: int):
	"""Called when a peer disconnects"""
	print("Player disconnected: ", id)
	remove_player_from_list(id)
	PlayerData.remove_player(id)

@rpc("any_peer", "reliable")
func send_player_data(display_name: String, sprite_path: String):
	"""Send player data to the server"""
	var sender_id = multiplayer.get_remote_sender_id()
	PlayerData.register_player(sender_id, display_name, sprite_path)
	add_player_to_list(sender_id, display_name)
	print("Registered player: ", display_name, " with ID: ", sender_id)

func add_player_to_list(id: int, display_name: String):
	"""Add a player to the UI list"""
	players_list.add_item(display_name)
	players_list.set_item_metadata(players_list.get_item_count() - 1, id)

func remove_player_from_list(id: int):
	"""Remove a player from the UI list"""
	for i in range(players_list.get_item_count()):
		if players_list.get_item_metadata(i) == id:
			players_list.remove_item(i)
			break 
