# GameEnd.gd - Individual player's game end scene
# Shows player's final results, other players' status, and provides game restart options
extends Control

# UI component references
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var time_label: Label = $CenterContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var final_stats_label: Label = $CenterContainer/VBoxContainer/StatsContainer/FinalStatsLabel
@onready var spectator_label: Label = $CenterContainer/VBoxContainer/SpectatorLabel
@onready var other_players_list: VBoxContainer = $CenterContainer/VBoxContainer/OtherPlayersContainer/OtherPlayersList
@onready var play_again_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton

# Player data
var player_outcome: String = ""
var player_name: String = ""
var time_lasted: float = 0.0
var final_health: int = 0
var final_social: int = 0
var final_ccat: int = 0

# Other players tracking
var other_players: Dictionary = {}

func _ready():
	"""Initialize the game end scene"""
	print("🎮 GameEnd scene initialized")
	print("🔍 PlayerData instance: ", PlayerData)
	print("🔍 PlayerData results at start: ", PlayerData.get_all_player_results())
	
	# Connect button signals
	play_again_button.pressed.connect(_on_play_again_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect to PlayerData signal for real-time updates
	print("🔗 Connecting to PlayerData.player_result_added signal...")
	PlayerData.player_result_added.connect(_on_player_result_added)
	print("🔗 Signal connected successfully!")
	
	# Initially hide spectator info
	spectator_label.visible = false
	
	# Set up the scene with player data (will be passed when transitioning)
	call_deferred("setup_player_results")
	call_deferred("load_existing_results")
	
	# Set up periodic check for new results (backup mechanism)
	var result_check_timer = Timer.new()
	result_check_timer.wait_time = 2.0  # Check every 2 seconds
	result_check_timer.timeout.connect(_check_for_new_results)
	result_check_timer.autostart = true
	add_child(result_check_timer)
	print("🔄 Set up periodic result checking every 2 seconds")

func setup_player_results():
	"""Setup the player's individual results display"""
	# Load data from PlayerData singleton
	var game_data = PlayerData.get_game_end_data()
	
	print("📊 Loading game data from PlayerData:")
	print("   Outcome: ", game_data.outcome)
	print("   Name: ", game_data.name)
	print("   Time Lasted: ", game_data.time_lasted)
	print("   Health: ", game_data.health)
	print("   Social: ", game_data.social)
	print("   CCAT: ", game_data.ccat)
	
	# Set player data and update display
	set_player_data(
		game_data.outcome,
		game_data.name,
		game_data.time_lasted,
		game_data.health,
		game_data.social,
		game_data.ccat
	)
	
	# Clear the data from PlayerData after loading
	PlayerData.clear_game_end_data()
	
	print("📊 Player results loaded from PlayerData")

func set_player_data(outcome: String, name: String, time: float, health: int, social: int, ccat: int):
	"""Set the player's game data and update the display"""
	player_outcome = outcome
	player_name = name
	time_lasted = time
	final_health = health
	final_social = social
	final_ccat = ccat
	
	# Update UI
	_update_player_display()
	
	print("📊 Player data set: ", name, " - ", outcome, " - ", time, "s")

func _update_player_display():
	"""Update the UI with player's results"""
	# Update title and result
	title_label.text = "Game Over - " + player_name
	
	# Set result text and color based on outcome
	match player_outcome:
		"win":
			result_label.text = "🎉 You got a $200k job!"
			result_label.add_theme_color_override("font_color", Color.GREEN)
		"lose_ccat":
			result_label.text = "❌ You have been kicked out!"
			result_label.add_theme_color_override("font_color", Color.RED)
		"lose_social":
			result_label.text = "📄 You did not get a job offer"
			result_label.add_theme_color_override("font_color", Color.ORANGE)
		_:
			result_label.text = "🤔 Game ended"
			result_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Update time and stats
	time_label.text = "Time Lasted: " + _format_time(time_lasted)
	final_stats_label.text = "Final Stats: Health %d, Social %d, CCAT %d" % [final_health, final_social, final_ccat]
	
	print("📊 Player display updated:")
	print("   Time Lasted: ", time_lasted, " seconds")
	print("   Formatted Time: ", _format_time(time_lasted))
	print("   Time Label Text: ", time_label.text)

func add_other_player_result(other_name: String, other_outcome: String, other_time: float):
	"""Add another player's result to the display"""
	print("👥 Adding other player result: ", other_name, " - ", other_outcome)
	
	# Store the data
	other_players[other_name] = {
		"outcome": other_outcome,
		"time": other_time
	}
	
	# Create UI entry
	var entry_container = HBoxContainer.new()
	entry_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Player name
	var name_label = Label.new()
	name_label.text = other_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 32)
	entry_container.add_child(name_label)
	
	# Result with color
	var result_label = Label.new()
	result_label.text = _get_result_text(other_outcome)
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_label.add_theme_font_size_override("font_size", 32)
	
	match other_outcome:
		"win":
			result_label.add_theme_color_override("font_color", Color.GREEN)
		"lose_ccat":
			result_label.add_theme_color_override("font_color", Color.RED)
		"lose_social":
			result_label.add_theme_color_override("font_color", Color.ORANGE)
		_:
			result_label.add_theme_color_override("font_color", Color.WHITE)
	
	entry_container.add_child(result_label)
	
	# Time
	var time_label = Label.new()
	time_label.text = _format_time(other_time)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 32)
	entry_container.add_child(time_label)
	
	# Add to list
	other_players_list.add_child(entry_container)

func _get_result_text(outcome: String) -> String:
	"""Convert outcome to display text"""
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

func enable_spectator_mode(target_player_name: String):
	"""Enable spectator mode to watch another player"""
	spectator_label.visible = true
	spectator_label.text = "👁️ Watching: " + target_player_name
	print("👁️ Spectator mode enabled, watching: ", target_player_name)

func disable_spectator_mode():
	"""Disable spectator mode"""
	spectator_label.visible = false
	print("👁️ Spectator mode disabled")

func _on_play_again_pressed():
	"""Handle Play Again button press"""
	print("🔄 Play Again button pressed")
	
	# Clear all game data before starting over
	PlayerData.clear_all_player_results()
	PlayerData.clear_game_end_data()
	print("🧹 Cleared all game data for new game")
	
	# Return to character creation scene
	get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")

func _on_quit_pressed():
	"""Handle Quit Game button press"""
	print("🚪 Quit button pressed")
	
	# Quit the application
	get_tree().quit()

# RPC functions for receiving updates about other players
@rpc("any_peer", "call_local", "reliable")
func receive_player_result(other_name: String, other_outcome: String, other_time: float):
	"""Receive another player's result via RPC"""
	add_other_player_result(other_name, other_outcome, other_time)

func clear_other_players():
	"""Clear the other players list"""
	for child in other_players_list.get_children():
		child.queue_free()
	other_players.clear()
	print("🧹 Cleared other players list")

func load_existing_results():
	"""Load any existing player results from PlayerData"""
	print("📊 Loading existing player results...")
	print("📊 Current player name: ", self.player_name)
	var all_results = PlayerData.get_all_player_results()
	print("📊 All results in PlayerData: ", all_results)
	print("📊 Number of results found: ", all_results.size())
	
	if all_results.size() == 0:
		print("📊 No existing results found - this might be the issue!")
	
	for other_player_name in all_results:
		var result = all_results[other_player_name]
		print("📊 Processing result for: ", other_player_name, " (Outcome: ", result.outcome, ")")
		# Don't add our own result
		if other_player_name != self.player_name:
			print("📊 Adding other player result: ", other_player_name)
			add_other_player_result(other_player_name, result.outcome, result.time_lasted)
		else:
			print("📊 Skipping own result for: ", other_player_name)

func _on_player_result_added(other_player_name: String, outcome: String, time_lasted: float):
	"""Handle new player result from PlayerData signal"""
	print("🔔 SIGNAL RECEIVED: New player result - ", other_player_name, " - ", outcome, " (", time_lasted, "s)")
	print("🔔 Current player name: ", self.player_name)
	
	# Don't add our own result
	if other_player_name != self.player_name:
		print("🔔 Adding other player result to UI: ", other_player_name)
		add_other_player_result(other_player_name, outcome, time_lasted)
	else:
		print("🔔 Ignoring own result: ", other_player_name)

func _check_for_new_results():
	"""Periodic backup check for new results (in case signals fail)"""
	print("🔄 Periodic check: Looking for new results...")
	var all_results = PlayerData.get_all_player_results()
	print("🔄 Total results in PlayerData: ", all_results.size())
	
	for result_player_name in all_results:
		# Skip our own result
		if result_player_name == self.player_name:
			continue
			
		# Check if we already have this result in our UI
		if result_player_name not in other_players:
			var result = all_results[result_player_name]
			print("🔄 Found NEW result for: ", result_player_name, " - ", result.outcome)
			add_other_player_result(result_player_name, result.outcome, result.time_lasted)
		else:
			print("🔄 Result for ", result_player_name, " already in UI") 