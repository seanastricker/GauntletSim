extends "res://scripts/VisibleNPC.gd"

func _unhandled_input(_event):
    if player_in_range and Input.is_action_just_pressed("interact"):
        dialogue_label.visible = true
        dialogue_timer.start()
        var player = get_tree().get_nodes_in_group("player")[0]
        if player and player.has_method("interact_with_social_npc"):
            player.interact_with_social_npc() 