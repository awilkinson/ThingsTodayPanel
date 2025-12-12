# Things Today Panel

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
</p>

A beautiful, always-on-top floating panel that displays your Things "Today" tasks. Inspired by Raycast Notes, designed to win Apple Design Awards.

![Things Today Panel](preview.png)

## ✨ Features

- **🎯 Always on Top** - Floating panel that stays visible above all windows
- **🎨 Beautiful Design** - Matches Things for Mac aesthetic with pixel-perfect details
- **⚡️ Lightning Fast** - Native SwiftUI with smooth 60fps animations
- **🔄 Auto-Refresh** - Updates your tasks every 60 seconds automatically
- **⌨️ Keyboard Shortcuts** - Quick access via Raycast or global hotkey
- **🎭 Subtle Animations** - Delightful micro-interactions throughout
- **📱 Non-Intrusive** - Doesn't steal focus, sits quietly in the background
- **🌙 Theme Aware** - Adapts to system light/dark mode

## 🚀 Installation

### Prerequisites

- macOS 13.0 or later
- Things 3 for Mac
- Xcode 15.0 or later
- Raycast (optional, for quick launch)

### Building from Source

1. Clone this repository:
```bash
git clone https://github.com/andrewwilkinson/ThingsTodayPanel.git
cd ThingsTodayPanel
```

2. Open the project in Xcode:
```bash
open ThingsTodayPanel.xcodeproj
```

3. Build and run (⌘R)

### Raycast Integration

1. Copy the Raycast script command:
```bash
cp RaycastScripts/show-things-today.sh ~/.config/raycast/scripts/
chmod +x ~/.config/raycast/scripts/show-things-today.sh
```

2. Open Raycast and search for "Show Things Today"
3. Assign a hotkey (recommended: ⌥T)

## 🎨 Design Philosophy

This app follows Things' design principles:

- **Clarity** - Clean, uncluttered interface
- **Efficiency** - Quick to scan, easy to interact with
- **Delight** - Subtle animations and polish
- **Respect** - Never intrusive, always helpful

### Design Details

- Typography: SF Pro (system font)
- Spacing: 4pt grid system
- Animations: 0.3s spring (response: 0.3, damping: 0.7)
- Colors: Things-inspired blue (#007AFF)
- Shadows: Subtle, system-native

## 🔧 Configuration

### Things Integration

The app uses **AppleScript** to query Things directly - no database access required!

**Setup Steps:**

1. **Get your Things auth token:**
   - Open Things → Settings (⌘,)
   - Go to General tab
   - Enable "Things URLs"
   - Click "Manage" → Copy your token

2. **Add token to Config.swift:**
   ```swift
   static let authToken = "YOUR_TOKEN_HERE"
   ```

3. **Grant AppleScript permissions:**
   - System Settings → Privacy & Security → Automation
   - Enable "Things3" for "Things Today Panel"

**Permissions Required:**
- Automation access to Things3
- Accessibility (for global hotkeys, optional)

### Customization

Edit `Config.swift` to customize:
- Refresh interval (default: 60 seconds)
- Auth token
- Data source preference (AppleScript, URL Scheme, or MCP Server)

## 📱 Usage

### Basic Operations

- **Click task** - Open in Things
- **Click checkbox** - Mark complete/incomplete
- **Hover task** - Highlight for selection
- **Click "New To-Do"** - Add task in Things (⌘N)
- **Click refresh icon** - Manual refresh

### Keyboard Shortcuts

- `⌘N` - New task in Things
- `⌘R` - Refresh tasks
- `⌘W` - Close panel
- `Esc` - Close panel

## 🛠 Architecture

```
ThingsTodayPanel/
├── ThingsTodayPanelApp.swift      # App entry point & lifecycle
├── FloatingPanelWindow.swift      # Custom NSPanel with floating behavior
├── ContentView.swift              # Main SwiftUI view
├── TaskRowView.swift              # Individual task component
├── Models.swift                   # Data models
├── ThingsDataService.swift        # Data layer & Things integration
└── RaycastScripts/
    └── show-things-today.sh       # Raycast launcher script
```

### Key Technologies

- **SwiftUI** - Modern declarative UI
- **Combine** - Reactive data flow
- **AppKit** - Native window management (NSPanel)
- **SQLite** - Direct Things database access

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Roadmap

- [ ] Direct Things MCP server integration
- [ ] Support for custom task filters
- [ ] Keyboard navigation (↑/↓ arrows)
- [ ] Task notes inline editing
- [ ] Drag & drop task reordering
- [ ] Widget customization
- [ ] Multiple window support (Today, Upcoming, etc.)
- [ ] Global hotkey without Raycast

## 🐛 Known Issues

- First launch requires Automation permission for Things3
- Task completion uses Things URL scheme (briefly activates Things)
- AppleScript parsing doesn't include deadline dates (Things limitation)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [Raycast Notes](https://www.raycast.com/core-features/notes)
- Design language from [Things](https://culturedcode.com/things/)
- Built with love for the macOS productivity community

## 📧 Contact

Andrew Wilkinson - [@andrewwilkinson](https://twitter.com/andrewwilkinson)

Project Link: [https://github.com/andrewwilkinson/ThingsTodayPanel](https://github.com/andrewwilkinson/ThingsTodayPanel)

---

<p align="center">Made with ❤️ for Things users</p>
