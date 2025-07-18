extends "res://scripts/VisibleNPC.gd"

func _unhandled_input(_event):
    if player_in_range and Input.is_action_just_pressed("interact"):
        # Find the local player who can interact (multiplayer-compatible)
        var overlapping_bodies = area.get_overlapping_bodies()
        var local_player_found = false
        
        for body in overlapping_bodies:
            if body.is_in_group("player") and body.has_method("interact_with_social_npc"):
                # In multiplayer, only let the local player (authority) interact
                var is_local_player = true
                if body.has_method("get") and body.get("peer_id") != null:
                    # This is a MultiplayerPlayer - check if it's the local player
                    is_local_player = (body.peer_id == multiplayer.get_unique_id())
                
                if is_local_player:
                    local_player_found = true
                    body.interact_with_social_npc()
                    print("Social interaction with ", npc_name, " by ", body.player_name if body.has_method("get") and body.get("player_name") else "player")
                    break
        
        # Only show dialogue if the LOCAL player is the one interacting
        if local_player_found:
            dialogue_label.visible = true
            dialogue_timer.start() 