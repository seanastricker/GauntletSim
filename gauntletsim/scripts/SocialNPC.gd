# SocialNPC.gd
extends "res://scripts/NPC.gd"

# This script extends the base NPC to add a social interaction.

func _input(event):
    if interaction_prompt.visible and event.is_action_pressed("interact"):
        # First, let the parent class handle showing the dialogue.
        super._input(event)

        # Now, add the social boost functionality.
        var bodies = area.get_overlapping_bodies()
        for body in bodies:
            if body.is_in_group("player") and body.has_method("modify_social"):  # Removed cooldown check for testing
                body.modify_social(5)
                # body.start_interaction_cooldown("socialize", 20.0)  # Disabled for testing
                print("Player socialized. Social +5") 