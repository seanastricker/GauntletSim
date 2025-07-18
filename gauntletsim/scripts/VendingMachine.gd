# VendingMachine.gd
extends Area2D

@onready var interaction_prompt: Label = $InteractionPrompt

func _ready():
    interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1))
    interaction_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    interaction_prompt.add_theme_constant_override("outline_size", 4)
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body.is_in_group("player"):
        # Check if this is the local player (multiplayer-compatible)
        var is_local_player = true
        if body.has_method("get") and body.get("peer_id") != null:
            # This is a MultiplayerPlayer - check if it's the local player
            is_local_player = (body.peer_id == multiplayer.get_unique_id())
        
        if is_local_player:
            interaction_prompt.visible = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        # Check if this is the local player (multiplayer-compatible)
        var is_local_player = true
        if body.has_method("get") and body.get("peer_id") != null:
            # This is a MultiplayerPlayer - check if it's the local player
            is_local_player = (body.peer_id == multiplayer.get_unique_id())
        
        if is_local_player:
            interaction_prompt.visible = false

func _process(_delta):
    if interaction_prompt.visible and Input.is_action_just_pressed("interact"):
        var bodies = get_overlapping_bodies()
        var local_player_found = false
        
        for body in bodies:
            if body.is_in_group("player") and body.has_method("modify_health"):  # Removed cooldown check for testing
                # Check if this is the local player (multiplayer-compatible)
                var is_local_player = true
                if body.has_method("get") and body.get("peer_id") != null:
                    # This is a MultiplayerPlayer - check if it's the local player
                    is_local_player = (body.peer_id == multiplayer.get_unique_id())
                
                if is_local_player:
                    local_player_found = true
                    body.modify_health(5)
                    # body.start_interaction_cooldown("vend", 15.0)  # Disabled for testing
                    print("Player used vending machine. Health +5")
                    break
        
        # Only hide prompt if the LOCAL player is the one interacting
        if local_player_found:
            interaction_prompt.visible = false # Hide prompt temporarily 