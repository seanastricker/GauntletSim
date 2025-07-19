# GameEndWindow.gd - UI window for displaying game results and player elimination status
# Shows real-time updates of player win/lose conditions and provides game restart functionality
extends Control

# UI component references
@onready var title_label: Label = $WindowPanel/VBoxContainer/TitleLabel
@onready var players_container: VBoxContainer = $WindowPanel/VBoxContainer/ScrollContainer/PlayersContainer

# Player elimination tracking
var eliminated_players: Dictionary = {}

func _ready():
	"""Initialize the game end window"""
	print("🎯 GameEndWindow initialized")
	print("🎯 Positioning handled by MainSceneManager container")
	
	# Add a styled background for permanent visibility
	if has_node("WindowPanel"):
		var panel = get_node("WindowPanel")
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.3, 0.9)  # Dark blue-gray background
		style.border_width_left = 2
		style.border_width_right = 2  
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.8, 1.0, 1.0)  # Light blue border
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		panel.add_theme_stylebox_override("panel", style)
		print("🎯 Applied permanent visibility styling to GameEndWindow")
	
	# Keep window visible from start - no hiding
	show_window()
	
	# Add initial placeholder message
	_add_placeholder_message()
	
	# Connect to PlayerData signals for real-time updates
	_connect_to_player_data()
	
	# Load any existing eliminations that happened before this window was created
	_load_existing_eliminations()
	
	# Connect to multiplayer player elimination signals if available
	_connect_to_players()

func _connect_to_player_data():
	"""Connect to PlayerData signals for real-time elimination updates"""
	print("🎯 Connecting GameEndWindow to PlayerData signals...")
	
	if not PlayerData.player_result_added.is_connected(_on_player_result_added):
		PlayerData.player_result_added.connect(_on_player_result_added)
		print("🎯 Connected to PlayerData.player_result_added signal")
	else:
		print("🎯 Already connected to PlayerData.player_result_added signal")

func _on_player_result_added(player_name: String, outcome: String, time_lasted: float):
	"""Called when PlayerData receives a new elimination result"""
	print("🎯 ====== PLAYERDATA SIGNAL RECEIVED ======")
	print("🎯 Player: ", player_name, " Outcome: ", outcome, " Time: ", time_lasted)
	
	# Get the peer_id for this player (we need it for the GameEndWindow)
	var peer_id = _get_peer_id_for_player_name(player_name)
	print("🎯 Found peer_id for ", player_name, ": ", peer_id)
	
	if peer_id != -1:
		print("🎯 Adding elimination to GameEndWindow...")
		add_eliminated_player(player_name, peer_id, outcome, time_lasted)
	else:
		print("🎯 ❌ Could not find peer_id for player: ", player_name)

func _get_peer_id_for_player_name(player_name: String) -> int:
	"""Find the peer_id for a given player name"""
	var all_players = PlayerData.get_all_players()
	for peer_id in all_players.keys():
		var player_data = all_players[peer_id]
		if player_data.get("name", "") == player_name:
			return peer_id
	return -1

func _load_existing_eliminations():
	"""Load any eliminations that already exist in PlayerData"""
	print("🎯 Loading existing eliminations from PlayerData...")
	var all_results = PlayerData.all_player_results
	print("🎯 Found ", all_results.size(), " existing results in PlayerData")
	
	for player_name in all_results.keys():
		var result = all_results[player_name]
		var outcome = result.get("outcome", "unknown")
		var time_lasted = result.get("time_lasted", 0.0)
		
		print("🎯 Processing existing result: ", player_name, " - ", outcome)
		
		# Get peer_id and add to window
		var peer_id = _get_peer_id_for_player_name(player_name)
		if peer_id != -1:
			print("🎯 Adding existing elimination: ", player_name)
			add_eliminated_player(player_name, peer_id, outcome, time_lasted)
		else:
			print("🎯 ❌ Could not find peer_id for existing player: ", player_name)

func _connect_to_players():
	"""Connect to all existing players to listen for elimination events"""
	# This will be called when players are eliminated to update the display
	pass

func show_window():
	"""Display the game end window (permanently visible)"""
	visible = true
	print("🎯 GameEndWindow is now permanently visible!")
	print("🎯 Positioned by MainSceneManager container in top-right corner")

func hide_window():
	"""Hide the game end window (not used in permanent mode)"""
	visible = false
	print("🎯 GameEndWindow hidden (permanent mode - should not be called)")

func _add_placeholder_message():
	"""Add initial placeholder text when no players are eliminated yet"""
	print("🎯 Adding placeholder message to GameEndWindow")
	
	# Clear any existing entries first
	for child in players_container.get_children():
		child.queue_free()
	
	# Add placeholder message
	var placeholder_label = Label.new()
	placeholder_label.text = "No eliminations yet..."
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))  # Light gray
	placeholder_label.add_theme_font_size_override("font_size", 24)
	players_container.add_child(placeholder_label)

func _clear_placeholder_message():
	"""Remove the placeholder message when first elimination occurs"""
	print("🎯 Clearing placeholder message from GameEndWindow")
	for child in players_container.get_children():
		if child is Label and child.text == "No eliminations yet...":
			child.queue_free()
			break

func add_eliminated_player(player_name: String, peer_id: int, outcome: String, time_lasted: float):
	"""Add a player to the elimination list with their results"""
	print("🚫 ====== GAMEENDWINDOW: ADD_ELIMINATED_PLAYER CALLED ======")
	print("🚫 Player: ", player_name, " (Peer: ", peer_id, ") Outcome: ", outcome)
	print("🚫 Window is permanently visible, adding elimination entry")
	
	# Check if this player is already eliminated (prevent duplicates)
	if eliminated_players.has(peer_id):
		print("🚫 Player ", player_name, " already in elimination list, skipping")
		return
	
	# Store player data
	eliminated_players[peer_id] = {
		"name": player_name,
		"outcome": outcome,
		"time_lasted": time_lasted,
		"timestamp": Time.get_ticks_msec()
	}
	
	# Remove placeholder message if this is the first elimination
	if eliminated_players.size() == 1:
		print("🚫 First elimination - removing placeholder message")
		_clear_placeholder_message()
	
	# Create or update player entry in UI
	print("🚫 Creating player entry in UI...")
	_create_player_entry(player_name, outcome, time_lasted)
	
	print("🚫 ====== END ADD_ELIMINATED_PLAYER ======")

func add_game_end_results(player_name: String, peer_id: int, outcome: String):
	"""Add final game results for players who lasted until timer end"""
	print("🏁 Adding final result for: ", player_name, " (", outcome, ")")
	
	# Calculate time lasted (full game duration if they made it to the end)
	var time_lasted = 60.0  # TODO: Get actual game duration from MainSceneManager
	
	add_eliminated_player(player_name, peer_id, outcome, time_lasted)

func _create_player_entry(player_name: String, outcome: String, time_lasted: float):
	"""Create a visual entry for a player's result"""
	# Create container for this player's info
	var entry_container = HBoxContainer.new()
	entry_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Player name label
	var name_label = Label.new()
	name_label.text = player_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 22)
	entry_container.add_child(name_label)
	
	# Result label with color coding
	var result_label = Label.new()
	var result_text = _get_result_text(outcome)
	result_label.text = result_text
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_label.add_theme_font_size_override("font_size", 22)
	
	# Color code the result
	match outcome:
		"win":
			result_label.add_theme_color_override("font_color", Color.GREEN)
		"lose_ccat":
			result_label.add_theme_color_override("font_color", Color.RED)
		"lose_social":
			result_label.add_theme_color_override("font_color", Color.ORANGE)
		_:
			result_label.add_theme_color_override("font_color", Color.WHITE)
	
	entry_container.add_child(result_label)
	
	# Time lasted label
	var time_label = Label.new()
	time_label.text = _format_time(time_lasted)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 22)
	entry_container.add_child(time_label)
	
	# Add to container
	players_container.add_child(entry_container)
	
	print("📋 Created player entry for ", player_name)

func _get_result_text(outcome: String) -> String:
	"""Convert outcome code to display text"""
	match outcome:
		"win":
			return "Got $200k Job!"
		"lose_ccat":
			return "Kicked Out"
		"lose_social":
			return "No Job Offer"
		_:
			return "Unknown"

func _format_time(seconds: float) -> String:
	"""Format seconds into MM:SS format"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]

func clear_results():
	"""Clear all player results from the display"""
	eliminated_players.clear()
	
	# Remove all child entries
	for child in players_container.get_children():
		child.queue_free()
	
	print("🧹 Cleared game results")



# RPC functions for multiplayer synchronization
@rpc("authority", "call_local", "reliable")
func sync_elimination(player_name: String, peer_id: int, outcome: String, time_lasted: float):
	"""Synchronize player elimination across all clients"""
	add_eliminated_player(player_name, peer_id, outcome, time_lasted)

@rpc("authority", "call_local", "reliable") 
func sync_game_end_results(player_name: String, peer_id: int, outcome: String):
	"""Synchronize final game results across all clients"""
	add_game_end_results(player_name, peer_id, outcome)

func get_eliminated_count() -> int:
	"""Get the number of eliminated players"""
	return eliminated_players.size()

func is_player_eliminated(peer_id: int) -> bool:
	"""Check if a specific player has been eliminated"""
	return peer_id in eliminated_players 