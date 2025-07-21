# GameStateManager.gd - Global singleton for managing game state across scenes
# Handles game timer, session state, and scene transitions while preserving game progress
extends Node

# Game Timer System (moved from MainSceneManager)
const GAME_DURATION = 60.0  # 1 minute for testing (eventually 10 minutes)
var game_time_remaining: float = GAME_DURATION
var game_timer: Timer
var is_game_active: bool = false
var game_ended: bool = false
var game_started_timestamp: float = 0.0

# Game Session State
var current_scene_name: String = ""
var is_game_session_active: bool = false
var game_session_id: String = ""

# Player State Management
var scene_transition_data: Dictionary = {}
var last_scene_player_positions: Dictionary = {}

# Timer UI Management
var timer_ui_scenes: Array[String] = ["Main", "Street"]  # Scenes that should show timer
var current_timer_ui: CanvasLayer = null

# Signals for game state changes
signal game_started()
signal game_timer_ended()
signal game_time_updated(time_remaining: float)
signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene_name: String)

func _ready():
	"""Initialize the GameStateManager singleton"""
	print("🎮 GameStateManager singleton initialized")
	
	# Set process mode to always so it persists across scene changes
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create the game timer
	setup_game_timer()
	
	# Connect to scene tree changes
	get_tree().node_added.connect(_on_node_added)
	# Note: We'll detect scene changes manually since current_scene_changed doesn't exist in Godot 4

func detect_and_handle_scene_change():
	"""Detect and handle scene changes manually"""
	var new_scene = get_tree().current_scene
	if new_scene:
		var scene_name = new_scene.scene_file_path.get_file().get_basename()
		
		# Only process if scene actually changed
		if scene_name != current_scene_name:
			print("🎬 Scene changed to: ", scene_name)
			current_scene_name = scene_name
			
			# Only manage game scenes, not menu/character creation scenes
			if scene_name in ["CharacterCreation", "Lobby", "GameEnd"]:
				print("🚫 Skipping GameStateManager setup for menu scene: ", scene_name)
				# Remove timer UI for menu scenes
				if current_timer_ui and is_instance_valid(current_timer_ui):
					current_timer_ui.queue_free()
					current_timer_ui = null
				return
			
			# Setup timer UI for applicable scenes (no deferred call to avoid conflicts)
			if timer_ui_scenes.has(scene_name) and is_game_session_active:
				setup_persistent_timer_ui()
			
			# Scale interaction prompts for the current scene
			call_deferred("scale_interaction_prompts_for_scene")
			
			scene_transition_completed.emit(scene_name)

func _on_scene_changed():
	"""Legacy function - now replaced by detect_and_handle_scene_change"""
	detect_and_handle_scene_change()

func _on_node_added(node: Node):
	"""Handle new nodes being added to detect scene managers"""
	# This helps us detect when scene managers are ready
	if node.name.ends_with("SceneManager"):
		print("🎭 Scene manager detected: ", node.name)

# === GAME SESSION MANAGEMENT ===

func start_game_session():
	"""Start a new game session (called when transitioning from lobby to main game)"""
	if is_game_session_active:
		print("⚠️ Game session already active, not starting new one")
		return
	
	print("🚀 Starting new game session")
	is_game_session_active = true
	game_session_id = str(Time.get_ticks_msec())
	game_time_remaining = GAME_DURATION
	is_game_active = false
	game_ended = false
	current_scene_name = ""
	
	# Clear previous session data
	scene_transition_data.clear()
	last_scene_player_positions.clear()
	
	print("✅ Game session started with ID: ", game_session_id)

func end_game_session():
	"""End the current game session"""
	print("🏁 Ending game session: ", game_session_id)
	
	is_game_session_active = false
	is_game_active = false
	game_ended = true
	
	if game_timer:
		game_timer.stop()
	
	# Remove persistent timer UI
	if current_timer_ui and is_instance_valid(current_timer_ui):
		print("🗑️ Removing persistent timer UI on session end")
		current_timer_ui.queue_free()
		current_timer_ui = null
	
	# Clear session data
	scene_transition_data.clear()
	last_scene_player_positions.clear()
	
	print("✅ Game session ended")

func is_session_active() -> bool:
	"""Check if a game session is currently active"""
	return is_game_session_active

# === GAME TIMER MANAGEMENT ===

func setup_game_timer():
	"""Initialize the persistent game timer"""
	game_timer = Timer.new()
	game_timer.name = "GlobalGameTimer"
	game_timer.wait_time = 1.0  # Update every second
	game_timer.autostart = false
	game_timer.timeout.connect(_on_game_timer_tick)
	add_child(game_timer)
	print("⏱️ Global game timer created")

func start_game_timer():
	"""Start the game timer (called when first player spawns)"""
	if not is_game_session_active:
		print("⚠️ Cannot start timer - no active game session")
		return
	
	if is_game_active:
		print("⚠️ Game timer already running")
		return
	
	print("🚀 Starting global game timer!")
	is_game_active = true
	game_ended = false
	game_started_timestamp = Time.get_unix_time_from_system()
	game_timer.start()
	
	# Notify all systems that game started
	game_started.emit()
	
	# If we're the server, notify all clients
	if multiplayer.is_server():
		sync_game_started.rpc()

@rpc("authority", "reliable")
func sync_game_started():
	"""Sync game start to all clients"""
	if not multiplayer.is_server():
		is_game_active = true
		game_ended = false
		game_started_timestamp = Time.get_unix_time_from_system()
		game_started.emit()
		print("📡 Received game start sync from server")

func _on_game_timer_tick():
	"""Handle timer tick - runs globally"""
	if not is_game_session_active or game_ended:
		return
	
	game_time_remaining -= 1.0
	
	# Emit signal for UI updates
	game_time_updated.emit(game_time_remaining)
	
	# Check if time is up
	if game_time_remaining <= 0.0:
		end_game_timer()

func end_game_timer():
	"""End the game timer and trigger game end"""
	print("⏰ Game time is up!")
	game_ended = true
	is_game_active = false
	
	if game_timer:
		game_timer.stop()
	
	# Emit signal for game end
	game_timer_ended.emit()
	
	# Evaluate all players for end game conditions
	call_deferred("evaluate_all_players_for_end_game")

func evaluate_all_players_for_end_game():
	"""Find and evaluate all players when timer ends"""
	print("📊 Evaluating all players for end game conditions...")
	
	# Find the current scene manager
	var scene_manager = get_current_scene_manager()
	if scene_manager:
		# Get all player nodes
		var players = scene_manager.get_children().filter(func(child): return child.name.begins_with("Player_"))
		print("📊 Found ", players.size(), " players to evaluate")
		
		for player in players:
			if player.has_method("evaluate_end_game_condition"):
				print("📊 Evaluating player: ", player.name)
				player.evaluate_end_game_condition()
	else:
		print("❌ No scene manager found for player evaluation")
	
	# After evaluating all players, transition to GameEnd scene
	print("🏁 Transitioning to GameEnd scene...")
	call_deferred("transition_to_game_end")

func transition_to_game_end():
	"""Transition to the GameEnd scene"""
	print("🏁 Starting transition to GameEnd scene...")
	
	# Save final player states before transitioning
	save_all_player_states()
	
	# Transition to GameEnd scene
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/GameEnd.tscn")
		print("✅ Transitioning to GameEnd scene")
	else:
		print("❌ Error: Cannot access scene tree for GameEnd transition")

func save_all_player_states():
	"""Save all current player states before ending the game"""
	print("💾 Saving all player states before game end...")
	
	var scene_manager = get_current_scene_manager()
	if scene_manager:
		var players = scene_manager.get_children().filter(func(child): return child.name.begins_with("Player_"))
		for player in players:
			if "peer_id" in player and player.peer_id != null:
				var peer_id = player.peer_id
				var player_data = {
					"name": player.player_name,
					"sprite_path": player.sprite_path if "sprite_path" in player else "",
					"health": player.health,
					"social": player.social,
					"ccat_score": player.ccat_score,
					"position": player.global_position,
					"is_eliminated": player.is_eliminated if "is_eliminated" in player else false,
					"game_outcome": player.game_outcome if "game_outcome" in player else "",
					"ui_visible": player.ui_visible if "ui_visible" in player else false,
					"decay_timer_active": player.decay_timer if "decay_timer" in player else null,
					"interaction_cooldowns": player.interaction_cooldowns if "interaction_cooldowns" in player else {},
					"last_direction": player.last_direction if "last_direction" in player else Vector2(0, 1)
				}
				PlayerData.store_complete_player_state(peer_id, player_data)
				print("💾 Saved final state for player ", peer_id)

func get_current_scene_manager() -> Node:
	"""Get the current scene's scene manager"""
	var current_scene = get_tree().current_scene
	if not current_scene:
		return null
	
	# Look for scene managers
	for child in current_scene.get_children():
		if child.name.ends_with("SceneManager"):
			return child
	
	return null

# === TIMER UI MANAGEMENT ===

func setup_persistent_timer_ui():
	"""Setup persistent timer UI that survives scene transitions"""
	print("🖥️ setup_persistent_timer_ui called - Scene: ", current_scene_name)
	print("🖥️ is_game_session_active: ", is_game_session_active)
	print("🖥️ timer_ui_scenes: ", timer_ui_scenes)
	print("🖥️ timer_ui_scenes.has(current_scene_name): ", timer_ui_scenes.has(current_scene_name))
	
	if not is_game_session_active or not timer_ui_scenes.has(current_scene_name):
		print("❌ Timer UI setup skipped for scene: ", current_scene_name)
		return
	
	# Only create timer UI if it doesn't exist
	if not current_timer_ui or not is_instance_valid(current_timer_ui):
		print("🔧 Creating persistent timer UI")
		current_timer_ui = create_timer_ui()
		
		# Add to scene tree root instead of individual scenes for persistence
		var scene_tree = get_tree()
		if scene_tree:
			scene_tree.root.add_child(current_timer_ui)
			print("✅ Persistent timer UI added to scene tree root")
		else:
			print("❌ Failed to get scene tree for timer UI")
			return
	else:
		print("✅ Timer UI already exists and is valid")
	
	# Update timer display
	update_timer_display()
	print("✅ Persistent timer UI setup complete for scene: ", current_scene_name)

func setup_timer_ui_for_scene(scene_node: Node):
	"""Legacy function - now uses persistent timer UI"""
	print("🖥️ setup_timer_ui_for_scene called (legacy) - delegating to persistent UI")
	setup_persistent_timer_ui()

func create_timer_ui() -> CanvasLayer:
	"""Create the timer UI that can be added to any scene"""
	# Create a CanvasLayer for UI that stays on screen
	var timer_canvas = CanvasLayer.new()
	timer_canvas.name = "GlobalTimerCanvas"
	
	# Create the main timer container
	var timer_container = Control.new()
	timer_container.name = "TimerContainer"
	timer_container.layout_mode = 3
	timer_container.anchors_preset = 0  # Top-left preset
	timer_container.anchor_left = 0.0
	timer_container.anchor_right = 0.0
	timer_container.anchor_top = 0.0
	timer_container.anchor_bottom = 0.0
	timer_container.offset_left = 15.0
	timer_container.offset_top = 15.0
	timer_container.offset_right = 265.0
	timer_container.offset_bottom = 95.0
	timer_container.z_index = 100
	timer_canvas.add_child(timer_container)
	
	# Create background box
	var timer_background = ColorRect.new()
	timer_background.name = "TimerBackground"
	timer_background.color = Color(0.0, 0.0, 0.0, 0.8)
	timer_background.size = Vector2(250, 80)
	timer_background.position = Vector2(0, 0)
	timer_background.z_index = 1
	timer_container.add_child(timer_background)
	
	# Create border style
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color.TRANSPARENT
	border_style.border_width_left = 4
	border_style.border_width_right = 4
	border_style.border_width_top = 4
	border_style.border_width_bottom = 4
	border_style.border_color = Color.WHITE
	border_style.corner_radius_top_left = 12
	border_style.corner_radius_top_right = 12
	border_style.corner_radius_bottom_left = 12
	border_style.corner_radius_bottom_right = 12
	timer_background.add_theme_stylebox_override("normal", border_style)
	
	# Create the timer label
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = format_time(game_time_remaining)
	timer_label.size = Vector2(250, 80)
	timer_label.position = Vector2(0, 0)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.z_index = 10
	
	# Style the timer label
	timer_label.add_theme_font_size_override("font_size", 48)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	timer_label.add_theme_constant_override("outline_size", 4)
	
	timer_container.add_child(timer_label)
	
	return timer_canvas

func update_timer_display():
	"""Update the timer display in current scene"""
	if not current_timer_ui or not is_instance_valid(current_timer_ui):
		return
	
	var timer_label = current_timer_ui.find_child("TimerLabel", true, false)
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

# === SCENE TRANSITION MANAGEMENT ===

func prepare_scene_transition(from_scene: String, to_scene: String):
	"""Prepare for scene transition by saving current state"""
	print("🎬 Preparing transition from ", from_scene, " to ", to_scene)
	
	scene_transition_started.emit(from_scene, to_scene)
	
	# Store current player states
	store_current_player_states()
	
	# Store scene-specific data
	scene_transition_data[from_scene] = {
		"timestamp": Time.get_unix_time_from_system(),
		"game_time_remaining": game_time_remaining,
		"is_game_active": is_game_active
	}

func store_current_player_states():
	"""Store current player states for scene transition"""
	var scene_manager = get_current_scene_manager()
	if not scene_manager:
		return
	
	var players = scene_manager.get_children().filter(func(child): return child.name.begins_with("Player_"))
	for player in players:
		if "peer_id" in player and player.peer_id != null:
			var peer_id = player.peer_id
			var player_data = {
				"name": player.player_name,
				"sprite_path": player.sprite_path if "sprite_path" in player else "",
				"health": player.health,
				"social": player.social,
				"ccat_score": player.ccat_score,
				"position": player.global_position,
				"is_eliminated": player.is_eliminated if "is_eliminated" in player else false,
				"scene": current_scene_name
			}
			PlayerData.store_player_data(peer_id, player_data)
			last_scene_player_positions[peer_id] = {
				"scene": current_scene_name,
				"position": player.global_position
			}

func get_game_time_remaining() -> float:
	"""Get remaining game time (for compatibility with existing code)"""
	return game_time_remaining

func is_game_running() -> bool:
	"""Check if game is currently active (for compatibility with existing code)"""
	return is_game_active and not game_ended and is_game_session_active

# === INITIALIZATION HELPERS ===

func initialize_for_main_scene():
	"""Initialize game state when entering main scene from lobby"""
	print("🎮 Initializing GameStateManager for main scene")
	start_game_session()
	detect_and_handle_scene_change()

func initialize_for_scene_transition():
	"""Initialize game state when transitioning between game scenes"""
	print("🎮 Initializing GameStateManager for scene transition")
	# Game session should already be active, just detect scene change
	# Timer UI setup is handled by detect_and_handle_scene_change()
	detect_and_handle_scene_change()

func setup_timer_ui_for_current_scene():
	"""Legacy function - now uses persistent timer UI"""
	print("🖥️ setup_timer_ui_for_current_scene called (legacy) - delegating to persistent UI")
	setup_persistent_timer_ui()

# Connect to game time updates to update UI
func _ready_complete():
	"""Complete initialization after all nodes are ready"""
	game_time_updated.connect(func(_time): update_timer_display())

# === UI SCALING FUNCTIONS ===

func get_ui_scale_factor_for_scene(scene_name: String = "") -> float:
	"""Get the UI scale factor for a given scene based on camera zoom differences"""
	if scene_name == "":
		scene_name = current_scene_name
	
	# Camera zoom levels:
	# Main scene: 4x zoom
	# Street scene: 1.2x zoom
	# Scale factor = Main zoom / Current zoom
	match scene_name:
		"Main":
			return 1.0  # No scaling needed for Main scene
		"Street":
			return 4.0 / 1.2  # 3.33x scaling to compensate for lower zoom
		_:
			return 1.0  # Default no scaling

func scale_interaction_prompts_for_scene():
	"""Scale all interaction prompts in the current scene to maintain readability"""
	print("🎨 Scaling interaction prompts for scene: ", current_scene_name)
	
	var scale_factor = get_ui_scale_factor_for_scene()
	var current_scene = get_tree().current_scene
	
	if not current_scene:
		return
	
	# Find all InteractionPrompt labels in the scene
	var interaction_prompts = find_children_recursive(current_scene, "InteractionPrompt")
	
	for prompt in interaction_prompts:
		if prompt is Label:
			prompt.scale = Vector2(scale_factor, scale_factor)
			print("🎨 Scaled interaction prompt '", prompt.text, "' by factor: ", scale_factor)

func find_children_recursive(node: Node, name_pattern: String) -> Array[Node]:
	"""Recursively find all children with names matching the pattern"""
	var found_nodes: Array[Node] = []
	
	# Check current node
	if node.name == name_pattern:
		found_nodes.append(node)
	
	# Check all children recursively
	for child in node.get_children():
		found_nodes.append_array(find_children_recursive(child, name_pattern))
	
	return found_nodes

# Connect signal after _ready
func _init():
	if not game_time_updated.is_connected(func(_time): update_timer_display()):
		call_deferred("_ready_complete") 