# Lobby.gd - Multiplayer lobby scene controller
# Handles hosting and joining multiplayer games
extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
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
	
	# Apply modern UI styling
	setup_modern_ui()
	
	print("🎮 Lobby initialization complete!")

func setup_modern_ui():
	"""Configure modern, attractive UI styling for lobby"""
	# Define colors
	var primary_color = Color(0.956, 0.689, 0.416, 1.0)  # #F4B06A
	var secondary_color = Color(0.992, 0.851, 0.604, 1.0)  # #FDD89A
	var black_border = Color(0.0, 0.0, 0.0, 1.0)
	var black_text = Color(0.0, 0.0, 0.0, 1.0)
	var dark_gray_text = Color(0.2, 0.2, 0.2, 0.8)
	
	# Get bold font
	var bold_font = ThemeDB.fallback_font
	
	# Define background color for text boxes
	var text_box_bg_color = Color(0.953, 0.690, 0.416, 1.0)  # #F3B06A
	
	# === TITLE LABEL STYLING ===
	style_label(title_label, 36, black_text, bold_font, text_box_bg_color, black_border)
	
	# === HOST BUTTON STYLING ===
	style_button(host_button, "Host Game", 28, primary_color, secondary_color, black_border, black_text, bold_font)
	
	# === JOIN BUTTON STYLING ===
	style_button(join_button, "Join Game", 28, primary_color, secondary_color, black_border, black_text, bold_font)
	
	# === START GAME BUTTON STYLING ===
	style_button(start_game_button, "Start Game", 32, primary_color, secondary_color, black_border, black_text, bold_font)
	
	# === IP INPUT STYLING ===
	style_line_edit(ip_input, 28, primary_color, secondary_color, black_border, black_text, dark_gray_text, bold_font)
	
	# === STATUS LABEL STYLING ===
	style_label(status_label, 28, black_text, bold_font, text_box_bg_color, black_border)
	
	# === PLAYERS LIST STYLING ===
	style_item_list(players_list, 22, primary_color, secondary_color, black_border, black_text, bold_font)
	
	print("Modern UI styling applied to lobby!")

func style_button(button: Button, text: String, font_size: int, bg_color: Color, hover_color: Color, border_color: Color, text_color: Color, font: Font):
	"""Apply consistent button styling"""
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_font_override("font", font)
	
	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = bg_color
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = border_color
	normal_style.corner_radius_top_left = 15
	normal_style.corner_radius_top_right = 15
	normal_style.corner_radius_bottom_left = 15
	normal_style.corner_radius_bottom_right = 15
	normal_style.shadow_size = 0
	normal_style.shadow_offset = Vector2(0, 0)
	
	# Hover state
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = hover_color
	
	# Pressed state
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(bg_color.r * 0.9, bg_color.g * 0.9, bg_color.b * 0.9, 1.0)
	
	# Focus state (no ugly outline)
	var focus_style = normal_style.duplicate()
	
	# Apply styles
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus_style)
	
	# Font colors - ensure pure black text in ALL states including disabled
	var pure_black = Color(0.0, 0.0, 0.0, 1.0)
	button.add_theme_color_override("font_color", pure_black)
	button.add_theme_color_override("font_hover_color", pure_black)
	button.add_theme_color_override("font_pressed_color", pure_black)
	button.add_theme_color_override("font_focus_color", pure_black)
	button.add_theme_color_override("font_hover_pressed_color", pure_black)
	button.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", pure_black)
	
	# Force remove any inherited theme colors that might override
	button.remove_theme_color_override("font_selected_color")
	button.remove_theme_color_override("font_unselected_color")
	
	# Set minimum size
	button.custom_minimum_size = Vector2(280, 70)

func style_line_edit(line_edit: LineEdit, font_size: int, bg_color: Color, hover_color: Color, border_color: Color, text_color: Color, placeholder_color: Color, font: Font):
	"""Apply consistent LineEdit styling"""
	line_edit.add_theme_font_size_override("font_size", font_size)
	line_edit.add_theme_font_override("font", font)
	
	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = bg_color
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = border_color
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	normal_style.shadow_size = 0
	normal_style.shadow_offset = Vector2(0, 0)
	
	# Hover state
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = hover_color
	
	# Focus state
	var focus_style = normal_style.duplicate()
	
	# Apply styles
	line_edit.add_theme_stylebox_override("normal", normal_style)
	line_edit.add_theme_stylebox_override("hover", hover_style)
	line_edit.add_theme_stylebox_override("focus", focus_style)
	line_edit.add_theme_stylebox_override("read_only", normal_style)
	
	# Font colors
	line_edit.add_theme_color_override("font_color", text_color)
	line_edit.add_theme_color_override("font_placeholder_color", placeholder_color)
	line_edit.add_theme_color_override("caret_color", text_color)
	line_edit.add_theme_color_override("selection_color", Color(0.4, 0.6, 1.0, 0.4))
	
	# Set minimum size
	line_edit.custom_minimum_size = Vector2(400, 50)

func style_label(label: Label, font_size: int, text_color: Color, font: Font, bg_color: Color = Color.TRANSPARENT, border_color: Color = Color.TRANSPARENT):
	"""Apply consistent Label styling with optional background box"""
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", text_color)
	
	if bg_color != Color.TRANSPARENT:
		# Create background box style
		var label_bg_style = StyleBoxFlat.new()
		label_bg_style.bg_color = bg_color
		
		if border_color != Color.TRANSPARENT:
			label_bg_style.border_width_left = 3
			label_bg_style.border_width_right = 3
			label_bg_style.border_width_top = 3
			label_bg_style.border_width_bottom = 3
			label_bg_style.border_color = border_color
		
		label_bg_style.corner_radius_top_left = 10
		label_bg_style.corner_radius_top_right = 10
		label_bg_style.corner_radius_bottom_left = 10
		label_bg_style.corner_radius_bottom_right = 10
		label_bg_style.shadow_size = 0
		label_bg_style.shadow_offset = Vector2(0, 0)
		
		# Add padding for better text appearance
		label_bg_style.content_margin_left = 20
		label_bg_style.content_margin_right = 20
		label_bg_style.content_margin_top = 12
		label_bg_style.content_margin_bottom = 12
		
		label.add_theme_stylebox_override("normal", label_bg_style)

func style_item_list(item_list: ItemList, font_size: int, bg_color: Color, selection_color: Color, border_color: Color, text_color: Color, font: Font):
	"""Apply consistent ItemList styling"""
	item_list.add_theme_font_size_override("font_size", font_size)
	item_list.add_theme_font_override("font", font)
	
	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(bg_color.r * 0.95, bg_color.g * 0.95, bg_color.b * 0.95, 1.0)  # Slightly darker
	bg_style.border_width_left = 3
	bg_style.border_width_right = 3
	bg_style.border_width_top = 3
	bg_style.border_width_bottom = 3
	bg_style.border_color = border_color
	bg_style.corner_radius_top_left = 10
	bg_style.corner_radius_top_right = 10
	bg_style.corner_radius_bottom_left = 10
	bg_style.corner_radius_bottom_right = 10
	bg_style.shadow_size = 0
	bg_style.shadow_offset = Vector2(0, 0)
	
	# Selected item style
	var selected_style = StyleBoxFlat.new()
	selected_style.bg_color = selection_color
	selected_style.border_width_left = 1
	selected_style.border_width_right = 1
	selected_style.border_width_top = 1
	selected_style.border_width_bottom = 1
	selected_style.border_color = border_color
	selected_style.corner_radius_top_left = 5
	selected_style.corner_radius_top_right = 5
	selected_style.corner_radius_bottom_left = 5
	selected_style.corner_radius_bottom_right = 5
	selected_style.shadow_size = 0
	selected_style.shadow_offset = Vector2(0, 0)
	
	# Apply styles
	item_list.add_theme_stylebox_override("panel", bg_style)
	item_list.add_theme_stylebox_override("selected", selected_style)
	item_list.add_theme_stylebox_override("selected_focus", selected_style)
	
	# Font colors
	item_list.add_theme_color_override("font_color", text_color)
	item_list.add_theme_color_override("font_selected_color", text_color)
	
	# Set minimum size
	item_list.custom_minimum_size = Vector2(400, 200)

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
	
	# Request current player list from server
	request_player_list.rpc_id(1)

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
	
	# Send current player list to the newly connected client
	if multiplayer.is_server():
		call_deferred("broadcast_player_list")

func _on_peer_disconnected(id: int):
	"""Called when a peer disconnects"""
	print("Player disconnected: ", id)
	remove_player_from_list(id)
	PlayerData.remove_player(id)
	
	# Broadcast updated player list to all remaining clients
	if multiplayer.is_server():
		broadcast_player_list()

@rpc("any_peer", "reliable")
func send_player_data(display_name: String, sprite_path: String):
	"""Send player data to the server"""
	var sender_id = multiplayer.get_remote_sender_id()
	PlayerData.register_player(sender_id, display_name, sprite_path)
	add_player_to_list(sender_id, display_name)
	print("Registered player: ", display_name, " with ID: ", sender_id)
	
	# Broadcast updated player list to all clients
	if multiplayer.is_server():
		broadcast_player_list()

@rpc("any_peer", "reliable")
func request_player_list():
	"""Request current player list from server (client to server)"""
	if multiplayer.is_server():
		print("📋 Client requested player list, broadcasting...")
		broadcast_player_list()

@rpc("authority", "reliable")
func update_player_list(player_data_list: Array):
	"""Receive updated player list from server"""
	print("📋 Received player list update: ", player_data_list)
	
	# Clear current list
	players_list.clear()
	
	# Add all players from the updated list
	for player_data in player_data_list:
		var id = player_data["id"]
		var name = player_data["name"]
		var is_host = (id == 1)
		var display_name = name + (" (Host)" if is_host else "")
		
		players_list.add_item(display_name)
		players_list.set_item_metadata(players_list.get_item_count() - 1, id)
	
	print("📋 Player list updated, total players: ", players_list.get_item_count())

func broadcast_player_list():
	"""Broadcast current player list to all clients (server only)"""
	if not multiplayer.is_server():
		return
	
	var player_data_list = []
	var all_players = PlayerData.get_all_players()
	
	for peer_id in all_players:
		var player_info = all_players[peer_id]
		player_data_list.append({
			"id": peer_id,
			"name": player_info["name"]
		})
	
	print("📋 Broadcasting player list to all clients: ", player_data_list)
	update_player_list.rpc(player_data_list)

func add_player_to_list(id: int, display_name: String):
	"""Add a player to the UI list (local only)"""
	players_list.add_item(display_name)
	players_list.set_item_metadata(players_list.get_item_count() - 1, id)

func remove_player_from_list(id: int):
	"""Remove a player from the UI list (local only)"""
	for i in range(players_list.get_item_count()):
		if players_list.get_item_metadata(i) == id:
			players_list.remove_item(i)
			break 
