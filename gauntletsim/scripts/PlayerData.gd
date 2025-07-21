# PlayerData.gd - Player data management for single and multiplayer
# Handles player information storage and synchronization
extends Node

# Player data for single-player compatibility
var player_name: String
var player_sprite_path: String

# Multiplayer player registry - now enhanced with complete state
var players_data: Dictionary = {}

# Enhanced player state storage for scene transitions
var complete_player_states: Dictionary = {}
var scene_specific_positions: Dictionary = {}  # {peer_id: {scene_name: position}}

# Signal emitted when player registry is synchronized from server
signal player_registry_updated
signal player_state_updated(peer_id: int)

# Game end data for transitions
var game_end_outcome: String = ""
var game_end_player_name: String = ""
var game_end_time_lasted: float = 0.0
var game_end_health: int = 0
var game_end_social: int = 0
var game_end_ccat: int = 0

# All players' results for GameEnd scene
var all_player_results: Dictionary = {}
signal player_result_added(result_player_name: String, outcome: String, time_lasted: float)
signal player_eliminated(eliminated_player_name: String, peer_id: int)

func register_player(peer_id: int, display_name: String, sprite_path: String):
    """Register a player's data for multiplayer synchronization"""
    # Assign spawn position based on peer ID for consistent positioning
    var spawn_positions = [
        Vector2(22, 306),   # Host spawn position
        Vector2(50, 306),   # Player 2 spawn (offset right)
        Vector2(78, 306),   # Player 3 spawn (offset right more)
        Vector2(106, 306),  # Player 4 spawn (offset right most)
    ]
    
    var spawn_pos: Vector2
    if peer_id == 1:
        spawn_pos = spawn_positions[0]  # Host always at first position
    else:
        # For other players, use their position in the registry
        var existing_count = players_data.size()  # Count before adding this player
        spawn_pos = spawn_positions[existing_count % spawn_positions.size()]
    
    players_data[peer_id] = {
        "name": display_name,
        "sprite_path": sprite_path,
        "health": 50,
        "social": 50,
        "ccat_score": 50,
        "position": spawn_pos
    }
    print("Registered player ", display_name, " with ID ", peer_id, " at spawn position ", spawn_pos)

@rpc("authority", "call_local")
func sync_player_registry(registry_data: Dictionary):
    """Synchronize player registry from server to all clients"""
    players_data = registry_data.duplicate(true)
    print("🔄 Player registry synchronized - received ", len(players_data), " players")
    for peer_id in players_data:
        var player = players_data[peer_id]
        print("  - Player ", peer_id, ": ", player["name"])
    player_registry_updated.emit()

func broadcast_player_registry():
    """Send current player registry to all clients (server only)"""
    if not multiplayer.is_server():
        return
        
    print("📡 Broadcasting player registry to all clients...")
    sync_player_registry.rpc(players_data)

func get_player_data(peer_id: int) -> Dictionary:
    """Get player data by peer ID"""
    return players_data.get(peer_id, {})

func get_all_players() -> Dictionary:
    """Get all registered players"""
    return players_data

func set_game_end_data(outcome: String, name: String, time_lasted: float, health: int, social: int, ccat: int):
    """Store game end data for scene transition - prevents overwriting elimination data"""
    # Check if we already have elimination data and prevent overwriting
    if game_end_outcome in ["lose_ccat", "lose_social"] and outcome in ["win", "lose_ccat", "lose_social"]:
        print("📊 PREVENTING OVERWRITE - Already have elimination data: ", game_end_outcome, " for ", game_end_player_name)
        print("📊 Ignoring new data: ", outcome, " for ", name, " - ", time_lasted, "s")
        return
    
    game_end_outcome = outcome
    game_end_player_name = name
    game_end_time_lasted = time_lasted
    game_end_health = health
    game_end_social = social
    game_end_ccat = ccat
    print("📊 Game end data stored: ", name, " - ", outcome, " - ", time_lasted, "s")

func get_game_end_data() -> Dictionary:
    """Get stored game end data"""
    return {
        "outcome": game_end_outcome,
        "name": game_end_player_name,
        "time_lasted": game_end_time_lasted,
        "health": game_end_health,
        "social": game_end_social,
        "ccat": game_end_ccat
    }

func clear_game_end_data():
    """Clear game end data"""
    game_end_outcome = ""
    game_end_player_name = ""
    game_end_time_lasted = 0.0
    game_end_health = 0
    game_end_social = 0
    game_end_ccat = 0

func add_player_result(result_player_name: String, outcome: String, time_lasted: float):
    """Add a player's result to the global results - prevents overwriting elimination data"""
    # Check if this player already has elimination data (lose_ccat or lose_social)
    if all_player_results.has(result_player_name):
        var existing_result = all_player_results[result_player_name]
        var existing_outcome = existing_result.get("outcome", "")
        
        # Don't overwrite elimination data with timer-end data
        if existing_outcome in ["lose_ccat", "lose_social"] and outcome in ["win", "lose_ccat", "lose_social"]:
            print("📊 PlayerData: PREVENTING OVERWRITE - Player ", result_player_name, " already has elimination result: ", existing_outcome)
            print("📊 PlayerData: Ignoring new result: ", outcome, " (", time_lasted, "s)")
            return
    
    all_player_results[result_player_name] = {
        "outcome": outcome,
        "time_lasted": time_lasted
    }
    print("📊 PlayerData: Added result for ", result_player_name, " - ", outcome, " (", time_lasted, "s)")
    print("📊 PlayerData: Total results now: ", all_player_results.size())
    print("📊 PlayerData: All results: ", all_player_results)
    
    # Emit signal for GameEnd scenes to listen to
    print("📊 PlayerData: EMITTING SIGNAL for ", result_player_name)
    player_result_added.emit(result_player_name, outcome, time_lasted)
    print("📊 PlayerData: Signal emitted successfully")

func get_all_player_results() -> Dictionary:
    """Get all player results"""
    return all_player_results

@rpc("any_peer", "call_local", "reliable")
func sync_player_result_across_scenes(result_player_name: String, outcome: String, time_lasted: float, eliminated_peer_id: int = -1):
    """RPC to sync player results across all scenes (including GameEnd.tscn)"""
    print("🌐 PlayerData RPC RECEIVED: ", result_player_name, " - ", outcome, " (", time_lasted, "s)")
    add_player_result(result_player_name, outcome, time_lasted)
    
    # Emit elimination signal if this is an elimination (not a game end)
    if eliminated_peer_id != -1 and (outcome == "lose_ccat" or outcome == "lose_social"):
        print("🚨 Emitting player_eliminated signal for ", result_player_name, " (peer ", eliminated_peer_id, ")")
        player_eliminated.emit(result_player_name, eliminated_peer_id)

func clear_all_player_results():
    """Clear all player results"""
    print("📊 PlayerData: BEFORE clearing - Results count: ", all_player_results.size())
    print("📊 Previous results: ", all_player_results)
    all_player_results.clear()
    print("📊 PlayerData: AFTER clearing - Results count: ", all_player_results.size())
    print("📊 PlayerData: All player results cleared successfully")

func clear_player_registry():
    """Clear the multiplayer player registry"""
    print("🧹 PlayerData: BEFORE clearing registry - Registry size: ", players_data.size())
    print("🧹 Previous registry: ", players_data)
    players_data.clear()
    print("🧹 PlayerData: AFTER clearing registry - Registry size: ", players_data.size())
    print("🧹 PlayerData: Player registry cleared successfully")

func remove_player(peer_id: int):
    """Remove a player from the registry"""
    if peer_id in players_data:
        players_data.erase(peer_id)
        print("Removed player with ID ", peer_id)

func update_player_stats(peer_id: int, health: int, social: int, ccat_score: int):
    """Update a player's stats"""
    if peer_id in players_data:
        players_data[peer_id]["health"] = health
        players_data[peer_id]["social"] = social
        players_data[peer_id]["ccat_score"] = ccat_score

func update_player_position(peer_id: int, position: Vector2):
    """Update a player's position"""
    if peer_id in players_data:
        players_data[peer_id]["position"] = position

func is_multiplayer_active() -> bool:
    """Check if we're in a multiplayer session"""
    return multiplayer.has_multiplayer_peer() and players_data.size() > 1

# === ENHANCED PLAYER STATE MANAGEMENT ===

func store_complete_player_state(peer_id: int, player_data: Dictionary):
    """Store complete player state for scene transitions"""
    complete_player_states[peer_id] = {
        "name": player_data.get("name", ""),
        "sprite_path": player_data.get("sprite_path", ""),
        "health": player_data.get("health", 50),
        "social": player_data.get("social", 50),
        "ccat_score": player_data.get("ccat_score", 50),
        "position": player_data.get("position", Vector2.ZERO),
        "current_scene": player_data.get("scene", ""),
        "is_eliminated": player_data.get("is_eliminated", false),
        "game_outcome": player_data.get("game_outcome", ""),
        "last_updated": Time.get_unix_time_from_system(),
        # UI state information
        "ui_visible": player_data.get("ui_visible", false),
        "decay_timer_active": player_data.get("decay_timer_active", false),
        "decay_timer_remaining": player_data.get("decay_timer_remaining", 0.0),  # Store remaining time
        # Interaction state
        "interaction_cooldowns": player_data.get("interaction_cooldowns", {}),
        "last_direction": player_data.get("last_direction", Vector2(0, 1))
    }
    
    # Store scene-specific position
    var scene_name = player_data.get("scene", "")
    if scene_name != "" and scene_name != null:
        if not scene_specific_positions.has(peer_id):
            scene_specific_positions[peer_id] = {}
        scene_specific_positions[peer_id][scene_name] = player_data.get("position", Vector2.ZERO)
        print("💾 Stored scene-specific position for player ", peer_id, " in ", scene_name, ": ", player_data.get("position", Vector2.ZERO))
        
        # Debug: Show decay timer info being stored
        print("⏲️ Stored decay timer state for player ", peer_id, ": active=", player_data.get("decay_timer_active", false), ", remaining=", player_data.get("decay_timer_remaining", 0.0), "s")
    
    print("💾 Stored complete player state for peer ", peer_id)
    player_state_updated.emit(peer_id)

func get_complete_player_state(peer_id: int) -> Dictionary:
    """Get complete player state"""
    return complete_player_states.get(peer_id, {})

func get_player_position_for_scene(peer_id: int, scene_name: String) -> Vector2:
    """Get player's last known position for a specific scene"""
    if scene_specific_positions.has(peer_id) and scene_specific_positions[peer_id].has(scene_name):
        return scene_specific_positions[peer_id][scene_name]
    
    # Fallback to default spawn positions
    var spawn_positions = [
        Vector2(22, 306),   # Host spawn position for office
        Vector2(100, 250),  # Host spawn position for street
        Vector2(50, 306),   # Player 2 spawn (office)
        Vector2(78, 306),   # Player 3 spawn (office)
        Vector2(106, 306)   # Player 4 spawn (office)
    ]
    
    # Determine appropriate spawn position based on scene and peer ID
    var base_index = 0 if scene_name == "Street" else 0
    var offset = max(0, peer_id - 1) if peer_id > 1 else 0
    var spawn_index = base_index + offset
    
    if spawn_index < spawn_positions.size():
        return spawn_positions[spawn_index]
    else:
        return spawn_positions[0]

func restore_player_state_for_scene(peer_id: int, target_scene: String) -> Dictionary:
    """Restore player state optimized for target scene"""
    var complete_state = get_complete_player_state(peer_id)
    if complete_state.is_empty():
        print("⚠️ No complete state found for player ", peer_id, ", using basic data")
        return get_player_data(peer_id)
    
    # Update position for target scene
    var scene_position = get_player_position_for_scene(peer_id, target_scene)
    complete_state["position"] = scene_position
    complete_state["current_scene"] = target_scene
    
    print("🔄 Restored state for player ", peer_id, " transitioning to ", target_scene)
    return complete_state

func update_player_scene_info(peer_id: int, scene_name: String, position: Vector2):
    """Update player's current scene and position"""
    if complete_player_states.has(peer_id):
        complete_player_states[peer_id]["current_scene"] = scene_name
        complete_player_states[peer_id]["position"] = position
        complete_player_states[peer_id]["last_updated"] = Time.get_unix_time_from_system()
        
        # Store scene-specific position
        if not scene_specific_positions.has(peer_id):
            scene_specific_positions[peer_id] = {}
        scene_specific_positions[peer_id][scene_name] = position
    
    # Update main registry as well
    if players_data.has(peer_id):
        players_data[peer_id]["position"] = position

func get_players_in_scene(scene_name: String) -> Array:
    """Get all players currently in a specific scene"""
    var players_in_scene = []
    for peer_id in complete_player_states:
        var state = complete_player_states[peer_id]
        if state.get("current_scene", "") == scene_name and not state.get("is_eliminated", false):
            players_in_scene.append({
                "peer_id": peer_id,
                "name": state.get("name", ""),
                "position": state.get("position", Vector2.ZERO)
            })
    return players_in_scene

func mark_player_eliminated(peer_id: int, outcome: String):
    """Mark a player as eliminated"""
    if complete_player_states.has(peer_id):
        complete_player_states[peer_id]["is_eliminated"] = true
        complete_player_states[peer_id]["game_outcome"] = outcome
        complete_player_states[peer_id]["last_updated"] = Time.get_unix_time_from_system()
    
    # Update main registry as well
    if players_data.has(peer_id):
        players_data[peer_id]["is_eliminated"] = true
        players_data[peer_id]["game_outcome"] = outcome

func clear_scene_transition_data():
    """Clear scene transition data for new game"""
    complete_player_states.clear()
    scene_specific_positions.clear()
    print("🧹 Cleared all scene transition data")

# Enhanced store_player_data for backward compatibility
func store_player_data(peer_id: int, player_data: Dictionary):
    """Enhanced store_player_data that also updates complete state"""
    # Update main registry (existing functionality)
    players_data[peer_id] = player_data.duplicate()
    
    # Also store in complete state system if we have enough data
    if player_data.has("name") and player_data.has("sprite_path"):
        store_complete_player_state(peer_id, player_data) 