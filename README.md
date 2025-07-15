# GauntletSim

A 2D multiplayer life simulation game built with Godot Engine where players navigate a city environment and make decisions that affect their character's stats.

![Godot Engine](https://img.shields.io/badge/Godot-4.3-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Status](https://img.shields.io/badge/status-In%20Development-yellow.svg)

## 🎮 Game Overview

GauntletSim is a social life simulation RPG with real-time multiplayer support. Players navigate a Pokemon-inspired top-down 2D city environment, making choices that balance their Health, Social, and CCAT Score (cognitive assessment) stats. Every decision has trade-offs, creating meaningful gameplay and emergent social dynamics.

### Key Features

- **Real-time Multiplayer**: Support for 2-10 concurrent players
- **Stat Management System**: Balance Health, Social, and CCAT Score with meaningful trade-offs
- **Dynamic Environment**: Multiple locations including office, apartments, restaurants, gym, and parks
- **Character Customization**: Choose from various character sprites and customize your appearance
- **Persistent Progress**: Character data and stats save between sessions
- **Activity Cooldowns**: Strategic timing required for stat optimization

## 🛠️ Technology Stack

- **Engine**: Godot 4.3
- **Language**: GDScript
- **Networking**: Godot's built-in MultiplayerAPI
- **Platform**: Desktop (Windows, macOS, Linux)
- **Assets**: Premium character and environment assets from Elements Envato

## 📋 Prerequisites

- [Godot Engine 4.3](https://godotengine.org/download) or later
- Git for version control
- 2GB of free disk space

## 🚀 Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/seanastricker/GauntletSim.git
cd GauntletSim
```

2. Open Godot Engine

3. Click "Import" and navigate to the cloned repository folder

4. Select the `project.godot` file and click "Import & Edit"

### Running the Game

1. In Godot, press `F5` or click the "Play" button
2. The game will launch in debug mode
3. Use arrow keys or WASD to move your character

## 🎯 Gameplay

### Controls

- **Movement**: Arrow keys or WASD
- **Interact**: E key or Space bar
- **Menu**: ESC key

### Current Locations

- **Office**: Work activities that increase CCAT Score but decrease Health and Social
  - NPCs: Ash, Rebecca, and Austen (office workers)

### Planned Locations

- **Apartment**: Rest and personal activities
- **Bar/Restaurant**: Social activities
- **Gym**: Health-focused activities
- **Park**: Balanced outdoor activities

## 🏗️ Development Status

The project is currently in **Phase 1: Single-Player Foundation** focusing on:

- ✅ Basic player movement and animation
- ✅ Office scene implementation
- ✅ Core stat system (0-50 range)
- ✅ NPC implementation
- 🔄 Interaction system with cooldowns
- 🔄 UI for stat display

### Roadmap

**Phase 2: Content Expansion**
- Additional locations (Apartment, Bar, Gym, Park)
- More activities and interactions
- Save/load system
- Enhanced UI and feedback

**Phase 3: Multiplayer Integration**
- Real-time player synchronization
- Chat system
- Shared world spaces

**Phase 4: Polish & Optimization**
- Performance optimization for 10 players
- Advanced features
- Balancing and playtesting

## 🤝 Contributing

This project was created as part of a game development challenge to build a multiplayer game using unfamiliar technology. Contributions and feedback are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Documentation

- [Game Design Document](docs/gauntletsim.md)
- [Project Overview](docs/project-overview.md)
- [Brainlift Development Log](docs/brainlift.md)

## 🎨 Assets

This project uses premium assets from:
- Character Generator pack for character sprites and customization
- Modern Office pack for environment assets
- UI Elements pack for interface design

## 🐛 Known Issues

- Multiplayer functionality not yet implemented
- Limited to office location in current build
- Stat decay rates need balancing
- Activity cooldown timers require fine-tuning

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Contact

**Developer**: Sean Astricker  
**GitHub**: [@seanastricker](https://github.com/seanastricker)  
**Project Link**: [https://github.com/seanastricker/GauntletSim](https://github.com/seanastricker/GauntletSim)

## 🙏 Acknowledgments

- Godot Engine community for excellent documentation
- Elements Envato for high-quality game assets
- AI-assisted development using Cursor and Claude

---

*This game is being developed as part of a technical challenge to demonstrate rapid learning and development using AI-augmented tools in an unfamiliar technology stack.* 