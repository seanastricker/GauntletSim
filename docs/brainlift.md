# Brainlift

This document serves as a log for the game development project. It will be updated regularly to track progress, learnings, and challenges.

## Learning Tools and Resources
*This section will document the tools, tutorials, documentation, and other resources used throughout the project.*

- **Primary AI Assistant:** Gemini 2.5 Pro (via Cursor)
- **Game Asset Library:** LimeZu on itch.io
- **Collaboration with Others** Primary source of gaining understanding and tools to look into
- ...

## Learning Pathway Decisions and Pivots
*This section will capture the rationale behind technology choices and any changes in direction during the project.*

- **Initial Decision (2025-07-14):** After analyzing the multiplayer life-simulation game concept, we have chosen to proceed with **Path 1: Godot and GDScript**.
    - **Rationale:** This stack was selected as the optimal choice for a first-time game developer aiming to build a systems-driven RPG.
    - **Comparison:**
        - **Unity (Path 3)** was considered powerful but with a learning curve that was too steep, potentially hindering the project's "Learning Velocity" goal.
        - **Browser-Based (Path 2)** was deemed too low-level, requiring extensive work on engine fundamentals (UI, state management, scene transitions) before core gameplay could be developed.
        - **Godot (Path 1)** offers the best balance. It's a full-featured engine that is beginner-friendly, has an intuitive architecture for the proposed game structure, and includes integrated networking support, which will be critical for the multiplayer requirement.
    - **Strategic Choice:** We will start with a 2D perspective (top-down or isometric) to reduce complexity and focus on implementing the core gameplay loop and stat-based mechanics quickly.

## Daily Progress Updates
*A log of daily activities, achievements, and blockers.*

### Recent Development Sprint
- **Goal:** Implement a fully functional character selection screen and ensure the chosen character is used in-game.
- **Accomplishments:**
  - **Character Creation UI:** Overhauled the scene to include a background image and a new UI section for sprite selection, featuring a preview area and next/previous buttons.
  - **Sprite Selection Logic:** Implemented GDScript logic to load a list of available character sprites (including the original `sean` sprite and new `matt` and `radin` sprites) and allow the user to cycle through them.
  - **Data Persistence:** Created a `PlayerData` singleton to store the player's chosen name and sprite path, successfully passing the selection from the creation scene to the main game scene.
  - **Dynamic Sprite Loading:** Updated the `Player` script to dynamically load the selected spritesheet and generate the necessary `SpriteFrames` and `AtlasTexture` resources at runtime.
- **Challenges:** Faced significant challenges with animation coordinates and automated tooling, which required extensive debugging.
- **Plan for Tomorrow:** Continue with core gameplay development, potentially focusing on expanding NPC interactions or implementing new stat-influencing activities.

### 2025-07-16
- **Today's Goal:** Just Submit
- **Accomplishments:** Implemented collisions, good UI start screen, player name/sprite customization, 3 unique NPCs, walk/idle animations, interacting with environment, stat display, stat decay, stat increase from interactions
- **Challenges:** understanding sprite sheets, implementing animations, understanding the hierarchy of nodes in Godot, trying to use Opus to vibe code (Gemini has been way better), positioning of characters and objects on the map
- **Plan for Tomorrow:** Implement Multiplayer functionality

## AI Prompts and Interactions
*A collection of key prompts, AI responses, and reflections on what worked well or could be improved.*
- **Prompting with exact coordinates of the sprite sheet and of the scenes was extremely helpful**
- **Gemini seems to react better to positive feedback than negative - a serious improvement**
- **I began adding memories so I don't have to repeat myself as much**
- **Providing images of Godot editor does not seem to help, it actually seems to confuse Gemini more**

## Challenges Faced and Solutions Found
*A log of specific technical or conceptual hurdles and how they were overcome.*

### Challenge: Player animations were incorrect after implementing dynamic sprite loading.
- **Context:** After successfully loading new character sprites, their animations in-game were broken (e.g., wrong direction, incorrect frames). The logic that worked for the original `sean_spritesheet.png` did not work for the new ones.
- **Solution:** The issue was that the new spritesheets had a different internal layout (frame order and coordinates) than the original. The fix involved reading the original, working `Player.tscn` to find the exact `x` and `y` coordinates for each of the `sean` sprite's animations. This correct mapping was then hard-coded into the `Player.gd` script's `_ready` function, which dynamically builds the `SpriteFrames` resource. This ensures any spritesheet following the same layout will animate correctly.
- **Key Takeaway:** When dynamically generating resources from assets, you cannot assume the assets share the same layout. Using a known-good asset as a "source of truth" for layout information is a reliable debugging and implementation strategy.

### Challenge: UI elements resized incorrectly when entering fullscreen.
- **Context:** After increasing UI size on the character creation screen using the `scale` property, the elements would shrink back to their original size in fullscreen mode.
- **Solution:** The `scale` property does not work well with Godot's layout system. The correct solution was to remove the `scale` property and instead control the UI size by setting the `theme_override_font_sizes/font_size` property on the `Label`, `LineEdit`, and `Button` nodes.
- **Key Takeaway:** For responsive UI in Godot, manipulate properties the layout system understands (like font size or minimum size) rather than applying transformations like `scale`.

### Challenge: Automated file edits repeatedly corrupted Godot scene files (`.tscn`).
- **Context:** Throughout the session, the AI's automated edits to `.tscn` files frequently resulted in malformed files that Godot could not parse.
- **Solution:** The immediate workaround was a cycle of attempting the edit, reverting the change via `git` or direct user instruction, and then trying a more precise edit. In several cases, the most reliable solution was for the AI to provide the complete, corrected file content in the chat for manual copy-pasting.
- **Key Takeaway:** Automated tooling for complex text formats like `.tscn` can be unreliable. Version control is essential for quick recovery. When automation fails, falling back to manual correction is a necessary and effective solution.

### Challenge: Positioning on Coordinate Plane
- **Context:** Cursor/Gemini was struggling with understanding the exact locations of people and objects.
- **Solution:** Had Gemini guide me through how to utilize Godot and determine coordinate points of objects, people, etc.
- **Key Takeaway:** Sometimes it is better to have AI guide you rather than telling AI what to do.
