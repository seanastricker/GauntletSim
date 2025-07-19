# CharacterCreation.gd
extends Control

@onready var name_edit: LineEdit = $CenterContainer/VBoxContainer/NameEdit
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var texture_rect: TextureRect = $CenterContainer/VBoxContainer/HBoxContainer/TextureRect
@onready var previous_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/PreviousButton
@onready var next_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/NextButton

var character_sprites = [
	"res://assets/characters/default.png",
	"res://assets/characters/sean_spritesheet.png",
	"res://assets/characters/matt.png",
	"res://assets/characters/radin.png",
	"res://assets/characters/darren.png",
	"res://assets/characters/hutch.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_01.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_02.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_03.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_04.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_05.png"
]
var current_sprite_index = 0

func _ready():
	# Clear any previous game data when returning to character creation
	PlayerData.clear_all_player_results()
	PlayerData.clear_game_end_data()
	print("🧹 CharacterCreation: Cleared all previous game data")
	
	start_button.pressed.connect(_on_start_button_pressed)
	previous_button.pressed.connect(_on_previous_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	name_edit.grab_focus()
	
	setup_sexy_ui()
	update_character_sprite()

func setup_sexy_ui():
	"""Configure modern, attractive UI styling"""
	# === SEXY NAME INPUT STYLING ===
	name_edit.add_theme_font_size_override("font_size", 32)
	name_edit.placeholder_text = "Player Name"
	
	# Make text bold
	var bold_font = ThemeDB.fallback_font
	name_edit.add_theme_font_override("font", bold_font)
	
	# Create modern input field styling
	var name_stylebox = StyleBoxFlat.new()
	name_stylebox.bg_color = Color(0.96, 0.69, 0.42, 1.0)  # #F5B06B background
	name_stylebox.border_width_left = 3
	name_stylebox.border_width_right = 3
	name_stylebox.border_width_top = 3
	name_stylebox.border_width_bottom = 3
	name_stylebox.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	name_stylebox.corner_radius_top_left = 15
	name_stylebox.corner_radius_top_right = 15
	name_stylebox.corner_radius_bottom_left = 15
	name_stylebox.corner_radius_bottom_right = 15
	name_stylebox.shadow_size = 0  # Remove shadow
	name_stylebox.shadow_offset = Vector2(0, 0)
	
	# Hover state with color change
	var name_stylebox_hover = name_stylebox.duplicate()
	name_stylebox_hover.bg_color = Color(1.0, 0.84, 0.60, 1.0)  # #FFD79A on hover
	name_stylebox_hover.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	name_stylebox_hover.shadow_size = 0  # Remove shadow
	name_stylebox_hover.shadow_offset = Vector2(0, 0)
	
	# Focused state
	var name_stylebox_focused = name_stylebox.duplicate()
	name_stylebox_focused.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border when focused
	name_stylebox_focused.bg_color = Color(0.96, 0.69, 0.42, 1.0)  # Keep #F5B06B when focused
	name_stylebox_focused.shadow_size = 0  # Remove shadow
	name_stylebox_focused.shadow_offset = Vector2(0, 0)
	
	name_edit.add_theme_stylebox_override("normal", name_stylebox)
	name_edit.add_theme_stylebox_override("hover", name_stylebox_hover)
	name_edit.add_theme_stylebox_override("focus", name_stylebox_focused)
	name_edit.add_theme_stylebox_override("read_only", name_stylebox)  # Ensure consistency
	name_edit.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text
	name_edit.add_theme_color_override("font_placeholder_color", Color(0.2, 0.2, 0.2, 0.8))  # Dark placeholder
	name_edit.add_theme_color_override("caret_color", Color(0.0, 0.0, 0.0, 1.0))  # Black cursor
	name_edit.add_theme_color_override("selection_color", Color(0.4, 0.6, 1.0, 0.4))  # Blue selection highlight
	
	# Set minimum size for consistent layout
	name_edit.custom_minimum_size = Vector2(300, 50)
	
	# === SEXY START BUTTON STYLING ===
	start_button.text = "Start"
	start_button.add_theme_font_size_override("font_size", 28)
	
	# Make start button text bold
	start_button.add_theme_font_override("font", bold_font)
	
	# Create gradient button styling
	var button_stylebox = StyleBoxFlat.new()
	button_stylebox.bg_color = Color(0.96, 0.69, 0.42, 1.0)  # #F5B06B orange background - 100% opacity
	button_stylebox.border_width_left = 3
	button_stylebox.border_width_right = 3
	button_stylebox.border_width_top = 3
	button_stylebox.border_width_bottom = 3
	button_stylebox.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	button_stylebox.corner_radius_top_left = 20
	button_stylebox.corner_radius_top_right = 20
	button_stylebox.corner_radius_bottom_left = 20
	button_stylebox.corner_radius_bottom_right = 20
	button_stylebox.shadow_size = 0  # Remove shadow
	button_stylebox.shadow_offset = Vector2(0, 0)
	
	# Hover state with brighter colors
	var button_stylebox_hover = button_stylebox.duplicate()
	button_stylebox_hover.bg_color = Color(1.0, 0.84, 0.60, 1.0)  # #FFD79A on hover
	button_stylebox_hover.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	button_stylebox_hover.shadow_size = 0  # Remove shadow
	button_stylebox_hover.shadow_offset = Vector2(0, 0)
	
	# Pressed state with inset effect
	var button_stylebox_pressed = button_stylebox.duplicate()
	button_stylebox_pressed.bg_color = Color(0.94, 0.65, 0.38, 1.0)  # Darker #F5B06B
	button_stylebox_pressed.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	button_stylebox_pressed.shadow_size = 0  # Remove shadow
	button_stylebox_pressed.shadow_offset = Vector2(0, 0)
	
	# Create focus state for start button to eliminate white outline
	var button_stylebox_focus = button_stylebox.duplicate()
	button_stylebox_focus.bg_color = Color(0.96, 0.69, 0.42, 1.0)  # Same as normal to hide focus
	button_stylebox_focus.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	
	start_button.add_theme_stylebox_override("normal", button_stylebox)
	start_button.add_theme_stylebox_override("hover", button_stylebox_hover)
	start_button.add_theme_stylebox_override("pressed", button_stylebox_pressed)
	start_button.add_theme_stylebox_override("focus", button_stylebox_focus)  # Remove ugly focus outline
	start_button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text
	start_button.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text on hover
	start_button.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text when pressed
	start_button.add_theme_color_override("font_focus_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text when focused
	start_button.add_theme_color_override("font_disabled_color", Color(0.3, 0.3, 0.3, 1.0))  # Dark gray when disabled
	
	# Set minimum size for consistent layout
	start_button.custom_minimum_size = Vector2(300, 60)
	
	# === SEXY NAVIGATION BUTTONS ===
	setup_navigation_buttons()
	
	# === CONNECT UI INTERACTIONS ===
	name_edit.text_changed.connect(_on_name_changed)
	name_edit.mouse_entered.connect(_on_name_edit_hover)
	name_edit.mouse_exited.connect(_on_name_edit_unhover)
	name_edit.focus_exited.connect(_on_name_edit_focus_exit)
	
	print("Sexy UI setup complete!")

func setup_navigation_buttons():
	"""Style the character navigation buttons - circular design"""
	# Previous button styling - arrow in circle
	previous_button.text = "◀"
	previous_button.add_theme_font_size_override("font_size", 20)  # Adjusted for larger circles
	
	# Next button styling - arrow in circle
	next_button.text = "▶"
	next_button.add_theme_font_size_override("font_size", 20)  # Adjusted for larger circles
	
	# Make navigation buttons text bold
	var bold_font = ThemeDB.fallback_font
	previous_button.add_theme_font_override("font", bold_font)
	next_button.add_theme_font_override("font", bold_font)
	
	var nav_stylebox = StyleBoxFlat.new()
	nav_stylebox.bg_color = Color(0.96, 0.69, 0.42, 1.0)  # #F5B06B background
	nav_stylebox.border_width_left = 2
	nav_stylebox.border_width_right = 2
	nav_stylebox.border_width_top = 2
	nav_stylebox.border_width_bottom = 2
	nav_stylebox.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	nav_stylebox.corner_radius_top_left = 22  # Perfect circle (half of 44px)
	nav_stylebox.corner_radius_top_right = 22
	nav_stylebox.corner_radius_bottom_left = 22
	nav_stylebox.corner_radius_bottom_right = 22
	nav_stylebox.shadow_size = 0  # Remove shadow
	nav_stylebox.shadow_offset = Vector2(0, 0)
	
	var nav_hover = nav_stylebox.duplicate()
	nav_hover.bg_color = Color(1.0, 0.84, 0.60, 1.0)  # #FFD79A on hover
	nav_hover.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	nav_hover.shadow_size = 0  # Remove shadow
	nav_hover.shadow_offset = Vector2(0, 0)
	
	# Pressed state
	var nav_pressed = nav_stylebox.duplicate()
	nav_pressed.bg_color = Color(0.94, 0.65, 0.38, 1.0)  # Slightly darker #F5B06B when pressed
	nav_pressed.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	nav_pressed.shadow_size = 0  # Remove shadow
	nav_pressed.shadow_offset = Vector2(0, 0)
	
	# Focus state - eliminate ugly white outline
	var nav_focus = nav_stylebox.duplicate()
	nav_focus.bg_color = Color(0.96, 0.69, 0.42, 1.0)  # Same as normal to hide focus
	nav_focus.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	nav_focus.shadow_size = 0  # Remove shadow
	nav_focus.shadow_offset = Vector2(0, 0)
	
	previous_button.add_theme_stylebox_override("normal", nav_stylebox.duplicate())
	previous_button.add_theme_stylebox_override("hover", nav_hover.duplicate())
	previous_button.add_theme_stylebox_override("pressed", nav_pressed.duplicate())
	previous_button.add_theme_stylebox_override("focus", nav_focus.duplicate())  # Remove ugly focus outline
	previous_button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text
	previous_button.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text on hover
	previous_button.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text when pressed
	previous_button.add_theme_color_override("font_focus_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text when focused
	previous_button.add_theme_color_override("font_disabled_color", Color(0.3, 0.3, 0.3, 1.0))  # Dark gray when disabled
	
	# Apply styling to both buttons
	next_button.add_theme_stylebox_override("normal", nav_stylebox.duplicate())
	next_button.add_theme_stylebox_override("hover", nav_hover.duplicate())
	next_button.add_theme_stylebox_override("pressed", nav_pressed.duplicate())
	next_button.add_theme_stylebox_override("focus", nav_focus.duplicate())  # Remove ugly focus outline
	next_button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text
	next_button.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text on hover
	next_button.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text when pressed
	next_button.add_theme_color_override("font_focus_color", Color(0.0, 0.0, 0.0, 1.0))  # Black text when focused
	next_button.add_theme_color_override("font_disabled_color", Color(0.3, 0.3, 0.3, 1.0))  # Dark gray when disabled
	
	# Add sizing constraints for circular arrow buttons
	# Set both minimum AND maximum sizes to prevent stretching
	previous_button.custom_minimum_size = Vector2(44, 44)  # Larger, more visible circles
	next_button.custom_minimum_size = Vector2(44, 44)  # Larger, more visible circles
	
	# Prevent any stretching in both directions
	previous_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	previous_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add margin spacing to separate buttons from character sprite
	# Set margins to create more space around buttons
	previous_button.add_theme_constant_override("h_separation", 16)
	next_button.add_theme_constant_override("h_separation", 16)
	
	# Alternative: Add to offsets for manual spacing if in HBoxContainer
	call_deferred("_add_button_spacing")

func _add_button_spacing():
	"""Add extra spacing between navigation buttons and character sprite"""
	# Check if buttons are in an HBoxContainer and add separation
	var hbox = previous_button.get_parent()
	if hbox is HBoxContainer:
		hbox.add_theme_constant_override("separation", 24)  # Increase spacing between elements
	
	# Also add some margin offsets if possible
	if previous_button.get_parent():
		var prev_rect = previous_button.get_rect()
		var next_rect = next_button.get_rect()
		# Add some offset margin
		previous_button.set_offset(SIDE_RIGHT, prev_rect.position.x - 12)
		next_button.set_offset(SIDE_LEFT, next_rect.position.x + 12)

func _on_name_edit_hover():
	"""Handle name edit hover - change background to #FFD79A"""
	var hover_stylebox = StyleBoxFlat.new()
	hover_stylebox.bg_color = Color(1.0, 0.84, 0.60, 1.0)  # #FFD79A
	hover_stylebox.border_width_left = 3
	hover_stylebox.border_width_right = 3
	hover_stylebox.border_width_top = 3
	hover_stylebox.border_width_bottom = 3
	hover_stylebox.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
	hover_stylebox.corner_radius_top_left = 15
	hover_stylebox.corner_radius_top_right = 15
	hover_stylebox.corner_radius_bottom_left = 15
	hover_stylebox.corner_radius_bottom_right = 15
	hover_stylebox.shadow_size = 0
	hover_stylebox.shadow_offset = Vector2(0, 0)
	
	name_edit.add_theme_stylebox_override("normal", hover_stylebox)

func _on_name_edit_unhover():
	"""Handle name edit unhover - return to #F5B06B (unless focused)"""
	# Only change back to normal if not focused
	if not name_edit.has_focus():
		var normal_stylebox = StyleBoxFlat.new()
		normal_stylebox.bg_color = Color(0.96, 0.69, 0.42, 1.0)  # #F5B06B
		normal_stylebox.border_width_left = 3
		normal_stylebox.border_width_right = 3
		normal_stylebox.border_width_top = 3
		normal_stylebox.border_width_bottom = 3
		normal_stylebox.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
		normal_stylebox.corner_radius_top_left = 15
		normal_stylebox.corner_radius_top_right = 15
		normal_stylebox.corner_radius_bottom_left = 15
		normal_stylebox.corner_radius_bottom_right = 15
		normal_stylebox.shadow_size = 0
		normal_stylebox.shadow_offset = Vector2(0, 0)
		
		name_edit.add_theme_stylebox_override("normal", normal_stylebox)

func _on_name_edit_focus_exit():
	"""Handle when text input loses focus - return to normal style"""
	_on_name_edit_unhover()  # Use the same logic as unhover

func _on_name_changed(new_text: String):
	"""Update start button based on name input"""
	if new_text.length() > 0:
		start_button.text = "Start"
	else:
		start_button.text = "Start"

func _on_start_button_pressed():
	"""Handle start button press with visual feedback"""
	var player_name = name_edit.text
	if player_name.is_empty():
		player_name = "Player"
	
	print("🏗️ Character created: '", player_name, "'")
	
	# Add satisfying button press animation
	animate_start_button_press()
	
	PlayerData.player_name = player_name
	PlayerData.player_sprite_path = character_sprites[current_sprite_index]
	
	# Brief delay for visual feedback before scene transition
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func animate_start_button_press():
	"""Animate start button press for satisfying feedback"""
	# Disable button to prevent double-clicks
	start_button.disabled = true
	
	# Success animation sequence
	var press_tween = create_tween()
	
	# Scale down (press effect)
	press_tween.tween_method(
		func(scale): start_button.scale = Vector2(scale, scale),
		1.0, 0.95, 0.1
	).set_ease(Tween.EASE_OUT)
	
	# Scale up (release effect)  
	press_tween.tween_method(
		func(scale): start_button.scale = Vector2(scale, scale),
		0.95, 1.0, 0.1
	).set_ease(Tween.EASE_OUT)
	
	# Brief color flash for extra feedback
	var color_tween = create_tween()
	color_tween.parallel().tween_property(start_button, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.1)
	color_tween.tween_property(start_button, "modulate", Color.WHITE, 0.2)
	
	print("Adventure begins for " + (name_edit.text if not name_edit.text.is_empty() else "Player") + "!")

func _on_previous_button_pressed():
	current_sprite_index = (current_sprite_index - 1 + character_sprites.size()) % character_sprites.size()
	update_character_sprite()
	animate_character_selection("left")

func _on_next_button_pressed():
	current_sprite_index = (current_sprite_index + 1) % character_sprites.size()
	update_character_sprite()
	animate_character_selection("right")

func animate_character_selection(direction: String):
	"""Add smooth animation when changing character sprites"""
	# Brief scale animation for visual feedback
	var scale_tween = create_tween()
	scale_tween.tween_method(
		func(scale): texture_rect.scale = Vector2(scale, scale),
		1.0, 1.15, 0.1
	).set_ease(Tween.EASE_OUT)
	
	scale_tween.tween_method(
		func(scale): texture_rect.scale = Vector2(scale, scale),
		1.15, 1.0, 0.1
	).set_ease(Tween.EASE_IN)
	
	# Subtle rotation for more dynamic feel
	var rotation_target = 0.1 if direction == "right" else -0.1
	var rotation_tween = create_tween()
	rotation_tween.parallel().tween_property(texture_rect, "rotation", rotation_target, 0.1)
	rotation_tween.tween_property(texture_rect, "rotation", 0.0, 0.1)

func update_character_sprite():
	"""Update character sprite with enhanced visual styling"""
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = load(character_sprites[current_sprite_index])
	atlas_texture.region = Rect2(48, 0, 16, 32)
	texture_rect.texture = atlas_texture
	
	# Add subtle glow effect to character preview
	texture_rect.modulate = Color(1.1, 1.1, 1.1, 1.0)  # Slight brightness increase
	
	# Add character counter feedback
	print("Character " + str(current_sprite_index + 1) + "/" + str(character_sprites.size()) + " selected!")