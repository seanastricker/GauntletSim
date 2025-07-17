# PlayerData.gd - Player data management for single and multiplayer
# Handles player information storage and synchronization
extends Node

# Local player data (existing)
var player_name: String
var player_sprite_path: String

# Multiplayer player registry
var players_data: Dictionary = {}

func register_player(peer_id: int, display_name: String, sprite_path: String):
    """Register a player's data for multiplayer synchronization"""
    players_data[peer_id] = {
        "name": display_name,
        "sprite_path": sprite_path,
        "health": 50,
        "social": 50,
        "ccat_score": 50,
        "position": Vector2(22, 306)  # Default spawn position
    }
    print("Registered player ", display_name, " with ID ", peer_id)

func get_player_data(peer_id: int) -> Dictionary:
    """Get player data by peer ID"""
    return players_data.get(peer_id, {})

func get_all_players() -> Dictionary:
    """Get all registered players"""
    return players_data

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