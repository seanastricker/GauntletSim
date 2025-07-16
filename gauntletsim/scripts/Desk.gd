# Desk.gd
extends Area2D

@onready var interaction_prompt: Label = $InteractionPrompt

func _ready():
    interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1))
    interaction_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    interaction_prompt.add_theme_constant_override("outline_size", 2)
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body.is_in_group("player"):
        interaction_prompt.visible = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        interaction_prompt.visible = false

func _process(_delta):
    if interaction_prompt.visible and Input.is_action_just_pressed("interact"):
        var bodies = get_overlapping_bodies()
        for body in bodies:
            if body.is_in_group("player") and body.has_method("work_at_desk"):
                body.work_at_desk()
                print("Player is working.")
                # Hide prompt after interaction to avoid spamming
                interaction_prompt.visible = false
                # A timer could be used to show it again after cooldown 