extends CharacterBody2D

# Player stats with min/max constraints
@export var health: int = 50 : set = set_health
@export var social: int = 50 : set = set_social  
@export var ccat_score: int = 50 : set = set_ccat_score

# Movement configuration
@export var speed: float = 200.0

# Player identification
@export var player_name: String = "" : set = set_player_name

# UI references
@onready var health_label: Label = $UI/StatsDisplay/HealthLabel
@onready var social_label: Label = $UI/StatsDisplay/SocialLabel
@onready var ccat_label: Label = $UI/StatsDisplay/CCATLabel
@onready var name_label: Label = $NameLabel
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Stat decay system
var decay_timer: Timer
var decay_rate: float = 1.0  # Stats decrease by 1 every decay_rate seconds

# Interaction cooldowns
var interaction_cooldowns: Dictionary = {}

func _ready() -> void:
	player_name = PlayerData.player_name
	setup_decay_timer()
	update_ui()
	
	# Set up collision shape if needed
	var collision_shape = $CollisionShape2D
	if collision_shape.shape == null:
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(32, 32)
		collision_shape.shape = rect_shape

func _physics_process(_delta: float) -> void:
	handle_movement()
	move_and_slide()

func handle_movement() -> void:
	"""Handle player input and movement"""
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
		
	input_vector = input_vector.normalized()
	velocity = input_vector * speed
	
	# Handle animations
	if animated_sprite:
		if velocity.length() > 0:
			# Walking animations based on direction
			if abs(velocity.x) > abs(velocity.y):
				if velocity.x > 0:
					animated_sprite.play("walk_right")
				else:
					animated_sprite.play("walk_left")
			else:
				if velocity.y > 0:
					animated_sprite.play("walk_down")
				else:
					animated_sprite.play("walk_up")
		else:
			# Stop the animation when not moving
			animated_sprite.stop()
			# Set to first frame of current animation
			animated_sprite.frame = 0

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
	health = clamp(health + amount, 0, 50)

func modify_social(amount: int) -> void:
	social = clamp(social + amount, 0, 50)

func modify_ccat_score(amount: int) -> void:
	ccat_score = clamp(ccat_score + amount, 0, 50)

# Stat setters that trigger UI updates
func set_health(value: int) -> void:
	health = clamp(value, 0, 50)
	update_ui()

func set_social(value: int) -> void:
	social = clamp(value, 0, 50)
	update_ui()

func set_ccat_score(value: int) -> void:
	ccat_score = clamp(value, 0, 50)
	update_ui()

func set_player_name(value: String) -> void:
	player_name = value
	if name_label:
		name_label.text = player_name

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
	player_name = data.get("name", "Player")
	health = data.get("health", 50)
	social = data.get("social", 50)
	ccat_score = data.get("ccat_score", 50)
	global_position.x = data.get("position_x", 0)
	global_position.y = data.get("position_y", 0)
	update_ui() 