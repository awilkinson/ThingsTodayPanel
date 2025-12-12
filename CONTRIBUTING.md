# Contributing to Things Today Panel

First off, thank you for considering contributing to Things Today Panel! It's people like you that make this tool amazing.

## Code of Conduct

This project and everyone participating in it is governed by respect and professionalism. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and what you expected**
- **Include screenshots if relevant**
- **Include your environment details** (macOS version, Things version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **Include mockups or examples if applicable**

### Pull Requests

- Fill in the required template
- Follow the Swift style guide
- Include screenshots in your PR for UI changes
- Update documentation as needed
- Add tests if applicable

## Development Process

### Setting Up Development Environment

1. Fork the repo
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ThingsTodayPanel.git
   ```
3. Create a branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```

### Code Style

- Use Swift's standard formatting
- Follow Apple's Human Interface Guidelines
- Keep code clean and well-commented
- Use meaningful variable and function names

### Swift Style Guidelines

```swift
// ✅ Good
func fetchTasks() async throws -> [ThingsTask] {
    // Implementation
}

// ❌ Avoid
func get_tasks() -> [ThingsTask]? {
    // Implementation
}
```

### Design Guidelines

When contributing UI changes:

- **Typography**: Use SF Pro (system font)
- **Spacing**: Follow 4pt grid system
- **Colors**: Use Things-inspired palette (see Models.swift)
- **Animations**: Use spring animations (response: 0.3, damping: 0.7)
- **Icons**: Use SF Symbols where possible

### Commit Messages

Follow conventional commits format:

```
feat: add keyboard navigation
fix: resolve window positioning bug
docs: update README with setup instructions
style: format code according to style guide
refactor: simplify task filtering logic
test: add tests for task completion
chore: update dependencies
```

### Testing Your Changes

Before submitting:

1. Build and run the app (⌘R)
2. Test all user interactions
3. Verify animations are smooth
4. Check both light and dark modes
5. Test with real Things data
6. Ensure no console errors

### Submitting Your Pull Request

1. Update documentation if needed
2. Ensure all tests pass
3. Push to your fork
4. Create a Pull Request

## Project Structure

```
ThingsTodayPanel/
├── ThingsTodayPanelApp.swift      # App lifecycle
├── FloatingPanelWindow.swift      # Window management
├── ContentView.swift              # Main UI
├── TaskRowView.swift              # Task components
├── Models.swift                   # Data models
├── ThingsDataService.swift        # Data layer
└── RaycastScripts/                # Integration scripts
```

## Areas Needing Contribution

- [ ] Direct Things MCP server integration
- [ ] Keyboard navigation (↑/↓ arrows)
- [ ] Custom task filters
- [ ] Widget customization
- [ ] Performance optimization
- [ ] Automated tests
- [ ] Localization

## Questions?

Feel free to open an issue for any questions about contributing!

## Recognition

Contributors will be recognized in the README.md file.

Thank you for contributing! 🎉
