extends CharacterBody2D

# Player stats with min/max constraints
@export var health: int = 50:
	set(value):
		health = clamp(value, 0, 50)
		if health_label:
			update_ui()
@export var social: int = 50:
	set(value):
		social = clamp(value, 0, 50)
		if social_label:
			update_ui()
@export var ccat_score: int = 50:
	set(value):
		ccat_score = clamp(value, 0, 50)
		if ccat_label:
			update_ui()

# Movement configuration
@export var speed: float = 200.0

# Player identification
@export var player_name: String = "":
	set(value):
		player_name = value
		if name_label:
			name_label.text = player_name
			name_label.add_theme_color_override("font_color", Color(1, 1, 1))
			name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			name_label.add_theme_constant_override("outline_size", 2)

# UI references
@onready var health_label: Label = $UI/StatsDisplay/HealthLabel
@onready var social_label: Label = $UI/StatsDisplay/SocialLabel
@onready var ccat_label: Label = $UI/StatsDisplay/CCATLabel
@onready var name_label: Label = $NameLabel
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Stat decay system
var decay_timer: Timer
var decay_rate: float = 10.0  # Stats decrease by 1 every 10 seconds

# Interaction cooldowns
var interaction_cooldowns: Dictionary = {}

var last_direction = Vector2(0, 1) # Default to facing down

func _ready() -> void:
	player_name = PlayerData.player_name
	setup_decay_timer()
	
	# Add outlines to UI labels
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 2)
	
	health_label.add_theme_color_override("font_color", Color(1, 1, 1))
	health_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	health_label.add_theme_constant_override("outline_size", 2)
	
	social_label.add_theme_color_override("font_color", Color(1, 1, 1))
	social_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	social_label.add_theme_constant_override("outline_size", 2)
	
	ccat_label.add_theme_color_override("font_color", Color(1, 1, 1))
	ccat_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	ccat_label.add_theme_constant_override("outline_size", 2)
	
	update_ui()
	
	# Set up collision shape if needed
	var collision_shape = $CollisionShape2D
	if collision_shape.shape == null:
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(32, 32)
		collision_shape.shape = rect_shape
	
	# Set initial animation
	update_animation(Vector2.ZERO)

func _physics_process(_delta: float) -> void:
	var input_vector = get_input_vector()
	velocity = input_vector * speed
	move_and_slide()
	update_animation(input_vector)

func get_input_vector() -> Vector2:
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

func update_animation(input_vector: Vector2) -> void:
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
			
	var anim_prefix = "walk"
	if input_vector == Vector2.ZERO:
		anim_prefix = "idle"
		
	var new_animation = anim_prefix + "_" + anim_direction
	
	if animated_sprite.animation != new_animation or not animated_sprite.is_playing():
		animated_sprite.play(new_animation)

func setup_decay_timer() -> void:
	"""Initialize the stat decay system"""
	decay_timer = Timer.new()
	decay_timer.wait_time = decay_rate
	decay_timer.autostart = true
	decay_timer.timeout.connect(_on_decay_timer_timeout)
	add_child(decay_timer)

func _on_decay_timer_timeout() -> void:
	"""Gradually decrease all stats over time"""
	modify_health(-1)
	modify_social(-1)
	modify_ccat_score(-1)

# Stat modification functions with bounds checking
func modify_health(amount: int) -> void:
	self.health = health + amount

func modify_social(amount: int) -> void:
	self.social = social + amount

func modify_ccat_score(amount: int) -> void:
	self.ccat_score = ccat_score + amount

# Stat setters that trigger UI updates - no longer needed

func set_player_name(value: String) -> void:
	self.player_name = value

func update_ui() -> void:
	"""Update the stats display UI"""
	if health_label:
		health_label.text = "Health: " + str(health)
	if social_label:
		social_label.text = "Social: " + str(social)
	if ccat_label:
		ccat_label.text = "CCAT Score: " + str(ccat_score)

# Interaction system with cooldowns
func can_interact(interaction_type: String) -> bool:
	"""Check if player can perform interaction based on cooldown"""
	if interaction_type in interaction_cooldowns:
		return Time.get_ticks_msec() >= interaction_cooldowns[interaction_type]
	return true

func start_interaction_cooldown(interaction_type: String, cooldown_seconds: float) -> void:
	"""Start cooldown timer for specific interaction type"""
	interaction_cooldowns[interaction_type] = Time.get_ticks_msec() + (cooldown_seconds * 1000)

# Office work interaction
func work_at_desk() -> void:
	"""Handle working at office desk - increases CCAT, decreases Health/Social"""
	if can_interact("work"):
		modify_ccat_score(5)
		modify_health(-2)
		modify_social(-1)
		start_interaction_cooldown("work", 10.0)  # 10 second cooldown
		print(player_name + " worked at desk. CCAT +5, Health -2, Social -1")

# Save/Load system for character persistence
func save_player_data() -> Dictionary:
	"""Save player data for persistence between sessions"""
	return {
		"name": player_name,
		"health": health,
		"social": social,
		"ccat_score": ccat_score,
		"position_x": global_position.x,
		"position_y": global_position.y
	}

func load_player_data(data: Dictionary) -> void:
	"""Load player data from saved data"""
	self.player_name = data.get("name", "Player")
	self.health = data.get("health", 50)
	self.social = data.get("social", 50)
	self.ccat_score = data.get("ccat_score", 50)
	global_position.x = data.get("position_x", 0)
	global_position.y = data.get("position_y", 0)
	update_ui() 

func interact_with_social_npc():
	modify_social(5)
	print(player_name + " talked to a social NPC. Social +5") 
