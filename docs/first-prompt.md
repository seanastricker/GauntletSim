Good morning, I am starting a new project as part of a program.  The project is developing a game. 

Specifications include:
Multiplayer Support - real-time interaction between multiple players
Performance - low latency, high performance gameplay with no lag
Platform - can be mobile, web, or desktop application
Complexity - must include levels or character progression (players need a sense of advancement)
Engagement - fun, interesting gameplay with clear objectives or storyline

Some development pathways that were recommended to me include:
Path 1: Desktop Game Development with Godot
     - engine: Godot
     - language: GDScript
     - Networking: Godot's built-in multiplayer API
     - Pros: Godot has exceptional documentation, thousands of tutorials, and GDScript is designed to be beginner friendly. 
Path 2: Browser-Based Game
     - Framework: Phaser 3 (2D) or Three.js (3D)
     - Language: JavaScript
     - Networking: Socket.io for real-time multiplayer
     - Pros: both frameworks have extensive documentation. Phaser 3 is perfect for 2D games with built-in physics and animations.  Three.js opens up 3D possibilities.  Socket.io simplifies multiplayer implementation
Path 3: Unity for Cross-Platform
     - Engine: Unity
     - Language: C#
     - Networking: Unity Netcode for GameObjects or Mirror Networking
     - Platform: Desktop or WebGL build
     - Pros: Unity has the largest game development community, countless tutorials, and comprehensive documentation. C# is well-structured and extensively covered by AI training data

Keep in mind that this is my first time developing a game and I am using Cursor to generate code via prompts I provide.  I typically use Gemini 2.5 Pro, claude 4 sonnet, and Claude 4 Opus.  I am also open to trying out Grok 4 if that would be beneficial.  I was told Path 1 would be easier than Path 2 which would be easier than Path 3 generally speaking.

I want you to help me choose the right technology for my chosen game.  We should analyze game requirements against available technologies, compare pros/cons of different tech stacks, and make an informed decision based on project constraints.  We should create a learning path as well.  This includes generating a customized curriculum for my chosen stack, focusing on essential concepts needed for my game, and building small proof-of-concept demos to validate understanding.  We should also plan out architecture.  This includes designing game architecture, planning networking infrastructure for multiplayer support, and identifying potential performance bottlenecks early.

To ensure I make consistent progress, we should start with single-player mechanics, debug and optimize unfamiliar code patterns, and implement core gameplay loop.  From there, we can start integrating multiplayer, including adding networking layer, implementing state synchronization, and handling player connections/disconnections.  Next, we can optimize performance.  We should profile and identify bottlenecks, use AI to suggest optimization strategies, and ensure smooth gameplay with multiple concurrent players.

Finally, we can polish and test.  This includes adding progression systems or storyline elements, implementing UI/UX improvements, and balancing game mechanics based on testing.  We also should test with maximum expected concurrent players, verify low-latency performance, and fix any remaining bugs or issues.  We also will need to create setup and deployment instructions, document my learning process and AI utilization, and prepare demonstration materials.

The Evaluation Criteria include:
1. Technical Achievement
     - Successfully implementing multiplayer functionality
     - Meeting performance requirements
     - Code quality despite unfamiliar tech stack
2. Learning Velocity & Methodology
     - How quickly you became productive in new technologies
     - Documentation of your learning tools and resources
     - Specific AI prompts and techniques that accelerated learning
     - Learning pathway decisions and pivots
3. Game Quality
     - Fun factor and engagement
     - Implementation of levels or progression system
     - Polish and attention to detail
4. AI Utilization
     - Strategic use of AI tools for learning
     - Problem-solving efficiency with AI assistance
     - Innovation in applying AI to development challenges
     - Quality of prompts and interactions with AI

Deliverables:
1. Working game
     - Deployed and accessible for testing
     - supporting multiple concurrent players
     - meeting all technical requirements
2. GitHub Repository
     - Architecture overview
     - Setup and deployment guide
     - Key technical decisions and rationale
3. Brainlift
     - Daily progress updates
     - AI prompts and interactions that accelerated learning
     - Challenges faced and solutions found
4. Demo Video
     - 5-minute gameplay demonstration
     - Technical walkthrough of key features
     - Reflection on AI-augmented development process

Success Metrics:
     - A fully functional multiplayer game in a previously unknown tech stack
     - Development velocity comparable to or exceeding traditional methods
     - Effective AI utilization throughout the learning and building process
     - A fun, engaging game that showcases technical competence

Some final notes:  
It was recommended to me to use Elements Envato which I believe has game assets which would be easier than creating my own.
It is vital that architecture for multiplayer is planned out, so when we are later implementing multiplayer on top of our single player game, we don't experience significant issues
I would like you to make a markdown file named 'project-overview.md' which includes all of this information.
You should also create a markdown file named 'brainlift.md' that will be used to capture daily progress updates, AI prompts and interactions that accelerated learning, and challenges faced and solutions found. This brainlift.md file should also include documentation of my learning tools/resources and learning pathway decisions and pivots.
These markdown files should be placed inside the docs folder.

Whenever you are ready, we can start discussing game ideas and determine the best option and approach given these instructions.