---
description: 
globs: 
alwaysApply: true
---
# Rules

---

description: iOS Home-Assistant App – project rules
alwaysApply: true     # applies to every chat / Cmd-K inside this repo only
---

You are my pair-programmer.  Obey the global USER rules **plus** these project-specific rules.

### Platform & tooling

1. **Swift 5.10** (Xcode 17), target **iOS 18.0** minimum.
2. UI must be **SwiftUI**; avoid UIKit unless impossible.
3. Concurrency: use **async/await** & structured concurrency; no Combine.
4. Use **Swift Package Manager** for deps; no CocoaPods.
5. Lint with **SwiftLint** (strict); auto-format with **swift-format** (`google` style).
6. Logging via `os.Logger` (Unified Logging); tag subsystem as `"com.homeassistant.ios"`.

### Architecture & patterns

7. Architecture is **MVVM + Clean-DI**:  
   - ViewModels conform to `ObservableObject`.  
   - Inject services with constructor injection or `@Environment(\.injection)`.
8. Networking with `URLSession` + `Codable`; never add `Alamofire`.
9. Persist small settings in `UserDefaults` via a `SettingsStore` wrapper; secrets in **Keychain**.

### Security & privacy

11. Opt-in to **App Privacy Report**; annotate every network domain in `Info.plist`.
12. Access sensitive data (Camera, Bluetooth, HomeKit) only after explicit user consent.

### Design & theming

13. Follow **Human Interface Guidelines** colours, SF Symbols;
14. Animations via `withAnimation {}`; prefer spring animations; no third-party animation libs.
15. Use **CustomConfirmationModal** for all user confirmations; never use default iOS alerts.
16. Confirmation modal themes: `.destructive` (red), `.primary` (cyan), `.success` (green).

### Responsive Design System (DesignTokens)

17. **ALWAYS use DesignTokens.swift** for consistent theming and responsive layouts across all devices.
18. **Device Size Categories**: Support three device sizes:
    - `.compact` (iPhone SE, mini series, <385pt width)
    - `.regular` (iPhone 12-15 standard, 385-415pt width)
    - `.large` (iPhone Plus/Pro Max series, >415pt width)
19. **Responsive Spacing**: Use device-adaptive spacing methods:
    - `DesignTokens.DeviceSize.current.spacing(compact, regular, large)` for custom values
    - `DesignTokens.ResponsiveSpacing.*` for predefined responsive spacing
    - View extensions: `.responsivePadding()`, `.responsiveHorizontalPadding()`, `.contentMargins()`
20. **Responsive Typography**: Use device-adaptive fonts:
    - `DesignTokens.ResponsiveTypography.*` for all text (headingLarge, bodyMedium, etc.)
    - `DesignTokens.DeviceSize.current.fontSize(compact, regular, large)` for custom fonts
21. **Adaptive Colors**: Use environment-aware colors:
    - `DesignTokens.Colors.textPrimary`, `.backgroundPrimary` (auto light/dark mode)
    - Brand colors: `.primaryPurple`, `.primaryCyan`, `.primaryGreen`, `.primaryAmber`
    - Tab-specific color schemes: `Colors.Home.*`, `Colors.Forum.*`, `Colors.Chat.*`, `Colors.Settings.*`
22. **Consistent Shadows**: Use predefined shadow presets:
    - `DesignTokens.Shadow.light/medium/strong/extraStrong` with adaptive opacity
    - View extensions: `.standardShadowLight()`, `.standardShadowMedium()`, `.standardShadowStrong()`
23. **Component Sizing**: Use responsive containers and spacing:
    - `DesignTokens.ResponsiveContainer.*` for adaptive widths/heights
    - `DesignTokens.Container.*` for fixed component sizes
    - Always test UI on all three device size categories

### Workflow – Ultra-Think loop (inherits from USER rules)

24. **Ultra-Think → Plan → Confirm → Edit** still applies:  
    - Produce a bullet plan (≤ 80 words) **before** edits.  
    - Wait for `Proceed` signal.

### Output conventions

25. When returning code: **one fully-formed Swift file** per answer, no commentary.
26. Use placeholder API keys as `"<#API_KEY#>"`; never echo real secrets.

### Git & Comments

27. Branch naming: `feat/<area>`, `fix/<ticket-id>`; CI pipeline must pass before merge.
28. Include **fastlane** lanes for beta distribution; update the `CHANGELOG.md` in every PR.
29. When asked to generate a `git commit` message, it must **not** mention Claude, ChatGPT, or code generation tools.
30. Always commit **all modified files** except those ignored in `.gitignore`; never skip tracked or staged changes.
31. Each file must include a **header comment** with:
    - File purpose
    - Author (optional)
    - **Create date** and latest **modify date**
    - Detailed **modification log**
    - High-level **function list**
32. Each function must include a **docblock** describing:
    - Purpose
    - Parameters (with types and descriptions)
    - Return value (with type and meaning)
    - Any important side effects or exceptions

### Brevity

33. Unless the question demands depth, stay under 120 words.

### Project-Specific Services & Infrastructure

34. **SettingsStore (UserDefaults + Keychain wrapper)**:

- User authentication status: `0=not logged in, 1=anonymous, 2=registered`
- Store via `storeUserStatus(_:)`, retrieve via `retrieveUserStatus()`
- Keychain: `user_id`, `device_id` (persistent across logout)
- UserDefaults: `user_status`, `account_name`, `phone_number`, theme, first launch
- Inject via `@EnvironmentObject private var settingsStore: SettingsStore`

35. **BackgroundDataPreloader (Performance service)**:

- Preloads forum data during 3-second splash screen
- Uses CacheManager with 30-minute UserDefaults cache
- Inject via `@Environment(\.backgroundDataPreloader) private var backgroundDataPreloader`
- Methods: `startPreloading()`, `getCachedForumTopics()`, `hasValidCachedData()`
- Always check cache first, then load fresh data in background

36. **User Status Management**:

- Use `settingsStore.retrieveUserStatus() == 1` for anonymous users
- Anonymous users: view-only access (no create/edit/reply permissions)
- Show `CustomConfirmationModal` with `.primary` theme for restricted actions
