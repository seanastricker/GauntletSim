# PlayerData.gd - Player data management for single and multiplayer
# Handles player information storage and synchronization
extends Node

# Player data for single-player compatibility
var player_name: String
var player_sprite_path: String

# Multiplayer player registry
var players_data: Dictionary = {}

# Signal emitted when player registry is synchronized from server
signal player_registry_updated

# Game end data for transitions
var game_end_outcome: String = ""
var game_end_player_name: String = ""
var game_end_time_lasted: float = 0.0
var game_end_health: int = 0
var game_end_social: int = 0
var game_end_ccat: int = 0

# All players' results for GameEnd scene
var all_player_results: Dictionary = {}
signal player_result_added(player_name: String, outcome: String, time_lasted: float)

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
    """Store game end data for scene transition"""
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

func add_player_result(player_name: String, outcome: String, time_lasted: float):
    """Add a player's result to the global results"""
    all_player_results[player_name] = {
        "outcome": outcome,
        "time_lasted": time_lasted
    }
    print("📊 PlayerData: Added result for ", player_name, " - ", outcome, " (", time_lasted, "s)")
    
    # Emit signal for GameEnd scenes to listen to
    player_result_added.emit(player_name, outcome, time_lasted)

func get_all_player_results() -> Dictionary:
    """Get all player results"""
    return all_player_results

func clear_all_player_results():
    """Clear all player results"""
    print("📊 PlayerData: BEFORE clearing - Results count: ", all_player_results.size())
    print("📊 Previous results: ", all_player_results)
    all_player_results.clear()
    print("📊 PlayerData: AFTER clearing - Results count: ", all_player_results.size())
    print("📊 PlayerData: All player results cleared successfully")

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