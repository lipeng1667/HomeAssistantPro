# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HomeAssistantPro is a modern SwiftUI-based iOS application for smart home management and community engagement, featuring curated smart-home case studies, daily tips, community forums, and direct technical support.

## Development Commands

### Building and Running

- Open project: `xed .` (or open HomeAssistantPro.xcodeproj in Xcode)
- Build and run: Use Xcode's Command + R
- Clean build: Use Xcode's Command + Shift + K
- Run tests: Use Xcode's Command + U

### Code Quality Tools (Referenced but not yet configured)

- SwiftLint: `swiftlint` (requires setup)
- swift-format: `swift-format` (requires setup)

## Architecture Overview

### Core Technologies

- **Framework**: SwiftUI with iOS 15.6+ deployment target
- **Language**: Swift 5.0+
- **Architecture**: MVVM (Model-View-ViewModel) pattern
- **State Management**: ObservableObject + @Published properties
- **Testing**: Swift Testing framework (modern approach, not XCTest)

### Key Architectural Patterns

- **MVVM Structure**: ViewModels in `ViewModels/` directory handle business logic
- **Environment Objects**: Global state sharing via `AppViewModel` and `SettingsStore`
- **Navigation**: Custom tab-based navigation with `MainTabView.swift`
- **Modern SwiftUI**: Extensive use of SwiftUI 3.0+ features and declarative syntax

### Project Structure

```
HomeAssistantPro/
├── HomeAssistantProApp.swift     # App entry point
├── ViewModels/                   # MVVM business logic layer
│   ├── AppViewModel.swift        # Global app state (authentication)
│   └── SettingsStore.swift       # Onboarding and user preferences
├── Views/                        # SwiftUI views organized by feature
├── Extensions/                   # Utility extensions (ColorExtension.swift)
├── Utils/                        # Helper utilities
└── Resources/Assets.xcassets     # Images, colors, app icons
```

### Design System

The app follows a **Modern iOS 2025 Design Language** with:

- **Glassmorphism Effects**: Ultra-thin material backgrounds
- **Dynamic Gradients**: Animated color transitions with purple (`#8B5CF6`), cyan (`#06B6D4`), and green (`#10B981`) themes
- **Floating Elements**: Elevated cards and components
- **Keyboard-Responsive UI**: Uses `TabBarVisibilityManager` and `KeyboardDismissModifier`

### Application Flow

1. **Onboarding**: 3-page intro experience managed by `SettingsStore`
2. **Authentication**: Login/signup flow through `AppViewModel`
3. **Main Navigation**: 4-tab interface (Home, Forum, Chat, Settings)
4. **State Persistence**: UserDefaults for settings and onboarding state

### Testing Structure

- **Unit Tests**: `HomeAssistantProTests/` using Swift Testing framework
- **UI Tests**: `HomeAssistantProUITests/` for comprehensive UI testing
- **Important**: Uses modern Swift Testing, not XCTest

### Development Notes

- **Bundle ID**: `com.vincenx.HomeAssistantPro`
- **Deployment Target**: iOS 15.6 minimum
- **Orientation**: iPhone portrait only
- **Dependencies**: Pure SwiftUI, no external packages currently
- **Code Quality**: Comprehensive documentation headers required in all Swift files
