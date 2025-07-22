# HomeAssistantPro

**Created:** March 3, 2025  
**Last Updated:** July 21, 2025  
**Version:** 2.2.0  
**iOS Target:** 16.0+  
**Xcode:** 17+  
**Swift:** 5.10  

**HomeAssistantPro** is a modern SwiftUI-based iOS application designed for smart home enthusiasts. Built with MVVM + Clean-DI architecture and 2025 iOS design principles, it features glassmorphism effects, responsive design, comprehensive design system, and real-time communication capabilities.

## 🌟 Features

### Core Functionality

- **🏠 Home Dashboard**: Curated smart home case studies with demo video player
- **💬 Community Forum**: Discussion platform with hot topics, categories, and post creation/editing
- **🔧 Tech Support Chat**: Real-time WebSocket chat with typing indicators and message management
- **⚙️ Settings Hub**: Profile management, theme switching, and app preferences
- **✨ Splash Screen**: Modern glassmorphism launch screen with floating animations
- **🎯 Intro Experience**: Beautiful onboarding flow for new users
- **🔐 Authentication**: Anonymous/registered login with persistent session management

### Design & UX

- **🌙 Dark Mode**: Automatic light/dark theme switching with adaptive colors
- **📱 Responsive Design**: Device-adaptive layouts for compact/regular/large screen sizes
- **✨ Glassmorphism**: Modern iOS design aesthetics with blur effects
- **🎨 Design System**: Centralized DesignTokens.swift for colors, spacing, typography
- **⚡ Smooth Animations**: Fluid spring transitions with haptic feedback integration
- **🎪 Floating Elements**: Dynamic orbs and animated gradient backgrounds
- **♿ Accessibility**: VoiceOver support and Dynamic Type scaling

### Technical Excellence

- **🏗️ MVVM + Clean-DI**: Architecture with dependency injection using @Environment
- **🔧 Modular Components**: Reusable UI components with standardized styling
- **📐 Responsive Layouts**: Three-tier device size system (compact/regular/large)
- **🎯 Type Safety**: Comprehensive Swift 5.10 type system with async/await
- **🌐 Network Layer**: URLSession-based API client with HMAC-SHA256 authentication
- **🔒 Security**: Keychain-based device identification and UserDefaults caching
- **⚡ Performance**: BackgroundDataPreloader with CacheManager for optimized loading
- **🔌 Real-time**: WebSocket integration with SocketIO for live chat features

## 🚀 Quick Start

### Prerequisites

```text
- Xcode 17+
- iOS 16.0+ deployment target
- Swift 5.10+
- macOS Sonoma 14.0+
- Swift Package Manager (SPM)
```

### Installation

```bash
# Clone the repository
git clone https://github.com/lipeng1667/HomeAssistantPro.git
cd HomeAssistantPro

# Open in Xcode
open HomeAssistantPro.xcodeproj

# Build and run (⌘+R)
```

## 📁 Architecture Overview

### Project Structure

```text
HomeAssistantPro/
├── HomeAssistantProApp.swift            # App entry point with splash screen logic
├── 🧠 ViewModels/
│   ├── AppViewModel.swift               # Global app state & authentication
│   ├── AnonymousRestrictionViewModel.swift # Anonymous user access management
│   └── ImageViewerModal.swift           # Image viewing modal state
├── 🛠️ Utils/
│   ├── DesignTokens.swift               # Complete design system (colors, spacing, typography)
│   ├── AnimationPresets.swift           # Consistent spring animations
│   ├── HapticManager.swift              # Haptic feedback patterns
│   ├── SharedButtonStyles.swift         # Unified button behaviors
│   ├── KeyboardDismissModifier.swift    # Keyboard handling utilities
│   ├── LocalizationManager.swift       # Multi-language support
│   ├── DateUtils.swift                  # Date formatting utilities
│   └── PhoneNumberUtils.swift           # Phone number validation
├── 🖥️ Views/
│   ├── SplashView.swift                 # Glassmorphism splash with floating orbs
│   ├── Components/
│   │   ├── MainTabView.swift            # Tab navigation controller
│   │   ├── StandardTabHeader.swift      # Unified headers with glassmorphism
│   │   ├── StandardTabBackground.swift  # Animated gradient backgrounds
│   │   ├── GlassmorphismCard.swift      # Glass effect cards
│   │   ├── CustomConfirmationModal.swift # Configurable confirmation modals
│   │   └── ReviewStatusBadge.swift      # Post status indicators
│   ├── HomeView.swift                   # Home dashboard with video player
│   ├── Forum/
│   │   ├── ForumView.swift              # Community forum with categories
│   │   ├── TopicDetailView.swift        # Forum topic details with replies
│   │   ├── CreatePostView.swift         # Post creation interface
│   │   └── EditReplyView.swift          # Reply editing interface
│   ├── ChatView.swift                   # Real-time WebSocket chat
│   ├── SettingsView.swift               # Settings & profile management
│   ├── Login/
│   │   ├── AuthenticationView.swift     # Main auth flow controller
│   │   ├── LoginView.swift              # Login interface
│   │   └── RegisterView.swift           # Registration interface
│   └── IntroView.swift                  # Onboarding flow
├── 🌐 Services/
│   ├── APIClient.swift                  # HMAC authenticated HTTP client
│   ├── ForumService.swift               # Forum API integration
│   ├── IMService.swift                  # Chat messaging service
│   ├── SocketManager.swift              # WebSocket connection manager
│   ├── SettingsStore.swift              # UserDefaults + Keychain wrapper
│   ├── BackgroundDataPreloader.swift    # Performance optimization service
│   └── CacheManager.swift               # Memory caching system
├── 📦 Models/
│   ├── AuthModels.swift                 # Authentication request/response models
│   ├── ForumModels.swift                # Forum post and topic models
│   ├── IMModels.swift                   # Chat message models
│   └── LocalVideoAssets.swift           # Video player models
├── 🎬 Components/
│   └── VideoPlayer/
│       ├── VideoPlayerView.swift        # Main video player component
│       ├── LocalVideoPlayer.swift       # Local video playback
│       └── FullscreenVideoModal.swift   # Fullscreen video modal
├── 🏛️ Legacy/
│   └── AppDelegate.swift                # Legacy app delegate
└── 🧪 Tests/
    ├── HomeAssistantProTests/           # Unit tests
    ├── SettingsStoreTests.swift         # Settings store test suite
    └── HomeAssistantProUITests/         # UI tests
```

### Design System Architecture

#### 🎨 DesignTokens.swift

The foundation of our design system providing:

- **Adaptive Colors**: Automatic light/dark mode switching with brand colors
- **Responsive Spacing**: Three-tier device system (compact/regular/large)
- **Typography Scale**: Device-aware font sizing with responsive scaling
- **Shadow Presets**: Elevation system with adaptive opacity
- **Device Detection**: Screen size categorization and responsive utilities

#### 🧩 Component System

- **StandardTabHeader**: Unified header with glassmorphism background
- **StandardTabBackground**: Animated gradient backgrounds with floating orbs
- **GlassmorphismCard**: Material design cards with blur effects
- **CustomConfirmationModal**: Themed confirmation dialogs (.destructive/.primary/.success)
- **ReviewStatusBadge**: Post status indicators with color coding
- **VideoPlayerView**: Full-featured video player with fullscreen support

## 🎨 Design System

### Color Palette

```swift
// Brand Colors
primaryPurple   #8B5CF6  // Home tab, primary actions
primaryCyan     #06B6D4  // Forum tab, secondary actions  
primaryGreen    #10B981  // Chat tab, success states
primaryAmber    #F59E0B  // Settings tab, warning states

// Adaptive Backgrounds (Light → Dark)
backgroundPrimary    #FAFAFA → #0F0F0F
backgroundSecondary  #F8FAFC → #1A1A1A
backgroundTertiary   #F4F4F5 → #262626
```

### Responsive Spacing System

```swift
Device Categories:
- Compact (<385pt width): iPhone SE, mini series - base spacing
- Regular (385-415pt width): iPhone standard models - enhanced spacing  
- Large (>415pt width): iPhone Plus/Pro Max - maximum spacing

Responsive Spacing Examples:
- contentMargins(): 16pt → 20pt → 24pt
- responsivePadding(): 12pt → 16pt → 20pt
- Section spacing: 24pt → 28pt → 32pt
```

### Typography Scale

```swift
// DesignTokens.ResponsiveTypography
headingLarge:   28pt → 32pt → 36pt
headingMedium:  24pt → 26pt → 28pt
bodyLarge:      18pt → 19pt → 20pt
bodyMedium:     16pt → 17pt → 18pt
bodySmall:      14pt → 15pt → 16pt
caption:        12pt → 13pt → 14pt
```

## 🔧 Development

### Dependencies

```swift
// Package.swift - Swift Package Manager
dependencies: [
    .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0")
]
```

### Building

```bash
# Debug build
xcodebuild -project HomeAssistantPro.xcodeproj -scheme HomeAssistantPro -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Release build  
xcodebuild -project HomeAssistantPro.xcodeproj -scheme HomeAssistantPro -configuration Release -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### Testing

```bash
# Run unit tests
xcodebuild test -project HomeAssistantPro.xcodeproj -scheme HomeAssistantPro -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run UI tests
xcodebuild test -project HomeAssistantPro.xcodeproj -scheme HomeAssistantProUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Code Quality Standards

- **SwiftLint**: Enforced strict code style and best practices
- **swift-format**: Auto-formatting with Google style guidelines
- **Type Safety**: Comprehensive Swift 5.10 type system usage
- **MVVM + Clean-DI**: Clear separation with dependency injection
- **Async/Await**: Structured concurrency, no Combine usage
- **os.Logger**: Unified logging with subsystem tagging

## 🔐 Authentication & Network Architecture

### Security Implementation

- **Device Identification**: UUID-based device ID stored securely in iOS Keychain
- **HMAC Authentication**: SHA-256 signature validation for all API requests  
- **Session Management**: UserDefaults for state, Keychain for sensitive data
- **Anonymous + Registered**: Dual authentication modes with permission restrictions

### API Integration & Services

```swift
// Service Architecture
APIClient (HMAC Auth) → ForumService/IMService → ViewModels → SwiftUI Views
                     ↳ SocketManager (WebSocket) → Real-time Chat
```

### Network Layer Services

- **APIClient**: URLSession-based HTTP client with HMAC-SHA256 authentication
- **ForumService**: Forum posts, topics, replies API integration
- **IMService**: Chat messaging service with real-time capabilities  
- **SocketManager**: WebSocket connection management using SocketIO
- **BackgroundDataPreloader**: Performance optimization with CacheManager

### Session & Cache Management

- **SettingsStore**: UserDefaults + Keychain wrapper for user data
- **CacheManager**: Memory-based caching with 30-minute expiration
- **Automatic Restoration**: Persistent login state across app launches
- **Permission System**: Anonymous users have view-only access restrictions

## 📱 Device Support & Compatibility

### Supported Device Categories

```swift
// DesignTokens.DeviceSize detection
.compact: <385pt width  (iPhone SE, mini series)
.regular: 385-415pt     (iPhone 12-15 standard)  
.large:   >415pt width  (iPhone Plus/Pro Max series)
```

### iOS Compatibility

- **iOS 16.0+**: Minimum deployment target (updated from 15.6+)
- **iOS 18.0+**: Recommended for optimal performance
- **Swift 5.10**: Latest language features and concurrency
- **SwiftUI**: Native UI framework with backward compatibility

### Accessibility & Responsive Design

- **Dark Mode**: Automatic system theme detection with adaptive colors
- **Dynamic Type**: Font scaling support for accessibility
- **VoiceOver**: Screen reader compatibility
- **Responsive Layouts**: Auto-adapting to screen sizes and orientations

## 🎯 Technical Achievements

### Architecture & Performance

- **MVVM + Clean-DI**: Structured architecture with dependency injection
- **Centralized Design System**: DesignTokens.swift eliminates styling inconsistencies  
- **Background Preloading**: 3-second splash screen preloads forum data
- **Memory Caching**: CacheManager reduces redundant API calls
- **Responsive Design**: Automatic adaptation across device sizes

### User Experience Excellence

- **Seamless Authentication**: Anonymous and registered modes with session persistence
- **Real-time Communication**: WebSocket-powered chat with typing indicators
- **Glassmorphism UI**: Modern iOS design with blur effects and floating animations
- **Accessibility First**: VoiceOver, Dynamic Type, and responsive layouts
- **Haptic Integration**: Consistent tactile feedback throughout the app

## 🚀 Version History

### v2.2.0 (Current - July 21, 2025)

- **🔌 WebSocket Integration**: Real-time chat with SocketIO and typing indicators
- **📹 Video Player**: Full-featured video player with fullscreen modal support
- **🎨 Enhanced Components**: ReviewStatusBadge and improved forum interfaces
- **📱 Chat System**: Complete instant messaging with message management
- **⚡ Performance**: BackgroundDataPreloader with CacheManager optimization

### v2.1.0 (July 4, 2025)

- **🌐 Network Integration**: Complete API authentication with backend server
- **🔐 Dual Authentication**: Anonymous and registered login modes
- **🔒 Security**: HMAC-SHA256 authenticated requests with device identification
- **💾 Session Persistence**: Automatic login state restoration via SettingsStore
- **🎨 Confirmation System**: CustomConfirmationModal with themed variants

### v2.0.0 (June 26, 2025)

- **✨ Design System**: Complete DesignTokens.swift implementation
- **🌙 Dark Mode**: Adaptive color system with light/dark switching
- **📱 Responsive Design**: Three-tier device size system (compact/regular/large)
- **🎪 Glassmorphism**: Modern UI with blur effects and floating animations
- **🏗️ Architecture**: MVVM + Clean-DI with dependency injection

### v1.0.0 (March 3, 2025)

- **🏗️ Foundation**: Initial MVVM architecture setup
- **🎬 Onboarding**: Complete intro flow and authentication system
- **📱 Navigation**: Four-tab app structure with SwiftUI
- **🔐 Authentication**: Basic login and anonymous mode implementation

## 📄 License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.

## 👨‍💻 Author

**Michael Lee**  

- Created: March 3, 2025
- Architecture: MVVM + SwiftUI
- Design: Modern iOS 2025 aesthetics

---
