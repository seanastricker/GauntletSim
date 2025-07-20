# Rules.gd
# Scene for displaying game rules and instructions
extends Control

@onready var back_button: Button = $BackButton

# Main elements
@onready var title_label: Label = $ScrollContainer/VBoxContainer/TitleLabel
@onready var main_content_panel: PanelContainer = $ScrollContainer/VBoxContainer/MainContentPanel

# Labels inside the main content panel (updated paths for new structure)
@onready var objective_label: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/ObjectiveLabel
@onready var objective_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/ObjectiveText
@onready var stats_label: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/StatsLabel
@onready var health_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/StatsHBoxContainer/HealthVBoxContainer/HealthText
@onready var health_decay_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/StatsHBoxContainer/HealthVBoxContainer/HealthDecayText
@onready var social_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/StatsHBoxContainer/SocialVBoxContainer/SocialText
@onready var social_job_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/StatsHBoxContainer/SocialVBoxContainer/SocialJobText
@onready var ccat_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/StatsHBoxContainer/CCATVBoxContainer/CCATText
@onready var ccat_kick_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/StatsHBoxContainer/CCATVBoxContainer/CCATKickText
@onready var controls_label: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/ControlsLabel
@onready var arrow_keys_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/ControlsHBoxContainer/ArrowKeysText
@onready var interact_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/ControlsHBoxContainer/InteractText
@onready var doors_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/ControlsHBoxContainer/DoorsText
@onready var mechanics_label: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/MechanicsLabel
@onready var stat_decay_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/MechanicsHBoxContainer/StatDecayText
@onready var trade_offs_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/MechanicsHBoxContainer/TradeOffsText
@onready var cooldowns_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/MechanicsHBoxContainer/CooldownsText
@onready var locations_label: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/LocationsLabel
@onready var office_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/LocationsHBoxContainer/OfficeText
@onready var street_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/LocationsHBoxContainer/StreetText
@onready var more_locations_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/LocationsHBoxContainer/MoreLocationsText
@onready var multiplayer_label: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/MultiplayerLabel
@onready var see_players_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/MultiplayerHBoxContainer/SeePlayersText
@onready var leaderboard_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/MultiplayerHBoxContainer/LeaderboardText
@onready var no_competition_text: Label = $ScrollContainer/VBoxContainer/MainContentPanel/VBoxContainer/MultiplayerHBoxContainer/NoCompetitionText

func _ready():
	"""Initialize the rules screen"""
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Apply consistent styling to match Lobby
	setup_ui_styling()
	
	# Add some nice visual effects
	setup_ui_effects()
	
	print("📖 Rules screen loaded")

func setup_ui_effects():
	"""Add visual polish to the rules screen"""
	# Fade in animation
	modulate = Color.TRANSPARENT
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", Color.WHITE, 0.5)

func _on_back_button_pressed():
	"""Handle back button press and return to character creation"""
	print("📖 Rules: Returning to character creation")
	
	# Add button press animation
	animate_button_press()
	
	# Brief delay for visual feedback
	await get_tree().create_timer(0.2).timeout
	
	# Return to character creation scene
	get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")

func animate_button_press():
	"""Animate back button press for visual feedback"""
	back_button.disabled = true
	
	var press_tween = create_tween()
	press_tween.tween_method(
		func(scale): back_button.scale = Vector2(scale, scale),
		1.0, 0.95, 0.1
	).set_ease(Tween.EASE_OUT)
	
	press_tween.tween_method(
		func(scale): back_button.scale = Vector2(scale, scale),
		0.95, 1.0, 0.1
	).set_ease(Tween.EASE_IN)



func _input(event):
	"""Handle escape key to go back"""
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

func setup_ui_styling():
	"""Apply consistent styling to match Lobby scene"""
	# Define colors (same as Lobby)
	var primary_color = Color(0.956, 0.689, 0.416, 1.0)  # #F4B06A
	var secondary_color = Color(0.992, 0.851, 0.604, 1.0)  # #FDD89A
	var black_border = Color(0.0, 0.0, 0.0, 1.0)
	var black_text = Color(0.0, 0.0, 0.0, 1.0)
	
	# Get bold font
	var bold_font = ThemeDB.fallback_font
	
	# Style back button to match Lobby exactly
	style_button(back_button, "◀ Back to Character Selection", 24, primary_color, secondary_color, black_border, black_text, bold_font)
	
	# Style main title (outside the main panel)
	style_label(title_label, 48, black_text, bold_font, primary_color, black_border)
	
	# Style the main content panel (one large background box)
	style_main_panel(main_content_panel, primary_color, black_border)
	
	# Style all labels inside the main panel (no backgrounds, just font styling)
	# Section headers
	style_label_text_only(objective_label, 28, black_text, bold_font)
	style_label_text_only(stats_label, 28, black_text, bold_font)
	style_label_text_only(controls_label, 28, black_text, bold_font)
	style_label_text_only(mechanics_label, 28, black_text, bold_font)
	style_label_text_only(locations_label, 28, black_text, bold_font)
	style_label_text_only(multiplayer_label, 28, black_text, bold_font)
	
	# Content text
	style_label_text_only(objective_text, 22, black_text, bold_font)
	style_label_text_only(health_text, 22, black_text, bold_font)
	style_label_text_only(health_decay_text, 18, black_text, bold_font)
	style_label_text_only(social_text, 22, black_text, bold_font)
	style_label_text_only(social_job_text, 18, black_text, bold_font)
	style_label_text_only(ccat_text, 22, black_text, bold_font)
	style_label_text_only(ccat_kick_text, 18, black_text, bold_font)
	style_label_text_only(arrow_keys_text, 22, black_text, bold_font)
	style_label_text_only(interact_text, 22, black_text, bold_font)
	style_label_text_only(doors_text, 22, black_text, bold_font)
	style_label_text_only(stat_decay_text, 22, black_text, bold_font)
	style_label_text_only(trade_offs_text, 22, black_text, bold_font)
	style_label_text_only(cooldowns_text, 22, black_text, bold_font)
	style_label_text_only(office_text, 22, black_text, bold_font)
	style_label_text_only(street_text, 22, black_text, bold_font)
	style_label_text_only(more_locations_text, 22, black_text, bold_font)
	style_label_text_only(see_players_text, 22, black_text, bold_font)
	style_label_text_only(leaderboard_text, 22, black_text, bold_font)
	style_label_text_only(no_competition_text, 22, black_text, bold_font)

func style_button(button: Button, text: String, font_size: int, bg_color: Color, hover_color: Color, border_color: Color, text_color: Color, font: Font):
	"""Apply consistent button styling (same as Lobby)"""
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

func style_label(label: Label, font_size: int, text_color: Color, font: Font, bg_color: Color = Color.TRANSPARENT, border_color: Color = Color.TRANSPARENT):
	"""Apply consistent Label styling with optional background box (same as Lobby)"""
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

func style_main_panel(panel: PanelContainer, bg_color: Color, border_color: Color):
	"""Style the main content panel with a unified background"""
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = bg_color
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = border_color
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.shadow_size = 0
	panel_style.shadow_offset = Vector2(0, 0)
	
	# Add padding for content inside the PanelContainer
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 10
	
	panel.add_theme_stylebox_override("panel", panel_style)

func style_label_text_only(label: Label, font_size: int, text_color: Color, font: Font):
	"""Style a label with just font properties (no background)"""
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", text_color) 