# GauntletSim - Game Design Document

## Game Concept

**Genre:** Social Life Simulation RPG with Real-time Multiplayer  
**Platform:** Desktop (Godot Engine)  
**Target Players:** 2-10 concurrent players  
**Visual Style:** 2D top-down perspective (Pokemon-inspired)  

## Core Concept

GauntletSim is a 2D multiplayer life simulation game where players navigate a city environment and make decisions that affect their character's stats. Players interact with various locations around the city, each offering different activities that influence their Health, Social, and Intelligence stats. The game emphasizes trade-offs between different life aspects, creating meaningful decision-making and emergent social dynamics.

## Core Mechanics

### Player Stats System
- **Health**: Improved through exercise, rest, healthy eating
- **Social**: Enhanced by interacting with friends, attending social events
- **CCAT Score**: Increased through work, studying, learning activities (cognitive assessment)
- **Stat Trade-offs**: Actions can positively affect one stat while negatively impacting another
  - Example: Working late increases CCAT Score but decreases Health and Social
- **Stat Constraints**: All stats range from 0 (minimum) to 50 (maximum)
- **Natural Decay**: All stats naturally decrease over time to encourage active gameplay
- **Interaction Cooldowns**: Activities have cooldown periods to prevent rapid stat farming

### World Navigation
- **Pokemon-style Movement**: Top-down 2D grid-based or free movement
- **Location Transitions**: Walk up to doors/entrances to get interaction prompts
- **Confirmation System**: "Would you like to enter?" dialog boxes
- **Seamless Room Loading**: Scene transitions between different locations

### Interaction System
- **Environmental Interactions**: Click/interact with objects in rooms
- **NPC Interactions**: Talk to non-player characters (starting with 3 office NPCs: Ash, Rebecca, Austen)
- **Player-to-Player Interaction**: See other players' activities (no direct stat effects between players)
- **Activity Confirmation**: Clear feedback on stat changes from actions
- **Cooldown System**: Activities have cooldown timers to prevent rapid stat farming

### Character System
- **Character Creation**: New players select from preset sprite options to represent themselves
- **Name Display**: Player-chosen names are displayed at all times above characters
- **Stat Privacy**: Individual player stats are private (not visible to other players)
- **Persistence**: Character data, stats, and customization save between game sessions

## World Design

### Location Types
**Initial Implementation:** Starting with Office location, expanding to other locations in subsequent phases.

1. **Office** *(Initial Focus)*
   - Activities: Work at desk, attend meetings, use computer
   - Primary Stat: CCAT Score (+)
   - Secondary Effects: Health (-), Social (-)
   - Cooldowns: Each work activity has cooldown period
   - **NPCs**: 3 permanent office workers
     - Ash (Office Worker)
     - Rebecca (Office Worker) 
     - Austen (Office Worker)

2. **Apartment Building / Home** *(Future)*
   - Activities: Sleep, cook, watch TV, clean
   - Primary Stat: Health (+)
   - Secondary Effects: Variable based on activity
   - Special: Private rooms (not shared spaces)

3. **Bar/Restaurant** *(Future)*
   - Activities: Eat, drink, socialize with patrons
   - Primary Stat: Social (+)
   - Secondary Effects: Health (-/+), CCAT Score (-)

4. **Gym/Recreation Center** *(Future)*
   - Activities: Exercise, sports, fitness classes
   - Primary Stat: Health (+)
   - Secondary Effects: Social (+), CCAT Score (-)

5. **Park/Outdoor Areas** *(Future)*
   - Activities: Walk, jog, socialize, relax
   - Balanced stat effects across all three

## Technical Architecture

### Engine Choice: Godot
**Rationale:**
- Excellent documentation and tutorials
- GDScript designed for beginners
- Built-in multiplayer API
- Strong 2D capabilities
- Free and open-source

### Scene Structure
```
Main Scene Manager
├── UI Overlay (HUD, stats, inventory)
├── Player Character Scene
├── Room Scenes
│   ├── Office Scene
│   ├── Apartment Scene
│   ├── Bar Scene
│   └── [Additional Location Scenes]
└── Multiplayer Manager
```

### Core Systems
1. **Movement System**: 2D character controller with collision detection
2. **Scene Transition System**: Handles loading between different locations
3. **Stat Management System**: Tracks and updates player statistics
4. **Interaction System**: Manages player-object and player-player interactions
5. **UI System**: Displays stats, notifications, and interaction prompts
6. **Networking System**: Handles multiplayer synchronization

## Development Phases

### Phase 1: Single-Player Foundation (Office Focus)
- Character creation system with sprite selection and name entry
- Basic player movement and animation
- Office scene implementation with work activities
- 3 Office NPCs implementation (Ash, Rebecca, Austen)
- Core stat system (Health, Social, CCAT Score) with 0-50 range
- Basic interaction system with cooldowns
- UI for stat display and character names
- Stat decay system implementation
- Integration of purchased assets for characters and environments

### Phase 2: Content Expansion
- Add additional locations (Apartment, Bar/Restaurant, Gym, Park)
- Implement varied activities and interactions for each location
- Private apartment rooms vs. shared spaces
- Enhanced UI and feedback systems
- Save/load system for character persistence
- Fine-tune stat decay rates and cooldown timers

### Phase 3: Multiplayer Integration
- Implement Godot's MultiplayerAPI
- Player synchronization across rooms
- Real-time stat updates between players
- Chat system or player interaction features

### Phase 4: Scaling and Polish
- Scale from 2 to 10 concurrent players
- Performance optimization
- Advanced multiplayer features
- Balancing and playtesting

## Design Decisions (Resolved)

### Stat System ✓
- **Decay Rate**: ✓ Stats naturally decrease over time to encourage active gameplay
- **Balancing**: TBD - Optimal rate of stat change needs testing and balancing
- **Caps**: ✓ Stats range from 0 (minimum) to 50 (maximum)
- **Persistence**: ✓ Stats save between sessions
- **Cooldowns**: ✓ Interactions have cooldown periods to prevent stat farming

### Player Interaction ✓
- **Direct Interaction**: ✓ Players cannot directly affect each other's stats
- **Visibility**: ✓ Players cannot see other players' stats (privacy maintained)
- **Cooperation**: ✓ No activities require multiple players (all solo-accessible)
- **Competition**: ✓ No competitive elements implemented

### Room Design ✓
- **Capacity Limits**: ✓ No player limits in rooms
- **Instancing**: ✓ Shared spaces for all rooms except apartment/private rooms
- **Dynamic Events**: ✓ No time-based events in rooms

### Progression System ✓
- **Unlockables**: ✓ All locations/activities available immediately (no progression gates)
- **Achievements**: ✓ No clear goals or milestones (open-ended gameplay)
- **Character Customization**: ✓ Preset sprite options + name entry during character creation

## Remaining Technical Questions

### Implementation Details (TBD)
- **Stat Decay Rate**: How fast should stats decrease? (needs playtesting)
- **Cooldown Timers**: Optimal cooldown duration for different activities
- **Network Optimization**: Best practices for 10-player synchronization
- **Save System**: Local vs. server-based character data storage

## Technical Considerations

### Networking Challenges
- **State Synchronization**: Keeping all players' views consistent
- **Latency Handling**: Ensuring smooth real-time interactions
- **Connection Management**: Handling player disconnections gracefully
- **Scalability**: Performance with 10 concurrent players

### Performance Optimization
- **Scene Management**: Efficient loading/unloading of room scenes
- **Network Traffic**: Minimizing data transmission
- **Resource Management**: Sprites, animations, and audio assets
- **Memory Usage**: Particularly important for longer play sessions
- **Asset Strategy**: Use purchased/premium assets for faster development and better visual quality

### Data Persistence
- **Save System**: Player stats, progress, and customization
- **Server Architecture**: Local hosting vs. dedicated servers
- **Data Security**: Preventing stat manipulation or cheating

## Success Metrics

### Core Functionality
- Smooth multiplayer experience with 2-10 players
- Stable stat system with meaningful trade-offs
- Intuitive navigation and interaction systems
- Engaging gameplay loop that encourages repeated play

### Technical Achievement
- Low-latency multiplayer performance
- Efficient scene transitions
- Robust networking without disconnection issues
- Clean, maintainable codebase

### Player Experience
- Clear feedback on stat changes and consequences
- Balanced difficulty and progression
- Social elements that encourage player interaction
- Replayability through different stat optimization strategies

## Next Steps

1. **Set up Godot project structure**
2. **Create basic player movement system**
3. **Implement simple room transition**
4. **Build core stat system**
5. **Add first interactive objects**
6. **Integrate multiplayer functionality**
7. **Scale and optimize for target player count**

---

*This document will be updated as development progresses and design decisions are finalized.* 