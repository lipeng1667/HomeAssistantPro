# HomeAssistantPro

created by Michaellee Lee on 3rd Mar 2025

**HomeAssistantPro** is an iOS application built with Swift.

## Features

- **Intro Pages**: A swipeable, three-page introduction displayed only on the first launch.
- **UserDefaults** integration to track whether the intro has been shown before.
- **Storyboard UI**: Main UI built using `Main.storyboard`.
- **Git Version Control**: Project tracked with Git (integrated through Xcode’s “Integrate” menu).

## Getting Started

### Prerequisites

- **Xcode** 14 (or newer)
- **iOS** deployment target: iOS 16+ (adjust in the project settings if needed)
- **Swift** 5 or higher

### Installation

1. **Clone or Download the Repository**

   ```bash
   git clone https://github.com/lipeng1667/HomeAssistantPro.git
   cd HomeAssistantPro

2. Open the Project in Xcode
 • Double-click HomeAssistantPro.xcodeproj (or open it via File → Open in Xcode).
3. Install/Check Dependencies
 • Ensure you have Command Line Tools installed and selected in Xcode (Xcode → Preferences → Locations → Command Line Tools).
 • If there are any external dependencies (e.g., via Swift Package Manager or CocoaPods), install them now.
4. Build & Run
 • Choose an iOS Simulator or a connected iPhone device in Xcode.
 • Press Command + R or click the Run button in the toolbar to build and launch.

Project Structure

```
HomeAssistantPro
├── HomeAssistantPro
│   ├── AppDelegate.swift               # App lifecycle
│   ├── SceneDelegate.swift             # Scene management (for iOS 13+)
│   ├── Info.plist                      # App configuration
│   ├── Models/                         # (Optional) data models
│   ├── Resources/
│   │   ├── Assets.xcassets             # Image assets
│   │   └── LaunchScreen.storyboard     # Launch screen storyboard
│   ├── Utils/                          # (Optional) utility/helper files
│   ├── ViewControllers/
│   │   ├── ViewController.swift        # Main view controller
│   │   └── IntroViewController.swift   # A basic intro view controller (if used)
│   ├── Views/
│   │   └── IntroViewController.xib     # .xib layout for the intro (if needed)
│   ├── Main.storyboard                 # Main UI storyboard
│   └── IntroPageViewController.swift   # UIPageViewController subclass
├── HomeAssistantProTests/              # Unit tests
└── HomeAssistantProUITests/            # UI tests
```

Usage

 1. Launching the App
 • If it’s the user’s first time opening the app, a 3-page intro is shown via IntroPageViewController.
 • After the intro, or on subsequent launches, the main view (ViewController.swift) is displayed.
 2. Navigating the Intro
 • Swipe between pages to see different images and text.
 • Optionally provide a Skip or Finish button to allow users to exit the intro at any time.
 3. Main App Content
 • Once the intro is dismissed, the user sees the main app interface, which can be customized in ViewController.swift or additional view controllers.

Contributing

Contributions, bug reports, and feature requests are welcome!
Feel free to open issues and submit pull requests on GitHub.

License

This project is provided under the MIT License.
Please see the LICENSE.md file for full details.
