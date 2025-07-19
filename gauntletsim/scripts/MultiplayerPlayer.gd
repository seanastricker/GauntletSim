# MultiplayerPlayer.gd - Networked player character for multiplayer sessions
# Handles individual player movement, stats, and interactions with RPC synchronization
extends CharacterBody2D

# Player stats with min/max constraints
@export var health: int = 50:
	set(value):
		health = clamp(value, 0, 50)
		if health_label and (peer_id == multiplayer.get_unique_id()):
			update_ui()

@export var social: int = 50:
	set(value):
		social = clamp(value, 0, 50)
		if social_label and (peer_id == multiplayer.get_unique_id()):
			update_ui()

@export var ccat_score: int = 50:
	set(value):
		ccat_score = clamp(value, 0, 50)
		if ccat_label and (peer_id == multiplayer.get_unique_id()):
			update_ui()

# Movement configuration
@export var speed: float = 200.0

# Player identification
@export var player_name: String = "":
	set(value):
		player_name = value
		if name_label:
			name_label.text = player_name

# Multiplayer-specific properties
@export var peer_id: int = 1:
	set(id):
		print("🔧 ⚠️  SETTER CALLED! Setting peer_id to ", id)
		peer_id = id
		print("🔧 ⚠️  SETTER COMPLETE! Peer ID set successfully!")

# UI references
# All UI elements - created programmatically for consistency
var health_label: Label = null
var health_bar: ProgressBar = null
var social_label: Label = null
var social_bar: ProgressBar = null
var ccat_label: Label = null
var ccat_bar: ProgressBar = null
@onready var name_label: Label = $NameLabel
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Stat decay system
var decay_timer: Timer
var decay_rate: float = 3.0  # 3 seconds for testing (1 second when Health = 0)

# Interaction cooldowns and movement tracking
var interaction_cooldowns: Dictionary = {}
var last_direction = Vector2(0, 1)
var was_moving_last_frame = false

# Game state tracking
var is_eliminated: bool = false
var game_outcome: String = ""  # "win", "lose_ccat", "lose_social", or ""
var notification_label: Label

func _ready() -> void:
	"""Initialize basic systems - player data will be loaded separately"""
	print("🎮 MultiplayerPlayer _ready() called for peer_id: ", peer_id)
	
	print("🎮 _ready(): Setting up collision...")
	# Setup basic systems
	setup_collision()
	print("🎮 _ready(): Collision setup complete")
	
	print("🎮 _ready(): Setting up animation...")
	update_animation(Vector2.ZERO)
	print("🎮 _ready(): Animation setup complete")
	
	print("🎮 _ready(): Ready function complete!")
	# Player data will be loaded when initialize_player() is called

func initialize_player_with_id(id: int):
	"""Load player data and configure the player - bypasses setter issues"""
	print("🎮 ===== INITIALIZE_PLAYER_WITH_ID STARTING =====")
	print("🎮 initialize_player_with_id() called with ID: ", id)
	
	print("🎮 About to set peer_id...")
	# Set peer_id directly without using the setter
	peer_id = id
	print("🎮 Peer ID set directly to: ", peer_id)
	
	# CRITICAL: Set multiplayer authority FIRST
	print("🔧 Setting multiplayer authority for peer ", peer_id)
	set_multiplayer_authority(peer_id)
	print("🔧 ✅ Authority set successfully for ", peer_id)
	
	# Load player data based on peer_id
	print("🎮 Current peer_id: ", peer_id)
	print("🎮 All registered players: ", PlayerData.get_all_players())
	print("🎮 Current multiplayer unique_id: ", multiplayer.get_unique_id())
	
	var player_data = PlayerData.get_player_data(peer_id)
	print("🎮 Retrieved player_data for peer ", peer_id, ": ", player_data)
	
	if player_data.is_empty():
		print("🎮 Using fallback PlayerData: name='", PlayerData.player_name, "'")
		# Fallback for host or single player
		player_name = PlayerData.player_name
		load_sprite(PlayerData.player_sprite_path)
	else:
		print("🎮 Using registry data: name='", player_data["name"], "'")
		player_name = player_data["name"]
		load_sprite(player_data["sprite_path"])
		health = player_data["health"]
		social = player_data["social"]
		ccat_score = player_data["ccat_score"]
		global_position = player_data["position"]
	
	# Setup UI - only visible for local player
	setup_ui()
	
	# Connect to player registry updates to refresh names if needed
	if not PlayerData.player_registry_updated.is_connected(_on_player_registry_updated):
		PlayerData.player_registry_updated.connect(_on_player_registry_updated)
	call_deferred("setup_notification_ui")
	
	# Setup systems
	setup_decay_timer()
	
	# Start with idle animation for all players (local and remote)
	update_animation(Vector2.ZERO)
	
	# Only process physics for our own character
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	set_physics_process(is_local_player)
	print("🎮 Physics processing enabled for peer ", peer_id, ": ", is_local_player)
	
	print("🎮 Player initialization complete!")

func set_peer_id_and_authority(id: int):
	"""Set peer ID and multiplayer authority - called from MainSceneManager"""
	print("🔧 set_peer_id_and_authority called with ID: ", id)
	
	peer_id = id
	print("🔧 Peer ID set to: ", peer_id)
	
	# Set multiplayer authority
	if is_inside_tree():
		print("🔧 Node is in tree, setting authority...")
		print("🔧 Multiplayer peer exists: ", multiplayer.has_multiplayer_peer())
		print("🔧 Is server: ", multiplayer.is_server())
		
		# Set multiplayer authority (no try/catch in GDScript)
		set_multiplayer_authority(id)
		print("🔧 ✅ Authority set successfully for ", id)
	else:
		print("🔧 ❌ Node not in tree!")

func create_health_ui():
	"""Create Health UI elements programmatically"""
	var vbox = get_node_or_null("UI/StatsDisplay/VBoxContainer")
	if not vbox:
		print("❌ VBoxContainer not found, cannot create Health UI")
		return
	
	# Create HealthContainer
	var health_container = Control.new()
	health_container.name = "HealthContainer_Runtime"
	health_container.layout_mode = 2
	health_container.custom_minimum_size = Vector2(480, 70)  # Same size as others
	
	# Insert at position 0 (first)
	vbox.add_child(health_container)
	vbox.move_child(health_container, 0)
	
	# Create HealthBar
	var health_progress_bar = ProgressBar.new()
	health_progress_bar.name = "HealthBar"
	health_progress_bar.size = Vector2(480, 70)  # Same size as Social and CCAT
	health_progress_bar.position = Vector2(0, 0)
	health_progress_bar.min_value = 0
	health_progress_bar.max_value = 50
	health_progress_bar.value = health
	health_progress_bar.show_percentage = false  # Hide percentage display
	health_progress_bar.z_index = 2
	health_container.add_child(health_progress_bar)
	
	# Create HealthLabel (positioned inside the progress bar)
	var health_text_label = Label.new()
	health_text_label.name = "HealthLabel"
	health_text_label.text = "Health: " + str(health) + "/50"
	health_text_label.position = Vector2(10, 20)  # Inside the progress bar
	health_text_label.size = Vector2(460, 30)  # Fits within bar
	health_text_label.z_index = 10
	health_container.add_child(health_text_label)
	
	# Store references
	health_bar = health_progress_bar
	health_label = health_text_label

func create_social_ui():
	"""Create Social UI elements programmatically if missing from scene"""
	var vbox = get_node_or_null("UI/StatsDisplay/VBoxContainer")
	if not vbox:
		print("❌ VBoxContainer not found, cannot create Social UI")
		return
	
	# Create SocialContainer
	var social_container = Control.new()
	social_container.name = "SocialContainer_Runtime"
	social_container.layout_mode = 2
	social_container.custom_minimum_size = Vector2(480, 70)  # Doubled from 240x35
	
	# Insert between Health and CCAT (position 1)
	vbox.add_child(social_container)
	vbox.move_child(social_container, 1)
	
	# Add subtle danger zone background highlight
	var danger_zone = ColorRect.new()
	danger_zone.name = "SocialDangerZone"
	danger_zone.color = Color(1, 0, 0, 0.08)  # Very subtle red tint
	danger_zone.size = Vector2(240, 70)  # From 0 to threshold (25/50 = 50% of 480px = 240px)
	danger_zone.position = Vector2(0, 0)
	danger_zone.z_index = 1
	social_container.add_child(danger_zone)
	
	# Create SocialBar
	var social_progress_bar = ProgressBar.new()
	social_progress_bar.name = "SocialBar"
	social_progress_bar.size = Vector2(480, 70)  # Doubled from 240x35
	social_progress_bar.position = Vector2(0, 0)
	social_progress_bar.min_value = 0
	social_progress_bar.max_value = 50
	social_progress_bar.value = social
	social_progress_bar.show_percentage = false  # Hide percentage display
	social_progress_bar.z_index = 2
	social_container.add_child(social_progress_bar)
	
	# Threshold line for Social = 25 (Simple math: 25 * 9.6px = 240px)
	var threshold_position = 25 * (480.0 / 50.0)  # 25 * 9.6 = 240px exactly
	
	# Drop shadow for threshold line
	var threshold_shadow = ColorRect.new()
	threshold_shadow.name = "SocialThresholdShadow"
	threshold_shadow.color = Color(0, 0, 0, 0.4)  # Dark shadow
	threshold_shadow.size = Vector2(6, 74)  # Slightly larger for shadow effect
	threshold_shadow.position = Vector2(threshold_position + 1, -2)  # Offset for shadow
	threshold_shadow.z_index = 3
	social_container.add_child(threshold_shadow)
	
	# Main threshold line
	var threshold_line = ColorRect.new()
	threshold_line.name = "SocialThresholdLine"
	threshold_line.color = Color(1, 0.8, 0.2, 0.9)  # Golden yellow
	threshold_line.size = Vector2(6, 70)  # Match bar height exactly
	threshold_line.position = Vector2(threshold_position, 0)  # Exactly at Social = 25
	threshold_line.z_index = 10
	social_container.add_child(threshold_line)
	
	# Threshold notch markers (centered on the line)
	var top_notch = ColorRect.new()
	top_notch.name = "SocialTopNotch"
	top_notch.color = Color(1, 0.8, 0.2, 0.9)  # Golden yellow
	top_notch.size = Vector2(16, 6)  # Doubled from 8x3
	top_notch.position = Vector2(threshold_position - 5, -8)  # Centered above line
	top_notch.z_index = 10
	social_container.add_child(top_notch)
	
	var bottom_notch = ColorRect.new()
	bottom_notch.name = "SocialBottomNotch"
	bottom_notch.color = Color(1, 0.8, 0.2, 0.9)  # Golden yellow
	bottom_notch.size = Vector2(16, 6)  # Doubled from 8x3
	bottom_notch.position = Vector2(threshold_position - 5, 72)  # Centered below line
	bottom_notch.z_index = 10
	social_container.add_child(bottom_notch)
	
	# Threshold label
	var threshold_label = Label.new()
	threshold_label.name = "SocialThresholdLabel"
	threshold_label.text = "25"
	threshold_label.add_theme_font_size_override("font_size", 16)
	threshold_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	threshold_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	threshold_label.add_theme_constant_override("outline_size", 2)
	threshold_label.position = Vector2(threshold_position - 8, 78)  # Centered below notch
	threshold_label.z_index = 10
	social_container.add_child(threshold_label)
	
	# Create SocialLabel (positioned inside the progress bar)
	var social_text_label = Label.new()
	social_text_label.name = "SocialLabel"
	social_text_label.text = "Social: " + str(social) + "/50"
	social_text_label.position = Vector2(10, 20)  # Inside the progress bar
	social_text_label.size = Vector2(460, 30)  # Fits within bar
	social_text_label.z_index = 10
	social_container.add_child(social_text_label)
	
	# Store references
	social_bar = social_progress_bar
	social_label = social_text_label

func create_ccat_ui():
	"""Create CCAT UI elements programmatically if missing from scene"""
	var vbox = get_node_or_null("UI/StatsDisplay/VBoxContainer")
	if not vbox:
		print("❌ VBoxContainer not found, cannot create CCAT UI")
		return
	
	# Create CCATContainer
	var ccat_container = Control.new()
	ccat_container.name = "CCATContainer_Runtime"
	ccat_container.layout_mode = 2
	ccat_container.custom_minimum_size = Vector2(480, 70)  # Doubled from 240x35
	
	# Insert at position 2 (after Health and Social)
	vbox.add_child(ccat_container)
	vbox.move_child(ccat_container, 2)
	
	# Add subtle danger zone background highlight
	var danger_zone = ColorRect.new()
	danger_zone.name = "CCATDangerZone"
	danger_zone.color = Color(1, 0, 0, 0.08)  # Very subtle red tint
	danger_zone.size = Vector2(384, 70)  # From 0 to threshold (40/50 = 80% of 480px = 384px)
	danger_zone.position = Vector2(0, 0)
	danger_zone.z_index = 1
	ccat_container.add_child(danger_zone)
	
	# Create CCATBar
	var ccat_progress_bar = ProgressBar.new()
	ccat_progress_bar.name = "CCATBar"
	ccat_progress_bar.size = Vector2(480, 70)  # Doubled from 240x35
	ccat_progress_bar.position = Vector2(0, 0)
	ccat_progress_bar.min_value = 0
	ccat_progress_bar.max_value = 50
	ccat_progress_bar.value = ccat_score
	ccat_progress_bar.show_percentage = false  # Hide percentage display
	ccat_progress_bar.z_index = 2
	ccat_container.add_child(ccat_progress_bar)
	
	# Threshold line for CCAT = 40 (Simple math: 40 * 9.6px = 384px)
	var threshold_position = 40 * (480.0 / 50.0)  # 40 * 9.6 = 384px exactly
	
	# Drop shadow for threshold line
	var threshold_shadow = ColorRect.new()
	threshold_shadow.name = "CCATThresholdShadow"
	threshold_shadow.color = Color(0, 0, 0, 0.4)  # Dark shadow
	threshold_shadow.size = Vector2(6, 74)  # Slightly larger for shadow effect
	threshold_shadow.position = Vector2(threshold_position + 1, -2)  # Offset for shadow
	threshold_shadow.z_index = 3
	ccat_container.add_child(threshold_shadow)
	
	# Main threshold line
	var threshold_line = ColorRect.new()
	threshold_line.name = "CCATThresholdLine"
	threshold_line.color = Color(1, 0.8, 0.2, 0.9)  # Golden yellow
	threshold_line.size = Vector2(6, 70)  # Match bar height exactly
	threshold_line.position = Vector2(threshold_position, 0)  # Exactly at CCAT = 40
	threshold_line.z_index = 10
	ccat_container.add_child(threshold_line)
	
	# Threshold notch markers (centered on the line)
	var top_notch = ColorRect.new()
	top_notch.name = "CCATTopNotch"
	top_notch.color = Color(1, 0.8, 0.2, 0.9)  # Golden yellow
	top_notch.size = Vector2(16, 6)  # Doubled from 8x3
	top_notch.position = Vector2(threshold_position - 5, -8)  # Centered above line
	top_notch.z_index = 10
	ccat_container.add_child(top_notch)
	
	var bottom_notch = ColorRect.new()
	bottom_notch.name = "CCATBottomNotch"
	bottom_notch.color = Color(1, 0.8, 0.2, 0.9)  # Golden yellow
	bottom_notch.size = Vector2(16, 6)  # Doubled from 8x3
	bottom_notch.position = Vector2(threshold_position - 5, 72)  # Centered below line
	bottom_notch.z_index = 10
	ccat_container.add_child(bottom_notch)
	
	# Threshold label
	var threshold_label = Label.new()
	threshold_label.name = "CCATThresholdLabel"
	threshold_label.text = "40"
	threshold_label.add_theme_font_size_override("font_size", 16)
	threshold_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	threshold_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	threshold_label.add_theme_constant_override("outline_size", 2)
	threshold_label.position = Vector2(threshold_position - 8, 78)  # Centered below notch
	threshold_label.z_index = 10
	ccat_container.add_child(threshold_label)
	
	# Create CCATLabel (positioned inside the progress bar)
	var ccat_text_label = Label.new()
	ccat_text_label.name = "CCATLabel"
	ccat_text_label.text = "CCAT: " + str(ccat_score) + "/50"
	ccat_text_label.position = Vector2(10, 20)  # Inside the progress bar
	ccat_text_label.size = Vector2(460, 30)  # Fits within bar
	ccat_text_label.z_index = 10
	ccat_container.add_child(ccat_text_label)
	
	# Store references
	ccat_bar = ccat_progress_bar
	ccat_label = ccat_text_label

func style_ui_elements():
	"""Apply styling to UI elements programmatically"""
	# Style all stat labels with larger fonts for the bigger UI
	for label in [health_label, social_label, ccat_label]:
		if label:
			label.add_theme_font_size_override("font_size", 24)  # Increased from default for better visibility
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			label.add_theme_constant_override("outline_size", 3)  # Slightly thicker outline for larger text

func verify_ui_paths():
	"""Verify that all UI node paths are working correctly"""
	print("🔍 Verifying UI paths...")
	var ui_layer = get_node_or_null("UI")
	print("🔍 UI layer: ", ui_layer != null)
	var stats_display = get_node_or_null("UI/StatsDisplay")
	print("🔍 StatsDisplay: ", stats_display != null)
	var vbox = get_node_or_null("UI/StatsDisplay/VBoxContainer")
	print("🔍 VBoxContainer: ", vbox != null)
	var health_container = get_node_or_null("UI/StatsDisplay/VBoxContainer/HealthContainer")
	print("🔍 HealthContainer: ", health_container != null)

func setup_ui():
	"""Configure UI visibility and styling"""
	print("🎮 setup_ui(): peer_id=", peer_id, " multiplayer_authority=", is_multiplayer_authority())
	print("🎮 setup_ui(): current unique_id=", multiplayer.get_unique_id())
	print("🎮 setup_ui(): player_name=", player_name)
	
	# Resize UI containers to accommodate larger progress bars
	resize_ui_containers()
	
	# Always create all UI programmatically for consistency
	print("🔧 Creating Health, Social, and CCAT UI elements...")
	create_health_ui()
	create_social_ui()
	create_ccat_ui()
	
	# Style and update the name label for ALL players (local and remote)
	print("🏷️ Setting name label for peer ", peer_id, " with name: '", player_name, "'")
	if name_label:
		name_label.text = player_name
		name_label.add_theme_color_override("font_color", Color(1, 1, 1))
		name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		name_label.add_theme_constant_override("outline_size", 4)
		print("✅ Name label updated to: '", name_label.text, "' for peer ", peer_id)
	else:
		print("❌ Name label is null for peer ", peer_id, "! Checking node path...")
		var name_node = get_node_or_null("NameLabel")
		if name_node:
			print("⚠️ Found NameLabel node manually for peer ", peer_id, ", updating @onready reference")
			name_label = name_node
			name_label.text = player_name
			print("✅ Name fixed: '", name_label.text, "' for peer ", peer_id)
		else:
			print("❌ NameLabel node not found in scene tree for peer ", peer_id, "!")
	
	var ui_layer = $UI
	# Show UI only for the local player (authority should match local peer ID)
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	ui_layer.visible = is_local_player
	
	print("🎮 UI visible for peer ", peer_id, ": ", ui_layer.visible)
	
	if is_local_player:
		# Apply styling to UI elements after creation
		style_ui_elements()
		# Update UI with initial values
		update_ui()
	else:
		# Dim non-local players slightly for visual distinction
		modulate = Color(0.9, 0.9, 0.9, 1.0)

func _on_player_registry_updated():
	"""Called when player registry is updated - refresh player name if needed"""
	print("🔄 Player registry updated for peer ", peer_id, " - checking if name needs refresh")
	var updated_data = PlayerData.get_player_data(peer_id)
	if not updated_data.is_empty():
		var new_name = updated_data["name"]
		if new_name != player_name:
			print("🏷️ Updating player name from '", player_name, "' to '", new_name, "' for peer ", peer_id)
			player_name = new_name
			if name_label:
				name_label.text = player_name
				print("✅ Name label refreshed to: '", name_label.text, "' for peer ", peer_id)

func resize_ui_containers():
	"""Resize the UI containers to accommodate larger progress bars"""
	var stats_display = get_node_or_null("UI/StatsDisplay")
	if stats_display:
		# Calculate required height: 3 bars (70px each) + spacing (5px each) + notch margins (12px total) + padding
		var required_height = (70 * 3) + (5 * 2) + 12 + 20  # = 252px total
		var required_width = 480 + 40  # Progress bar width + padding = 520px
		
		# Update the StatsDisplay container size
		stats_display.offset_top = -required_height - 10  # Move up to accommodate larger size
		stats_display.offset_right = required_width + 10
		
		print("📏 Resized StatsDisplay container to accommodate 2x larger progress bars")
		print("📏 New height: ", required_height, "px, New width: ", required_width, "px")
	else:
		print("❌ Could not find StatsDisplay container to resize")
	
	# Also ensure VBoxContainer has proper spacing for the larger elements
	var vbox = get_node_or_null("UI/StatsDisplay/VBoxContainer")
	if vbox:
		vbox.add_theme_constant_override("separation", 8)  # Increase spacing between bars
		print("📏 Updated VBoxContainer separation for larger elements")

func load_sprite(sprite_path: String):
	"""Load and configure player sprite animations"""
	if not sprite_path:
		return
		
	var sprite_sheet = load(sprite_path)
	if not sprite_sheet:
		return
	
	if not animated_sprite:
		return
		
	var new_sprite_frames = SpriteFrames.new()
	
	var anim_definitions = {
		"idle_down": {"y": 32, "x_start": 288, "frames": 6},
		"idle_up": {"y": 32, "x_start": 96, "frames": 6},
		"idle_left": {"y": 32, "x_start": 192, "frames": 6},
		"idle_right": {"y": 32, "x_start": 0, "frames": 6},
		"walk_down": {"y": 64, "x_start": 288, "frames": 6},
		"walk_up": {"y": 64, "x_start": 96, "frames": 6},
		"walk_left": {"y": 64, "x_start": 192, "frames": 6},
		"walk_right": {"y": 64, "x_start": 0, "frames": 6}
	}

	for anim_name in anim_definitions:
		var anim_data = anim_definitions[anim_name]
		new_sprite_frames.add_animation(anim_name)
		new_sprite_frames.set_animation_loop(anim_name, true)
		new_sprite_frames.set_animation_speed(anim_name, 5.0)
		
		for i in range(anim_data["frames"]):
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = sprite_sheet
			atlas_texture.region = Rect2(anim_data["x_start"] + (i * 16), anim_data["y"], 16, 32)
			new_sprite_frames.add_frame(anim_name, atlas_texture)

	animated_sprite.sprite_frames = new_sprite_frames

func _physics_process(_delta: float) -> void:
	"""Handle movement and synchronization"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player:
		# Handle input and movement for local player
		var input_vector = get_input_vector()
		velocity = input_vector * speed
		move_and_slide()
		update_animation(input_vector)
		
		# Track if player is currently moving
		var is_moving_now = (velocity.length() > 0 or input_vector.length() > 0)
		
		# Sync position to other players when moving OR when just stopped moving
		if is_moving_now or was_moving_last_frame:
			sync_position.rpc(global_position, input_vector)
		
		# Update movement state for next frame
		was_moving_last_frame = is_moving_now

func get_input_vector() -> Vector2:
	"""Get normalized input vector from player input"""
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	return input_vector.normalized()

@rpc("unreliable")
func sync_position(pos: Vector2, input_vec: Vector2):
	"""Synchronize position and animation across network"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if not is_local_player:
		global_position = pos
		update_animation(input_vec)

@rpc("reliable")
func sync_stats(new_health: int, new_social: int, new_ccat: int):
	"""Synchronize stats across network"""
	health = new_health
	social = new_social
	ccat_score = new_ccat
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player:
		update_ui()

# Stat modification functions with RPC synchronization
func modify_health(amount: int) -> void:
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player and not is_eliminated:
		var old_health = health
		self.health = health + amount
		sync_stats.rpc(health, social, ccat_score)
		
		# Check if health status changed (affects decay rate)
		if (old_health == 0) != (health == 0):
			update_decay_rate()

func modify_social(amount: int) -> void:
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player and not is_eliminated:
		self.social = social + amount
		sync_stats.rpc(health, social, ccat_score)

func modify_ccat_score(amount: int) -> void:
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	print("📊 MODIFY_CCAT_SCORE - Player: ", player_name, " (Peer: ", peer_id, ") Amount: ", amount)
	print("📊 Is Local Player: ", is_local_player, " | Is Eliminated: ", is_eliminated)
	print("📊 CCAT before change: ", ccat_score)
	
	if is_local_player and not is_eliminated:
		print("📊 Applying CCAT change to local player")
		self.ccat_score = ccat_score + amount
		print("📊 CCAT after change: ", ccat_score)
		sync_stats.rpc(health, social, ccat_score)
		print("📊 Stats synced via RPC")
		
		# Check for instant lose condition after CCAT change
		check_instant_lose_conditions()
	else:
		print("📊 Skipping CCAT change - not local player or already eliminated")

func setup_decay_timer() -> void:
	"""Initialize the stat decay system"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	print("⏲️ SETUP_DECAY_TIMER - Player: ", player_name, " (Peer: ", peer_id, ")")
	print("⏲️ Is Local Player: ", is_local_player)
	print("⏲️ Multiplayer Unique ID: ", multiplayer.get_unique_id())
	
	if is_local_player:
		print("⏲️ Setting up decay timer for LOCAL player ", player_name)
		decay_timer = Timer.new()
		decay_timer.wait_time = get_current_decay_rate()
		decay_timer.autostart = true
		decay_timer.timeout.connect(_on_decay_timer_timeout)
		add_child(decay_timer)
		print("⏲️ Decay timer created with wait_time: ", decay_timer.wait_time, " seconds")
	else:
		print("⏲️ NOT setting up decay timer - this is a REMOTE player")

func update_decay_rate():
	"""Update the decay timer rate based on current health"""
	if decay_timer and not is_eliminated:
		var new_rate = get_current_decay_rate()
		decay_timer.wait_time = new_rate
		print("🕒 Decay rate updated to ", new_rate, " seconds (Health: ", health, ")")

func _on_decay_timer_timeout() -> void:
	"""Gradually decrease all stats over time"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	print("⏰ DECAY TIMER TIMEOUT - Player: ", player_name, " (Peer: ", peer_id, ")")
	print("⏰ Is Local Player: ", is_local_player, " | Is Eliminated: ", is_eliminated)
	print("⏰ Current stats - Health: ", health, " Social: ", social, " CCAT: ", ccat_score)
	
	if is_local_player and not is_eliminated:
		print("⏰ Applying decay to local player ", player_name)
		modify_health(-1)
		modify_social(-1)
		modify_ccat_score(-1)
		print("⏰ After decay - Health: ", health, " Social: ", social, " CCAT: ", ccat_score)
	else:
		print("⏰ Skipping decay - not local player or already eliminated")

func setup_collision():
	"""Setup collision shape"""
	var collision_shape = $CollisionShape2D
	if collision_shape.shape == null:
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(24, 17)
		collision_shape.shape = rect_shape

func update_animation(input_vector: Vector2) -> void:
	"""Update character animation based on movement"""
	if not animated_sprite:
		return

	if input_vector != Vector2.ZERO:
		last_direction = input_vector

	var anim_direction = "down"
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			anim_direction = "right"
		else:
			anim_direction = "left"
	else:
		if last_direction.y > 0:
			anim_direction = "down"
		else:
			anim_direction = "up"
			
	var anim_prefix = "walk" if input_vector != Vector2.ZERO else "idle"
	var new_animation = anim_prefix + "_" + anim_direction
	
	if animated_sprite.animation != new_animation or not animated_sprite.is_playing():
		animated_sprite.play(new_animation)

func update_ui() -> void:
	"""Update the stats display UI with progress bars and text"""
	# Update Health
	if health_label and health_bar:
		health_label.text = "Health: " + str(health) + "/50"
		health_bar.value = health
		# Fixed color: Always green for health
		health_bar.modulate = Color.GREEN
	
	# Update Social
	if social_label and social_bar:
		social_label.text = "Social: " + str(social) + "/50"
		social_bar.value = social
		# Fixed color: Always blue for social
		social_bar.modulate = Color.BLUE
	
	# Update CCAT
	if ccat_label and ccat_bar:
		ccat_label.text = "CCAT: " + str(ccat_score) + "/50"
		ccat_bar.value = ccat_score
		# Fixed color: Always red for CCAT score
		ccat_bar.modulate = Color.RED

# Interaction functions
func can_interact(interaction_type: String) -> bool:
	"""Check if player can perform interaction based on cooldown"""
	if interaction_type in interaction_cooldowns:
		return Time.get_ticks_msec() >= interaction_cooldowns[interaction_type]
	return true

func start_interaction_cooldown(interaction_type: String, cooldown_seconds: float) -> void:
	"""Start cooldown timer for specific interaction type"""
	interaction_cooldowns[interaction_type] = Time.get_ticks_msec() + (cooldown_seconds * 1000)

func work_at_desk() -> void:
	"""Handle working at office desk - increases CCAT, decreases Health/Social"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player:  # Removed cooldown check for testing
		modify_ccat_score(5)
		modify_health(-2)
		modify_social(-1)
		# start_interaction_cooldown("work", 10.0)  # Disabled for testing
		print(player_name + " worked at desk. CCAT +5, Health -2, Social -1")

func interact_with_social_npc():
	"""Handle social NPC interaction"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player:
		modify_social(5)
		print(player_name + " talked to a social NPC. Social +5")

# === WIN/LOSE SYSTEM ===

func setup_notification_ui():
	"""Create notification UI for win/lose messages"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player:
		
		notification_label = Label.new()
		notification_label.name = "NotificationLabel_" + str(peer_id)
		notification_label.text = ""
		
		# Use anchors for center positioning
		notification_label.anchor_left = 0.5
		notification_label.anchor_right = 0.5
		notification_label.anchor_top = 0.5
		notification_label.anchor_bottom = 0.5
		notification_label.offset_left = -150
		notification_label.offset_right = 150
		notification_label.offset_top = -50
		notification_label.offset_bottom = 50
		
		notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		notification_label.z_index = 200
		notification_label.visible = false
		
		# Style the notification
		notification_label.add_theme_font_size_override("font_size", 28)
		notification_label.add_theme_color_override("font_color", Color.WHITE)
		notification_label.add_theme_color_override("font_outline_color", Color.BLACK)
		notification_label.add_theme_constant_override("outline_size", 4)
		
		# Add background
		var notification_bg = StyleBoxFlat.new()
		notification_bg.bg_color = Color(0.0, 0.0, 0.0, 0.8)
		notification_bg.border_width_left = 3
		notification_bg.border_width_right = 3
		notification_bg.border_width_top = 3
		notification_bg.border_width_bottom = 3
		notification_bg.border_color = Color.WHITE
		notification_bg.corner_radius_top_left = 15
		notification_bg.corner_radius_top_right = 15
		notification_bg.corner_radius_bottom_left = 15
		notification_bg.corner_radius_bottom_right = 15
		notification_label.add_theme_stylebox_override("normal", notification_bg)
		
		# Add to the scene tree at the top level for proper display
		var scene_root = get_tree().current_scene
		if scene_root:
			scene_root.add_child(notification_label)
			print("🎯 Notification UI created for local player ", peer_id)
		else:
			print("❌ Could not find scene root for notification UI")

func check_instant_lose_conditions():
	"""Check for conditions that cause immediate game loss"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	print("🔍 CHECKING INSTANT LOSE - Player: ", player_name, " (Peer: ", peer_id, ")")
	print("🔍 Is Local Player: ", is_local_player, " | Is Eliminated: ", is_eliminated)
	print("🔍 Current CCAT Score: ", ccat_score)
	
	if not is_local_player or is_eliminated:
		print("🔍 Skipping instant lose check - not local player or already eliminated")
		return
	
	# CCAT Score below 40 = instant elimination
	if ccat_score < 40:
		print("🚨 INSTANT ELIMINATION TRIGGERED! CCAT: ", ccat_score, " < 40")
		eliminate_player("lose_ccat", "You have been kicked out!")
		return
	else:
		print("🔍 CCAT score safe: ", ccat_score, " >= 40")

func eliminate_player(outcome: String, message: String):
	"""Eliminate a player from the game"""
	print("🚨 ELIMINATE_PLAYER CALLED for ", player_name, " - Outcome: ", outcome)
	print("🚨 Player ID: ", peer_id, " | Local Player ID: ", multiplayer.get_unique_id())
	print("🚨 Already eliminated: ", is_eliminated)
	
	if is_eliminated:
		print("🚨 Player already eliminated, skipping")
		return
	
	print("🚨 PROCEEDING WITH ELIMINATION for ", player_name)
	is_eliminated = true
	game_outcome = outcome
	
	# Calculate time lasted - with comprehensive error handling
	var main_scene = get_node("/root/Main")
	var time_lasted = 0.0
	
	print("🕒 Calculating time lasted for elimination...")
	print("🕒 Main scene found: ", main_scene != null)
	print("🔍 DEBUG: Searching for MainSceneManager...")
	
	# Try to find the actual MainSceneManager
	var scene_manager = null
	if main_scene:
		# Check if main_scene itself has the script
		if main_scene.has_method("get_game_time_remaining"):
			scene_manager = main_scene
			print("🔍 Found MainSceneManager at /root/Main")
		else:
			# Look for children that might have the MainSceneManager script
			for child in main_scene.get_children():
				if child.has_method("get_game_time_remaining"):
					scene_manager = child
					print("🔍 Found MainSceneManager at child: ", child.name)
					break
		
		if not scene_manager:
			# Try alternative paths
			scene_manager = get_node_or_null("/root/MainSceneManager")
			if scene_manager and scene_manager.has_method("get_game_time_remaining"):
				print("🔍 Found MainSceneManager at /root/MainSceneManager")
			else:
				scene_manager = null
	
	if scene_manager:
		main_scene = scene_manager
		print("🔍 Using scene_manager for time calculation")
	else:
		print("🔍 No MainSceneManager found, using fallback")
	
	if main_scene:
		print("🕒 Attempting time calculation with safe approach...")
		# Set fallback first, then try to calculate actual time
		time_lasted = 30.0
		print("🕒 Default fallback time set: ", time_lasted, " seconds")
		
		# Try to get actual time - if it works, great; if not, we keep fallback
		print("🕒 Attempting to get game time remaining...")
		print("🔍 DEBUG: main_scene type: ", typeof(main_scene))
		print("🔍 DEBUG: main_scene class: ", main_scene.get_class())
		print("🔍 DEBUG: has_method check: ", main_scene.has_method("get_game_time_remaining"))
		if main_scene.has_method("get_game_time_remaining"):
			var game_time_remaining = main_scene.get_game_time_remaining()
			print("🕒 Game time remaining: ", game_time_remaining)
			time_lasted = main_scene.GAME_DURATION - game_time_remaining
			print("🕒 Calculated time lasted: ", time_lasted, " seconds")
		else:
			print("🕒 get_game_time_remaining method not found, keeping fallback time")
	else:
		print("❌ Could not find main scene for time calculation!")
		time_lasted = 30.0  # Fallback time
		print("🕒 Using fallback time: ", time_lasted, " seconds")
	
	# Check if this is the local player
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	print("🚨 Is this the local player? ", is_local_player)
	
	if is_local_player:
		print("🚨 LOCAL PLAYER ELIMINATION - Storing data and transitioning to GameEnd.tscn")
		# Store player data in a singleton for the GameEnd scene
		PlayerData.set_game_end_data(outcome, player_name, time_lasted, health, social, ccat_score)
		print("🚨 Data stored successfully")
		print("🚨 PlayerData game_end_outcome: ", PlayerData.game_end_outcome)
		print("🚨 PlayerData game_end_player_name: ", PlayerData.game_end_player_name)
		print("🚨 PlayerData game_end_time_lasted: ", PlayerData.game_end_time_lasted)
		
		print("🚨 Calling scene transition...")
		# Use call_deferred to ensure the scene transition happens on the next frame
		call_deferred("_transition_to_game_end")
		print("🚨 Scene transition scheduled!")
	else:
		print("🚨 REMOTE PLAYER ELIMINATION - Updating GameEndWindow for others")
		# For other players, just update the elimination window for remaining players
		if main_scene and main_scene.has_method("get_game_end_window"):
			var game_end_window = main_scene.get_game_end_window()
			if game_end_window:
				print("🚨 Found GameEndWindow, adding eliminated player: ", player_name)
				game_end_window.add_eliminated_player(player_name, peer_id, outcome, time_lasted)
			else:
				print("🚨 GameEndWindow not found via get_game_end_window()")
		else:
			print("🚨 MainScene doesn't have get_game_end_window() method")
	
	# Add result to PlayerData for global tracking
	PlayerData.add_player_result(player_name, outcome, time_lasted)
	
	# Sync elimination to all clients via PlayerData singleton (persists across scenes)
	print("📡 Calling PlayerData.sync_player_result_across_scenes.rpc for ", player_name)
	PlayerData.sync_player_result_across_scenes.rpc(player_name, outcome, time_lasted)
	print("📡 PlayerData RPC call completed")
	
	# Stop decay timer
	if decay_timer:
		decay_timer.stop()
	
	# Disable movement
	set_physics_process(false)

func _transition_to_game_end():
	"""Safely transition to GameEnd scene - called via call_deferred"""
	print("🚨 _TRANSITION_TO_GAME_END called!")
	print("🚨 About to change scene to GameEnd.tscn...")
	get_tree().change_scene_to_file("res://scenes/GameEnd.tscn")
	print("🚨 Scene change completed!")

func evaluate_end_game_condition():
	"""Evaluate win/lose condition when game time ends (called by MainSceneManager)"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	print("🎯 evaluate_end_game_condition called for peer ", peer_id, " (local: ", is_local_player, ", eliminated: ", is_eliminated, ")")
	print("🎯 Player ", player_name, " stats - Health: ", health, " Social: ", social, " CCAT: ", ccat_score)
	
	if not is_local_player:
		print("🎯 Skipping evaluation - not local player")
		return
	
	if is_eliminated:
		print("🎯 Skipping evaluation - already eliminated")
		return
	
	print("📊 Evaluating end-game condition for LOCAL player: ", player_name)
	print("📊 Final stats - Health: ", health, " Social: ", social, " CCAT: ", ccat_score)
	
	# Calculate time lasted (full game duration)
	var main_scene = get_node("/root/Main")
	var time_lasted = 60.0  # Full game duration since timer ended
	if main_scene and main_scene.has_method("get_game_time_remaining"):
		time_lasted = main_scene.GAME_DURATION
		print("📊 Time lasted: ", time_lasted, " seconds (full game duration)")
	
	# Determine outcome based on final stats
	var final_outcome = ""
	
	# Check win condition FIRST: CCAT >= 40 AND Social >= 25
	if ccat_score >= 40 and social >= 25:
		final_outcome = "win"
		print("🎉 ", player_name, " WON! CCAT: ", ccat_score, " >= 40, Social: ", social, " >= 25")
	# Check lose condition: Social < 25
	elif social < 25:
		final_outcome = "lose_social"
		print("❌ ", player_name, " lost: Social score too low (", social, " < 25)")
	# Final fallback: CCAT must be < 40 if we reach here
	else:
		final_outcome = "lose_ccat"
		print("❌ ", player_name, " lost: CCAT score too low (", ccat_score, " < 40)")
	
	game_outcome = final_outcome
	
	print("📊 FINAL OUTCOME: ", final_outcome, " for player ", player_name)
	
	# Store player data and transition to GameEnd scene
	print("📊 Storing game end data and transitioning to GameEnd scene...")
	PlayerData.set_game_end_data(final_outcome, player_name, time_lasted, health, social, ccat_score)
	
	# Add result to PlayerData for global tracking
	PlayerData.add_player_result(player_name, final_outcome, time_lasted)
	
	# Sync final result to other players via PlayerData singleton (persists across scenes)
	print("📡 Calling PlayerData.sync_player_result_across_scenes.rpc for ", player_name)
	PlayerData.sync_player_result_across_scenes.rpc(player_name, final_outcome, time_lasted)
	print("📡 PlayerData game end RPC call completed")
	
	# Use call_deferred to ensure the scene transition happens cleanly
	call_deferred("transition_to_game_end")

func transition_to_game_end():
	"""Transition to the GameEnd scene"""
	print("🎬 Transitioning to GameEnd scene...")
	get_tree().change_scene_to_file("res://scenes/GameEnd.tscn")

func show_notification(message: String, color: Color):
	"""Display a notification message to the player"""
	if notification_label:
		notification_label.text = message
		notification_label.add_theme_color_override("font_color", color)
		notification_label.visible = true
		
		# Auto-hide after 5 seconds
		var timer = Timer.new()
		timer.wait_time = 5.0
		timer.one_shot = true
		timer.timeout.connect(func(): 
			if notification_label:
				notification_label.visible = false
			timer.queue_free()
		)
		add_child(timer)
		timer.start()
		
		print("💬 Showing notification: ", message)

func get_current_decay_rate() -> float:
	"""Get the current decay rate based on health"""
	if health == 0:
		return decay_rate / 3.0  # 3x faster decay when health is 0
	else:
		return decay_rate  # Normal decay rate

@rpc("any_peer", "call_local", "reliable")
func sync_elimination_to_all(eliminated_name: String, eliminated_peer_id: int, eliminated_outcome: String, eliminated_time: float):
	"""Sync player elimination to all remaining players"""
	print("📡 RPC RECEIVED: sync_elimination_to_all for ", eliminated_name, " (peer ", eliminated_peer_id, ")")
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	var is_eliminated_player = (eliminated_peer_id == multiplayer.get_unique_id())
	print("📡 This player peer_id: ", peer_id, " | Local player ID: ", multiplayer.get_unique_id())
	print("📡 is_local_player: ", is_local_player, " | is_eliminated_player: ", is_eliminated_player)
	
	# Add to PlayerData for global tracking
	print("📡 Adding player result to PlayerData...")
	PlayerData.add_player_result(eliminated_name, eliminated_outcome, eliminated_time)
	
	# Only update GameEndWindow for players still in the game
	print("📡 Checking if should update GameEndWindow...")
	print("📡 Conditions: is_local_player=", is_local_player, " not is_eliminated=", not is_eliminated, " not is_eliminated_player=", not is_eliminated_player)
	if is_local_player and not is_eliminated and not is_eliminated_player:
		print("📡 Updating GameEndWindow...")
		var main_scene = get_node("/root/Main")
		if main_scene and main_scene.has_method("get_game_end_window"):
			var game_end_window = main_scene.get_game_end_window()
			if game_end_window:
				print("📡 GameEndWindow found, adding eliminated player: ", eliminated_name)
				game_end_window.add_eliminated_player(eliminated_name, eliminated_peer_id, eliminated_outcome, eliminated_time)
			else:
				print("📡 GameEndWindow not found via get_game_end_window()")
		else:
			print("📡 MainScene not found or doesn't have get_game_end_window() method")
	else:
		print("📡 Not updating GameEndWindow (wrong conditions)")

@rpc("any_peer", "call_local", "reliable")
func sync_game_end_to_all(finished_name: String, finished_peer_id: int, finished_outcome: String, finished_time: float):
	"""Sync game end result to all remaining players"""
	print("📡 RPC RECEIVED: sync_game_end_to_all for ", finished_name, " (peer ", finished_peer_id, ")")
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	var is_finished_player = (finished_peer_id == multiplayer.get_unique_id())
	print("📡 This player peer_id: ", peer_id, " | Local player ID: ", multiplayer.get_unique_id())
	print("📡 is_local_player: ", is_local_player, " | is_finished_player: ", is_finished_player)
	
	# Add to PlayerData for global tracking - THIS IS KEY for GameEnd scenes
	print("📡 Adding game end result to PlayerData...")
	PlayerData.add_player_result(finished_name, finished_outcome, finished_time)
	
	# Only update GameEndWindow for players still in the game
	print("📡 Checking if should update GameEndWindow...")
	print("📡 Conditions: is_local_player=", is_local_player, " not is_eliminated=", not is_eliminated, " not is_finished_player=", not is_finished_player)
	if is_local_player and not is_eliminated and not is_finished_player:
		print("📡 Updating GameEndWindow...")
		var main_scene = get_node("/root/Main")
		if main_scene and main_scene.has_method("get_game_end_window"):
			var game_end_window = main_scene.get_game_end_window()
			if game_end_window:
				print("📡 GameEndWindow found, adding finished player: ", finished_name)
				game_end_window.add_eliminated_player(finished_name, finished_peer_id, finished_outcome, finished_time)
			else:
				print("📡 GameEndWindow not found via get_game_end_window()")
		else:
			print("📡 MainScene not found or doesn't have get_game_end_window() method")
	else:
		print("📡 Not updating GameEndWindow (wrong conditions)") 
