# GauntletSim - Multiplayer Integration Phases

## Overview

This document outlines a comprehensive, step-by-step plan to implement multiplayer functionality in GauntletSim without breaking existing single-player systems. The plan is designed to be safe, incremental, and easily reversible if issues arise.

## Current State Analysis

### ✅ Working Systems
- Character creation with PlayerData singleton
- Single-player movement and interactions
- Office scene with NPCs and interactive objects
- Stat system with decay and cooldowns
- Working UI and animation systems

### ❌ Missing Systems
- Multiplayer infrastructure
- Lobby system
- Player synchronization
- Network authority management

## Target User Flow

1. **Character Creation** → Player selects name and sprite
2. **Lobby Scene** → Player chooses Host or Join Game
3. **Multiplayer Lobby** → Host waits for players, then starts game
4. **Main Scene** → All players enter simultaneously

## Implementation Phases

---

## Phase 1: Lobby Scene Creation
**Goal:** Create lobby infrastructure without modifying existing systems  
**Risk Level:** Low  
**Duration:** 2-3 days

### 1.1 Create Lobby Script

Create `scripts/Lobby.gd`:

```gdscript
# scripts/Lobby.gd - NEW FILE
extends Control

@onready var host_button: Button = $CenterContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/JoinButton
@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPInput
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var players_list: ItemList = $CenterContainer/VBoxContainer/PlayersList
@onready var start_game_button: Button = $CenterContainer/VBoxContainer/StartGameButton

const DEFAULT_PORT = 7000
var multiplayer_peer: ENetMultiplayerPeer

func _ready():
    host_button.pressed.connect(_on_host_pressed)
    join_button.pressed.connect(_on_join_pressed)
    start_game_button.pressed.connect(_on_start_game_pressed)
    start_game_button.visible = false
    
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    
    status_label.text = "Choose Host or Join"
    ip_input.placeholder_text = "localhost"

func _on_host_pressed():
    """Start hosting a multiplayer game"""
    multiplayer_peer = ENetMultiplayerPeer.new()
    var error = multiplayer_peer.create_server(DEFAULT_PORT, 4)  # Max 4 players
    
    if error == OK:
        multiplayer.multiplayer_peer = multiplayer_peer
        status_label.text = "Hosting on port " + str(DEFAULT_PORT)
        start_game_button.visible = true
        host_button.disabled = true
        join_button.disabled = true
        ip_input.editable = false
        
        # Register host player
        PlayerData.register_player(1, PlayerData.player_name, PlayerData.player_sprite_path)
        add_player_to_list(1, PlayerData.player_name + " (Host)")
    else:
        status_label.text = "Failed to host: " + str(error)

func _on_join_pressed():
    """Join an existing multiplayer game"""
    var ip = ip_input.text if ip_input.text else "localhost"
    multiplayer_peer = ENetMultiplayerPeer.new()
    var error = multiplayer_peer.create_client(ip, DEFAULT_PORT)
    
    if error == OK:
        multiplayer.multiplayer_peer = multiplayer_peer
        status_label.text = "Connecting to " + ip + "..."
        host_button.disabled = true
        join_button.disabled = true
        ip_input.editable = false
    else:
        status_label.text = "Failed to connect: " + str(error)

func _on_start_game_pressed():
    """Host starts the game for all players"""
    if multiplayer.is_server():
        status_label.text = "Starting game..."
        start_game.rpc()

func _on_connected_to_server():
    """Called when successfully connected to server as client"""
    status_label.text = "Connected! Waiting for game to start..."
    send_player_data.rpc_id(1, PlayerData.player_name, PlayerData.player_sprite_path)

func _on_connection_failed():
    """Called when connection to server fails"""
    status_label.text = "Connection failed!"
    host_button.disabled = false
    join_button.disabled = false
    ip_input.editable = true

@rpc("call_local", "reliable")
func start_game():
    """Transition all players to the main game scene"""
    get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_peer_connected(id: int):
    """Called when a new peer connects to the server"""
    print("Player connected: ", id)

func _on_peer_disconnected(id: int):
    """Called when a peer disconnects"""
    print("Player disconnected: ", id)
    remove_player_from_list(id)
    PlayerData.remove_player(id)

@rpc("any_peer", "reliable")
func send_player_data(name: String, sprite_path: String):
    """Send player data to the server"""
    var sender_id = multiplayer.get_remote_sender_id()
    PlayerData.register_player(sender_id, name, sprite_path)
    add_player_to_list(sender_id, name)
    print("Registered player: ", name, " with ID: ", sender_id)

func add_player_to_list(id: int, name: String):
    """Add a player to the UI list"""
    players_list.add_item(name)
    players_list.set_item_metadata(players_list.get_item_count() - 1, id)

func remove_player_from_list(id: int):
    """Remove a player from the UI list"""
    for i in range(players_list.get_item_count()):
        if players_list.get_item_metadata(i) == id:
            players_list.remove_item(i)
            break
```

### 1.2 Create Lobby Scene

Create `scenes/Lobby.tscn` with the following structure:

```
Lobby (Control)
└── CenterContainer
    └── VBoxContainer
        ├── TitleLabel ("Multiplayer Lobby")
        ├── StatusLabel ("Choose Host or Join")
        ├── IPInput (LineEdit)
        ├── HBoxContainer
        │   ├── HostButton ("Host Game")
        │   └── JoinButton ("Join Game")
        ├── PlayersList (ItemList)
        └── StartGameButton ("Start Game")
```

### 1.3 Modify Character Creation Flow

In `scripts/CharacterCreation.gd`, change line 42:

```gdscript
# OLD:
get_tree().change_scene_to_file("res://scenes/Main.tscn")

# NEW:
get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
```

### Phase 1 Testing
- ✅ Character creation transitions to lobby
- ✅ Host button creates server
- ✅ Join button attempts connection
- ✅ UI updates appropriately

### ✅ Phase 1 COMPLETED ✅
**Implementation Date:** December 2024  
**Status:** Successfully Implemented and Tested  

#### **What Was Built:**
- **Lobby.gd Script**: Complete multiplayer lobby controller with host/join functionality
- **Lobby.tscn Scene**: Clean UI layout with host/join buttons, player list, and status display
- **Enhanced PlayerData.gd**: Added multiplayer player registry system while maintaining single-player compatibility
- **Modified CharacterCreation.gd**: Seamless transition from character creation to lobby

#### **Technical Achievements:**
- ✅ ENet multiplayer peer creation for up to 4 players
- ✅ RPC (Remote Procedure Call) system for player data synchronization
- ✅ Player list UI with real-time updates
- ✅ Connection status feedback and error handling
- ✅ Fixed Node property shadowing conflicts
- ✅ Zero breaking changes to existing single-player functionality

#### **User Flow Verified:**
1. **Character Creation** → Player selects name and sprite ✅
2. **Lobby Scene** → Player chooses Host or Join Game ✅  
3. **Multiplayer Lobby** → Host waits for players, both players appear in list ✅
4. **Synchronized Transition** → Both instances move to Main scene simultaneously ✅

#### **Multiplayer Testing Results:**
- ✅ **Host Functionality**: Server creation on port 7000 works correctly
- ✅ **Join Functionality**: Client connection to localhost works correctly  
- ✅ **Player Registration**: Both players appear in host's player list
- ✅ **Scene Synchronization**: Start Game button transitions both instances
- ✅ **Error Handling**: Connection failures handled gracefully
- ✅ **UI Responsiveness**: Buttons disable/enable appropriately during connection

#### **Known Limitations (By Design):**
- Players cannot see each other in Main scene yet (requires Phase 3 implementation)
- Each instance runs independent Player objects (will be replaced with MultiplayerPlayer in Phase 3)
- No position synchronization between players (implemented in Phase 3)

#### **Risk Assessment:** 
- **Deployment Risk**: LOW - No breaking changes to existing systems
- **Rollback Capability**: HIGH - Easy to revert by changing one line in CharacterCreation.gd
- **Stability**: HIGH - No crashes or critical errors during testing

#### **Ready for Phase 2:**
The lobby infrastructure provides a solid foundation for Phase 2 (Enhanced PlayerData) and Phase 3 (MultiplayerSpawner Setup). All multiplayer networking components are functional and ready for the next implementation phase.

---

## Phase 2: Enhanced PlayerData for Multiplayer
**Goal:** Extend PlayerData to handle multiple players  
**Risk Level:** Low  
**Duration:** 1-2 days

### 2.1 Enhance PlayerData.gd

Modify `scripts/PlayerData.gd`:

```gdscript
# scripts/PlayerData.gd - MODIFY EXISTING
extends Node

# Local player data (existing)
var player_name: String
var player_sprite_path: String

# Multiplayer player registry
var players_data: Dictionary = {}

func register_player(peer_id: int, name: String, sprite_path: String):
    """Register a player's data for multiplayer synchronization"""
    players_data[peer_id] = {
        "name": name,
        "sprite_path": sprite_path,
        "health": 50,
        "social": 50,
        "ccat_score": 50,
        "position": Vector2(22, 306)  # Default spawn position
    }
    print("Registered player ", name, " with ID ", peer_id)

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
```

### Phase 2 Testing
- ✅ Multiple players can join lobby
- ✅ Player names appear in lobby list
- ✅ PlayerData registry tracks all players
- ✅ Disconnection removes players properly

---

## Phase 3: MultiplayerSpawner Setup
**Goal:** Implement proper multiplayer spawning and synchronization  
**Risk Level:** Medium  
**Duration:** 3-4 days

### 3.1 Create MultiplayerPlayer Script

Create `scripts/MultiplayerPlayer.gd` (based on existing Player.gd):

```gdscript
# scripts/MultiplayerPlayer.gd - NEW FILE
extends CharacterBody2D

# Copy all stat properties from Player.gd
@export var health: int = 50:
    set(value):
        health = clamp(value, 0, 50)
        if health_label and is_multiplayer_authority():
            update_ui()

@export var social: int = 50:
    set(value):
        social = clamp(value, 0, 50)
        if social_label and is_multiplayer_authority():
            update_ui()

@export var ccat_score: int = 50:
    set(value):
        ccat_score = clamp(value, 0, 50)
        if ccat_label and is_multiplayer_authority():
            update_ui()

# Movement and identification
@export var speed: float = 200.0
@export var player_name: String = "":
    set(value):
        player_name = value
        if name_label:
            name_label.text = player_name

# Multiplayer-specific properties
@export var peer_id: int = 1:
    set(id):
        peer_id = id
        set_multiplayer_authority(id)

# UI references (copy from Player.gd)
@onready var health_label: Label = $UI/StatsDisplay/HealthLabel
@onready var social_label: Label = $UI/StatsDisplay/SocialLabel
@onready var ccat_label: Label = $UI/StatsDisplay/CCATLabel
@onready var name_label: Label = $NameLabel
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Timers and systems
var decay_timer: Timer
var decay_rate: float = 10.0
var interaction_cooldowns: Dictionary = {}
var last_direction = Vector2(0, 1)

func _ready() -> void:
    """Initialize the multiplayer player"""
    # Load player data based on peer_id
    var player_data = PlayerData.get_player_data(peer_id)
    
    if player_data.is_empty():
        # Fallback for host or single player
        player_name = PlayerData.player_name
        load_sprite(PlayerData.player_sprite_path)
    else:
        player_name = player_data["name"]
        load_sprite(player_data["sprite_path"])
        health = player_data["health"]
        social = player_data["social"]
        ccat_score = player_data["ccat_score"]
        global_position = player_data["position"]
    
    # Setup UI - only visible for local player
    setup_ui()
    
    # Setup systems
    setup_decay_timer()
    setup_collision()
    update_animation(Vector2.ZERO)
    
    # Only process physics for our own character
    set_physics_process(is_multiplayer_authority())

func setup_ui():
    """Configure UI visibility and styling"""
    var ui_layer = $UI
    ui_layer.visible = is_multiplayer_authority()
    
    if is_multiplayer_authority():
        # Add outlines to UI labels
        name_label.add_theme_color_override("font_color", Color(1, 1, 1))
        name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        name_label.add_theme_constant_override("outline_size", 4)
        
        health_label.add_theme_color_override("font_color", Color(1, 1, 1))
        health_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        health_label.add_theme_constant_override("outline_size", 4)
        
        social_label.add_theme_color_override("font_color", Color(1, 1, 1))
        social_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        social_label.add_theme_constant_override("outline_size", 4)
        
        ccat_label.add_theme_color_override("font_color", Color(1, 1, 1))
        ccat_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        ccat_label.add_theme_constant_override("outline_size", 4)
        
        update_ui()

func load_sprite(sprite_path: String):
    """Load and configure player sprite animations"""
    if not sprite_path:
        return
        
    var sprite_sheet = load(sprite_path)
    if not sprite_sheet:
        return
        
    var new_sprite_frames = SpriteFrames.new()
    
    var anim_definitions = {
        "idle_down": {"y": 32, "x_start": 288, "frames": 6},
        "idle_up": {"y": 32, "x_start": 96, "frames": 6},
        "idle_left": {"y": 32, "x_start": 192, "frames": 6},
        "idle_right": {"y": 32, "x_start": 0, "frames": 6},
        "walk_down": {"y": 64, "x_start": 288, "frames": 6},
        "walk_up": {"y": 64, "x_start": 96, "frames": 6},
        "walk_left": {"y": 64, "x_start": 192, "frames": 6},
        "walk_right": {"y": 64, "x_start": 0, "frames": 6}
    }

    for anim_name in anim_definitions:
        var anim_data = anim_definitions[anim_name]
        new_sprite_frames.add_animation(anim_name)
        new_sprite_frames.set_animation_loop(anim_name, true)
        new_sprite_frames.set_animation_speed(anim_name, 5.0)
        
        for i in range(anim_data["frames"]):
            var atlas_texture = AtlasTexture.new()
            atlas_texture.atlas = sprite_sheet
            atlas_texture.region = Rect2(anim_data["x_start"] + (i * 16), anim_data["y"], 16, 32)
            new_sprite_frames.add_frame(anim_name, atlas_texture)

    animated_sprite.sprite_frames = new_sprite_frames

func _physics_process(delta: float) -> void:
    """Handle movement and synchronization"""
    if is_multiplayer_authority():
        # Handle input and movement for local player
        var input_vector = get_input_vector()
        velocity = input_vector * speed
        move_and_slide()
        update_animation(input_vector)
        
        # Sync position to other players
        if velocity.length() > 0 or input_vector.length() > 0:
            sync_position.rpc_unreliable(global_position, input_vector)

func get_input_vector() -> Vector2:
    """Get normalized input vector from player input"""
    var input_vector = Vector2.ZERO
    if Input.is_action_pressed("ui_right"):
        input_vector.x += 1
    if Input.is_action_pressed("ui_left"):
        input_vector.x -= 1
    if Input.is_action_pressed("ui_down"):
        input_vector.y += 1
    if Input.is_action_pressed("ui_up"):
        input_vector.y -= 1
    return input_vector.normalized()

@rpc("unreliable")
func sync_position(pos: Vector2, input_vec: Vector2):
    """Synchronize position and animation across network"""
    if not is_multiplayer_authority():
        global_position = pos
        update_animation(input_vec)

@rpc("reliable")
func sync_stats(new_health: int, new_social: int, new_ccat: int):
    """Synchronize stats across network"""
    health = new_health
    social = new_social
    ccat_score = new_ccat
    if is_multiplayer_authority():
        update_ui()

# Copy all stat modification functions from Player.gd with RPC calls
func modify_health(amount: int) -> void:
    if is_multiplayer_authority():
        self.health = health + amount
        sync_stats.rpc(health, social, ccat_score)

func modify_social(amount: int) -> void:
    if is_multiplayer_authority():
        self.social = social + amount
        sync_stats.rpc(health, social, ccat_score)

func modify_ccat_score(amount: int) -> void:
    if is_multiplayer_authority():
        self.ccat_score = ccat_score + amount
        sync_stats.rpc(health, social, ccat_score)

# Copy remaining functions from Player.gd
func setup_decay_timer() -> void:
    """Initialize the stat decay system"""
    if is_multiplayer_authority():
        decay_timer = Timer.new()
        decay_timer.wait_time = decay_rate
        decay_timer.autostart = true
        decay_timer.timeout.connect(_on_decay_timer_timeout)
        add_child(decay_timer)

func _on_decay_timer_timeout() -> void:
    """Gradually decrease all stats over time"""
    if is_multiplayer_authority():
        modify_health(-1)
        modify_social(-1)
        modify_ccat_score(-1)

func setup_collision():
    """Setup collision shape"""
    var collision_shape = $CollisionShape2D
    if collision_shape.shape == null:
        var rect_shape = RectangleShape2D.new()
        rect_shape.size = Vector2(24, 17)
        collision_shape.shape = rect_shape

func update_animation(input_vector: Vector2) -> void:
    """Update character animation based on movement"""
    if not animated_sprite:
        return

    if input_vector != Vector2.ZERO:
        last_direction = input_vector

    var anim_direction = "down"
    if abs(last_direction.x) > abs(last_direction.y):
        if last_direction.x > 0:
            anim_direction = "right"
        else:
            anim_direction = "left"
    else:
        if last_direction.y > 0:
            anim_direction = "down"
        else:
            anim_direction = "up"
            
    var anim_prefix = "walk" if input_vector != Vector2.ZERO else "idle"
    var new_animation = anim_prefix + "_" + anim_direction
    
    if animated_sprite.animation != new_animation or not animated_sprite.is_playing():
        animated_sprite.play(new_animation)

func update_ui() -> void:
    """Update the stats display UI"""
    if health_label:
        health_label.text = "Health: " + str(health)
    if social_label:
        social_label.text = "Social: " + str(social)
    if ccat_label:
        ccat_label.text = "CCAT Score: " + str(ccat_score)

# Copy interaction functions from Player.gd
func can_interact(interaction_type: String) -> bool:
    """Check if player can perform interaction based on cooldown"""
    if interaction_type in interaction_cooldowns:
        return Time.get_ticks_msec() >= interaction_cooldowns[interaction_type]
    return true

func start_interaction_cooldown(interaction_type: String, cooldown_seconds: float) -> void:
    """Start cooldown timer for specific interaction type"""
    interaction_cooldowns[interaction_type] = Time.get_ticks_msec() + (cooldown_seconds * 1000)

func work_at_desk() -> void:
    """Handle working at office desk - increases CCAT, decreases Health/Social"""
    if is_multiplayer_authority() and can_interact("work"):
        modify_ccat_score(5)
        modify_health(-2)
        modify_social(-1)
        start_interaction_cooldown("work", 10.0)
        print(player_name + " worked at desk. CCAT +5, Health -2, Social -1")

func interact_with_social_npc():
    """Handle social NPC interaction"""
    if is_multiplayer_authority():
        modify_social(5)
        print(player_name + " talked to a social NPC. Social +5")
```

### 3.2 Create MultiplayerPlayer Scene

Create `scenes/MultiplayerPlayer.tscn` by duplicating `Player.tscn` and:
- Change script to `MultiplayerPlayer.gd`
- Add to "players" group
- Ensure all node paths match

### 3.3 Create Main Scene Manager

Create `scripts/MainSceneManager.gd`:

```gdscript
# scripts/MainSceneManager.gd - NEW FILE
extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready():
    """Initialize the main scene with multiplayer support"""
    # Setup multiplayer callbacks
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    
    # If we're the server, spawn all players
    if multiplayer.is_server():
        call_deferred("spawn_all_players")

func spawn_all_players():
    """Spawn all registered players"""
    # Spawn host player (always ID 1)
    spawn_player(1)
    
    # Spawn all connected clients
    for peer_id in multiplayer.get_peers():
        spawn_player(peer_id)

func spawn_player(peer_id: int):
    """Spawn a specific player"""
    var player_scene = preload("res://scenes/MultiplayerPlayer.tscn")
    var player_instance = player_scene.instantiate()
    
    # Configure player
    player_instance.name = "Player_" + str(peer_id)
    player_instance.peer_id = peer_id
    
    # Set spawn position (spread players out)
    var spawn_positions = [
        Vector2(22, 306),   # Original spawn
        Vector2(50, 306),   # Offset right
        Vector2(78, 306),   # Offset right more
        Vector2(106, 306),  # Offset right most
    ]
    
    var existing_players = get_children().filter(func(child): return child.is_in_group("players"))
    var spawn_index = existing_players.size()
    player_instance.global_position = spawn_positions[spawn_index % spawn_positions.size()]
    
    # Add to scene
    add_child(player_instance, true)
    print("Spawned player with ID: ", peer_id, " at position: ", player_instance.global_position)

func _on_peer_connected(peer_id: int):
    """Handle new peer connection"""
    print("New peer connected: ", peer_id)
    call_deferred("spawn_player", peer_id)

func _on_peer_disconnected(peer_id: int):
    """Handle peer disconnection"""
    print("Peer disconnected: ", peer_id)
    var player_node = get_node_or_null("Player_" + str(peer_id))
    if player_node:
        player_node.queue_free()
```

### 3.4 Modify Main.tscn

Update `scenes/Main.tscn`:
1. Remove the existing Player instance
2. Add a new Node2D as child with `MainSceneManager.gd` script
3. Add MultiplayerSpawner as child of MainSceneManager
4. Configure MultiplayerSpawner:
   - **Spawn Path:** Set to the MainSceneManager node
   - **Scene:** Set to MultiplayerPlayer.tscn
   - **Spawn Function:** Leave empty (uses default)

### Phase 3 Testing
- ✅ Multiple players spawn in Main scene
- ✅ Players can see each other moving
- ✅ Each player only controls their own character
- ✅ Player names display correctly
- ✅ Stats update independently

---

## Phase 4: Interaction Synchronization
**Goal:** Ensure interactions work properly across multiplayer  
**Risk Level:** Low  
**Duration:** 1-2 days

### 4.1 Modify Desk.gd for Multiplayer

Update `scripts/Desk.gd`:

```gdscript
# In Desk.gd, modify the _process function:
func _process(_delta):
    if interaction_prompt.visible and Input.is_action_just_pressed("interact"):
        var bodies = get_overlapping_bodies()
        for body in bodies:
            if body.is_in_group("player") and body.has_method("work_at_desk"):
                # Only process if this is the local player's character
                if body.is_multiplayer_authority():
                    body.work_at_desk()
                    print("Player is working: ", body.player_name)
                    # Hide prompt after interaction to avoid spamming
                    interaction_prompt.visible = false
                    break
```

### 4.2 Modify NPC Scripts for Multiplayer

Update `scripts/VisibleNPC.gd`:

```gdscript
# In VisibleNPC.gd, modify the input handling:
func _unhandled_input(_event):
    if player_in_range and Input.is_action_just_pressed("interact"):
        # Find the player that should handle this input
        var overlapping_players = area.get_overlapping_bodies().filter(
            func(body): return body.is_in_group("player") and body.is_multiplayer_authority()
        )
        
        if overlapping_players.size() > 0:
            var player = overlapping_players[0]
            if player.has_method("interact_with_social_npc"):
                player.interact_with_social_npc()
            
            # Show dialogue for all players to see
            show_dialogue.rpc()

@rpc("call_local", "reliable")
func show_dialogue():
    """Show dialogue to all players"""
    dialogue_label.visible = true
    dialogue_timer.start()
```

Update `scripts/VisibleSocialNPC.gd` (if different from VisibleNPC.gd):

```gdscript
# Similar modifications to ensure only the interacting player gets stat benefits
# but all players see the dialogue
```

### Phase 4 Testing
- ✅ Players can interact with desks without conflicts
- ✅ Only the interacting player gets stat changes
- ✅ NPC dialogues appear for all players
- ✅ Interaction cooldowns work per player

---

## Phase 5: Polish and Error Handling
**Goal:** Add robustness and quality-of-life improvements  
**Risk Level:** Low  
**Duration:** 2-3 days

### 5.1 Enhanced Connection Management

Update `scripts/MainSceneManager.gd`:

```gdscript
# Add to MainSceneManager.gd:
func _ready():
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    
    if multiplayer.is_server():
        call_deferred("spawn_all_players")

func _on_server_disconnected():
    """Handle server disconnection"""
    print("Lost connection to server!")
    # Return to lobby or main menu
    get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")

func cleanup_disconnected_player(peer_id: int):
    """Clean up resources for disconnected player"""
    var player_node = get_node_or_null("Player_" + str(peer_id))
    if player_node:
        player_node.queue_free()
    
    PlayerData.remove_player(peer_id)
```

### 5.2 UI Improvements

Add to `scripts/MultiplayerPlayer.gd`:

```gdscript
# Add network status indicator
func _ready():
    # ... existing code ...
    
    # Add network status for non-authority players
    if not is_multiplayer_authority():
        # Dim the non-local players slightly
        modulate = Color(0.8, 0.8, 0.8, 1.0)
    
    # Add ping display for local player
    if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
        add_ping_display()

func add_ping_display():
    """Add ping display for the local player"""
    var ping_label = Label.new()
    ping_label.name = "PingLabel"
    ping_label.text = "Ping: --"
    ping_label.position = Vector2(10, 10)
    ping_label.add_theme_color_override("font_color", Color.YELLOW)
    $UI.add_child(ping_label)
    
    # Update ping every second
    var ping_timer = Timer.new()
    ping_timer.wait_time = 1.0
    ping_timer.autostart = true
    ping_timer.timeout.connect(update_ping)
    add_child(ping_timer)

func update_ping():
    """Update ping display"""
    var ping_label = $UI.get_node_or_null("PingLabel")
    if ping_label and multiplayer.has_multiplayer_peer():
        # This is a simplified ping - Godot doesn't have built-in ping measurement
        ping_label.text = "Players: " + str(PlayerData.get_all_players().size())
```

### 5.3 Error Recovery

Create `scripts/NetworkManager.gd` (singleton):

```gdscript
# scripts/NetworkManager.gd - NEW AUTOLOAD
extends Node

signal connection_established
signal connection_failed
signal player_joined(peer_id: int)
signal player_left(peer_id: int)

func _ready():
    """Initialize network manager"""
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_peer_connected(peer_id: int):
    player_joined.emit(peer_id)

func _on_peer_disconnected(peer_id: int):
    player_left.emit(peer_id)

func _on_connected_to_server():
    connection_established.emit()

func _on_connection_failed():
    connection_failed.emit()

func _on_server_disconnected():
    print("Server disconnected! Returning to character creation...")
    get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")

func disconnect_from_session():
    """Cleanly disconnect from multiplayer session"""
    if multiplayer.has_multiplayer_peer():
        multiplayer.multiplayer_peer.close()
    PlayerData.players_data.clear()
```

Add NetworkManager to autoloads in project settings.

### 5.4 Fallback for Single Player

Update `scripts/MainSceneManager.gd`:

```gdscript
func _ready():
    # ... existing code ...
    
    # Handle single-player mode
    if not multiplayer.has_multiplayer_peer():
        setup_single_player()

func setup_single_player():
    """Setup single player mode (fallback)"""
    print("Setting up single-player mode")
    
    # Use the original Player scene for single player
    var player_scene = preload("res://scenes/Player.tscn")
    var player_instance = player_scene.instantiate()
    player_instance.global_position = Vector2(22, 306)
    add_child(player_instance)
```

### Phase 5 Testing
- ✅ Clean disconnection handling
- ✅ Server disconnection recovery
- ✅ Single-player mode still works
- ✅ Visual feedback for multiplayer status
- ✅ Performance remains stable

---

## Implementation Timeline

### Week 1
- **Days 1-2:** Phase 1 (Lobby Scene)
- **Days 3-4:** Phase 2 (PlayerData Enhancement)
- **Day 5:** Testing and refinement

### Week 2  
- **Days 1-3:** Phase 3 (MultiplayerSpawner Setup)
- **Day 4:** Phase 4 (Interaction Synchronization)
- **Day 5:** Phase 5 (Polish and Error Handling)

## Risk Mitigation Strategy

### Backup Strategy
- Create git branch before each phase
- Keep working version tagged before major changes
- Test each phase thoroughly before proceeding

### Testing Protocol
1. **Single Player Testing:** Ensure existing functionality still works
2. **Two Player Testing:** Basic host/client functionality
3. **Multi Player Testing:** 3-4 players simultaneously
4. **Network Failure Testing:** Simulate disconnections and reconnections
5. **Performance Testing:** Check for frame rate issues with multiple players

### Rollback Plan
If any phase fails:
1. Revert to previous git branch
2. Identify specific issue
3. Create minimal fix
4. Re-test before proceeding

## Success Criteria

### Technical Achievements
- ✅ Stable 2-4 player multiplayer sessions
- ✅ Synchronized player movement and stats
- ✅ Working interaction system without conflicts
- ✅ Proper handling of connections/disconnections
- ✅ Maintained single-player compatibility

### Performance Targets
- ✅ 60 FPS with 4 players
- ✅ Sub-100ms input response time
- ✅ No memory leaks during long sessions
- ✅ Stable network performance over 30+ minutes

### User Experience Goals
- ✅ Intuitive lobby system
- ✅ Clear feedback on connection status
- ✅ Smooth transition between scenes
- ✅ No confusing UI or controls

## Common Pitfalls Avoided

### Authority Conflicts
- **Problem:** Multiple players trying to control the same object
- **Solution:** Clear authority assignment using `is_multiplayer_authority()`

### Race Conditions
- **Problem:** Network messages arriving out of order
- **Solution:** Use reliable RPCs for critical state changes

### State Desynchronization
- **Problem:** Players seeing different game states
- **Solution:** Server authoritative design with client prediction

### Input Conflicts
- **Problem:** Multiple players' inputs affecting same objects
- **Solution:** Authority-based input handling

### Scene Management Issues
- **Problem:** Players spawning in wrong scenes or duplicate spawns
- **Solution:** Proper MultiplayerSpawner configuration and deferred spawning

## Future Considerations

### Scalability
- Current plan supports 2-4 players
- Can be extended to 6-8 players with minor modifications
- Would need dedicated server for 10+ players

### Additional Features
- Voice chat integration
- Player statistics tracking
- Room persistence
- Spectator mode
- Reconnection support

### Performance Optimization
- Spatial partitioning for large worlds
- Interest management for distant players
- Network compression for mobile support

---

## Conclusion

This phased approach ensures a safe, incremental implementation of multiplayer functionality while preserving the existing single-player experience. Each phase builds upon the previous one with clear testing criteria and rollback strategies.

The plan specifically addresses the common causes of multiplayer implementation failures through proper authority management, scene control, and network synchronization. By following this roadmap, GauntletSim will successfully transition from a single-player to a multiplayer experience without breaking existing functionality. 