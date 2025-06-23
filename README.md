# HomeAssistantPro

Created by Michael Lee on March 3, 2025.

**HomeAssistantPro** is a SwiftUI-based iOS application for managing and exploring high-end smart-home solutions. It combines curated case studies, daily tips, community discussion, direct support, and account management into one seamless experience.

## Overview

HomeAssistantPro delivers:

- Curated showcases of real-world smart-home installations.
- Bite-sized daily tips for smarter living.
- A community forum for discussion.
- One-on-one chat support with our tech team.
- Flexible authentication: register via phone/email or explore anonymously.

## Features

- **Intro Pages**: A three-page swipeable introduction on first launch.
- **UserDefaults**: Tracks whether the intro has been shown.
- **Tab-Based Navigation**: Home, Forum, Chat, Settings.
- **Authentication**: Phone/email sign-up or anonymous mode.
- **SwiftUI** & **MVVM**: Modern architecture with async/await networking.
- **Unit & UI Tests**: XCTest and SnapshotTesting coverage.
- **SwiftLint & swift-format**: Code style and linting enforced automatically.

## Getting Started

### Prerequisites

- Xcode 17 (or newer)
- iOS 18.0+ deployment target
- Swift 5.10+

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/<your-org>/HomeAssistantPro.git
   cd HomeAssistantPro
   ```

2. Open the project:

   ```bash
   xed .
   ```

3. Resolve dependencies:
   - Swift Package Manager will auto-fetch required packages.
4. Build & Run:
   - Select your target simulator or device.
   - Press **Command + R** in Xcode.

### Project Structure

```
HomeAssistantPro
├── HomeAssistantPro
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Info.plist
│   ├── Models/
│   ├── ViewControllers/
│   │   ├── IntroPageViewController.swift
│   │   └── ViewController.swift
│   ├── Views/
│   ├── Utils/
│   ├── Resources/
│   └── Supporting Files/
├── HomeAssistantProTests/
└── HomeAssistantProUITests/
```

## Usage

1. **Launching the App**  
   - On first launch, a three-page intro (`IntroPageViewController`) is shown.  
   - On subsequent launches, or after the intro, the authentication screen is displayed.

2. **Navigating the Intro**  
   - Swipe between pages to view imagery and captions.  
   - A **Skip** or **Finish** button allows exiting the intro at any time.

3. **Authentication**  
   - Choose to sign up or log in using your phone number or email, or enter Anonymous Mode to explore the app without registering.
   - Registration includes verification by code or email link.
   - Anonymous users can register later at any time from the **Settings** tab.

4. **Main App Content**  
   - Once logged in (or in anonymous mode), users enter the main interface, featuring four core tabs:
     - **Home:** Discover curated smart-home cases (with images/videos) and daily tips.
     - **Forum:** Engage with the community by browsing, posting, and commenting on user threads.
     - **Chat:** Access direct 1-on-1 messaging with the technical support team for help or questions.
     - **Settings:** Manage account, edit your profile/avatar, switch between anonymous and registered modes, and adjust app preferences.

## Tech Stack

- Swift 5.10, SwiftUI, MVVM + Clean-DI
- Async/Await networking with `URLSession` & `Codable`
- Swift Package Manager for dependencies
- SwiftLint (strict) & swift-format (Google style)
- XCTest & SnapshotTesting for tests
- os.Logger for unified logging

## Contributing

Contributions are welcome! To contribute:

1. Fork the repo and create a feature branch: `git checkout -b feat/your-feature`
2. Commit your changes and push to your fork.
3. Open a pull request describing your changes.
4. Ensure all tests pass and linting errors are resolved.

## License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
