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
@onready var health_label: Label = $UI/StatsDisplay/HealthLabel
@onready var social_label: Label = $UI/StatsDisplay/SocialLabel
@onready var ccat_label: Label = $UI/StatsDisplay/CCATLabel
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
		print("🎮 No player data found, using fallback (PlayerData globals)")
		# Fallback for host or single player
		player_name = PlayerData.player_name
		load_sprite(PlayerData.player_sprite_path)
		print("🎮 Fallback: name=", player_name, " sprite=", PlayerData.player_sprite_path)
	else:
		print("🎮 Using player_data from registry")
		player_name = player_data["name"]
		load_sprite(player_data["sprite_path"])
		health = player_data["health"]
		social = player_data["social"]
		ccat_score = player_data["ccat_score"]
		global_position = player_data["position"]
		print("🎮 Loaded: name=", player_name, " sprite=", player_data["sprite_path"])
	
	# Setup UI - only visible for local player
	setup_ui()
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

func setup_ui():
	"""Configure UI visibility and styling"""
	print("🎮 setup_ui(): peer_id=", peer_id, " multiplayer_authority=", is_multiplayer_authority())
	print("🎮 setup_ui(): current unique_id=", multiplayer.get_unique_id())
	
	# Style the name label for ALL players (local and remote)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 4)
	
	var ui_layer = $UI
	# Show UI only for the local player (authority should match local peer ID)
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	ui_layer.visible = is_local_player
	
	print("🎮 UI visible for peer ", peer_id, ": ", ui_layer.visible)
	
	if is_local_player:
		# Add outlines to stats UI labels (only for local player)
		health_label.add_theme_color_override("font_color", Color(1, 1, 1))
		health_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		health_label.add_theme_constant_override("outline_size", 4)
		
		social_label.add_theme_color_override("font_color", Color(1, 1, 1))
		social_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		social_label.add_theme_constant_override("outline_size", 4)
		
		ccat_label.add_theme_color_override("font_color", Color(1, 1, 1))
		ccat_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		ccat_label.add_theme_constant_override("outline_size", 4)
		
		update_ui()
	else:
		# Dim non-local players slightly for visual distinction
		modulate = Color(0.9, 0.9, 0.9, 1.0)

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
	if is_local_player and not is_eliminated:
		self.ccat_score = ccat_score + amount
		sync_stats.rpc(health, social, ccat_score)
		
		# Check for instant lose condition after CCAT change
		check_instant_lose_conditions()

func setup_decay_timer() -> void:
	"""Initialize the stat decay system"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player:
		decay_timer = Timer.new()
		decay_timer.wait_time = get_current_decay_rate()
		decay_timer.autostart = true
		decay_timer.timeout.connect(_on_decay_timer_timeout)
		add_child(decay_timer)

func update_decay_rate():
	"""Update the decay timer rate based on current health"""
	if decay_timer and not is_eliminated:
		var new_rate = get_current_decay_rate()
		decay_timer.wait_time = new_rate
		print("🕒 Decay rate updated to ", new_rate, " seconds (Health: ", health, ")")

func _on_decay_timer_timeout() -> void:
	"""Gradually decrease all stats over time"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	if is_local_player and not is_eliminated:
		modify_health(-1)
		modify_social(-1)
		modify_ccat_score(-1)

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
	"""Update the stats display UI"""
	if health_label:
		health_label.text = "Health: " + str(health)
	if social_label:
		social_label.text = "Social: " + str(social)
	if ccat_label:
		ccat_label.text = "CCAT Score: " + str(ccat_score)

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
	if not is_local_player or is_eliminated:
		return
	
	# CCAT Score below 40 = instant elimination
	if ccat_score < 40:
		eliminate_player("lose_ccat", "You have been kicked out!")
		return

func eliminate_player(outcome: String, message: String):
	"""Eliminate a player from the game"""
	if is_eliminated:
		return
	
	print("🚫 Player ", player_name, " eliminated: ", outcome)
	is_eliminated = true
	game_outcome = outcome
	
	# Show notification
	show_notification(message, Color.RED)
	
	# Stop decay timer
	if decay_timer:
		decay_timer.stop()
	
	# Disable movement
	set_physics_process(false)

func evaluate_end_game_condition():
	"""Evaluate win/lose condition when game time ends (called by MainSceneManager)"""
	var is_local_player = (peer_id == multiplayer.get_unique_id())
	print("🎯 evaluate_end_game_condition called for peer ", peer_id, " (local: ", is_local_player, ", eliminated: ", is_eliminated, ")")
	
	if not is_local_player or is_eliminated:
		print("🎯 Skipping evaluation - not local player or already eliminated")
		return
	
	print("📊 Evaluating end-game condition for ", player_name)
	print("📊 Final stats - Health: ", health, " Social: ", social, " CCAT: ", ccat_score)
	
	# Check lose condition: Social < 25
	if social < 25:
		game_outcome = "lose_social"
		show_notification("You did not get a job offer", Color.RED)
		print("❌ ", player_name, " lost: Social score too low (", social, ")")
		return
	
	# Check win condition: CCAT >= 40 AND Social >= 25
	if ccat_score >= 40 and social >= 25:
		game_outcome = "win"
		show_notification("You got a $200k job!", Color.GREEN)
		print("🎉 ", player_name, " won! CCAT: ", ccat_score, " Social: ", social)
		return
	
	# This shouldn't happen if instant lose worked, but just in case
	game_outcome = "lose_ccat"
	show_notification("You have been kicked out!", Color.RED)
	print("❌ ", player_name, " lost: CCAT score too low (", ccat_score, ")")

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
