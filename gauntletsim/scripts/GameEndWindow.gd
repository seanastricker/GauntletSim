# GameEndWindow.gd - UI window for displaying game results and player elimination status
# Shows real-time updates of player win/lose conditions and provides game restart functionality
extends Control

# UI component references
@onready var title_label: Label = $WindowPanel/VBoxContainer/TitleLabel
@onready var players_container: VBoxContainer = $WindowPanel/VBoxContainer/ScrollContainer/PlayersContainer

# Player elimination tracking
var eliminated_players: Dictionary = {}
var is_window_visible: bool = false

func _ready():
	"""Initialize the game end window"""
	print("🎯 GameEndWindow initialized")
	print("🎯 Initial position: ", position, " Size: ", size)
	print("🎯 Initial anchors - Left: ", anchor_left, " Right: ", anchor_right)
	print("🎯 Initial offsets - Left: ", offset_left, " Right: ", offset_right, " Top: ", offset_top, " Bottom: ", offset_bottom)
	
	# Ensure correct positioning on initialization
	anchor_left = 1.0
	anchor_right = 1.0  
	offset_left = -260.0
	offset_right = -10.0
	offset_top = 80.0
	offset_bottom = 320.0
	print("🎯 Set positioning in _ready - Position: ", position, " Size: ", size)
	
	# Add a bright background to make it visible during testing
	if has_node("WindowPanel"):
		var panel = get_node("WindowPanel")
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.8, 0.9)  # Blue background with transparency
		style.border_width_left = 2
		style.border_width_right = 2  
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color.WHITE
		panel.add_theme_stylebox_override("panel", style)
		print("🎯 Applied blue background style to GameEndWindow")
	
	# Initially hide the window
	hide_window()
	
	# Connect to multiplayer player elimination signals if available
	_connect_to_players()

func _connect_to_players():
	"""Connect to all existing players to listen for elimination events"""
	# This will be called when players are eliminated to update the display
	pass

func show_window():
	"""Display the game end window"""
	visible = true
	is_window_visible = true
	print("🎯 Game end window shown!")
	print("🎯 Position: ", position, " Size: ", size)
	print("🎯 Anchors - Left: ", anchor_left, " Right: ", anchor_right)
	print("🎯 Offsets - Left: ", offset_left, " Right: ", offset_right, " Top: ", offset_top, " Bottom: ", offset_bottom)
	
	# Force correct positioning
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -260.0
	offset_right = -10.0
	offset_top = 80.0
	offset_bottom = 320.0
	print("🎯 Forced positioning - New position: ", position, " Size: ", size)

func hide_window():
	"""Hide the game end window"""
	visible = false
	is_window_visible = false
	print("🎯 Game end window hidden")

func add_eliminated_player(player_name: String, peer_id: int, outcome: String, time_lasted: float):
	"""Add a player to the elimination list with their results"""
	print("🚫 GameEndWindow: Adding eliminated player: ", player_name, " (", outcome, ")")
	print("🚫 Current window visible: ", is_window_visible)
	print("🚫 Window position: ", position, " size: ", size)
	
	# Store player data
	eliminated_players[peer_id] = {
		"name": player_name,
		"outcome": outcome,
		"time_lasted": time_lasted,
		"timestamp": Time.get_ticks_msec()
	}
	
	# Create or update player entry in UI
	_create_player_entry(player_name, outcome, time_lasted)
	
	# Show window if this is the first elimination
	if not is_window_visible:
		print("🚫 Showing GameEndWindow for first elimination...")
		show_window()
	else:
		print("🚫 GameEndWindow already visible, just adding entry")

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
	name_label.add_theme_font_size_override("font_size", 14)
	entry_container.add_child(name_label)
	
	# Result label with color coding
	var result_label = Label.new()
	var result_text = _get_result_text(outcome)
	result_label.text = result_text
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_label.add_theme_font_size_override("font_size", 14)
	
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
	time_label.add_theme_font_size_override("font_size", 14)
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