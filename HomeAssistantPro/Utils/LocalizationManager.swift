//
//  LocalizationManager.swift
//  HomeAssistantPro
//
//  Created: June 26, 2025
//  Last Modified: June 26, 2025
//  Author: Michael Lee
//  Version: 1.0.0
//
//  Purpose: Manages app localization with support for English and Chinese
//  languages. Provides dynamic language switching with persistent storage
//  and reactive updates across the app.
//
//  Update History:
//  v1.0.0 (June 26, 2025) - Initial creation with English/Chinese support
//
//  Features:
//  - Dynamic language switching without app restart
//  - Persistent language preference storage
//  - Reactive updates using Combine framework
//  - Support for English (en) and Chinese Simplified (zh-Hans)
//  - Fallback to system language preference
//

import SwiftUI
import Combine

/// Supported languages in the app
enum Language: String, CaseIterable {
    case english = "en"
    case chinese = "zh-Hans"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chinese:
            return "中文"
        }
    }
    
    var nativeName: String {
        switch self {
        case .english:
            return "English"
        case .chinese:
            return "简体中文"
        }
    }
    
    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .chinese:
            return "🇨🇳"
        }
    }
}

/// Manages localization and language switching for the app
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: UserDefaultsKeys.selectedLanguage)
            updateBundle()
        }
    }
    
    private var bundle: Bundle = Bundle.main
    
    private struct UserDefaultsKeys {
        static let selectedLanguage = "SelectedLanguage"
    }
    
    private init() {
        // Load saved language or default to system preference
        let savedLanguage = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedLanguage)
        
        if let savedLanguage = savedLanguage,
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default to system language if supported, otherwise English
            let systemLanguage = Locale.current.languageCode ?? "en"
            self.currentLanguage = Language(rawValue: systemLanguage) ?? .english
        }
        
        updateBundle()
    }
    
    /// Updates the bundle for the current language
    private func updateBundle() {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            self.bundle = Bundle.main
            return
        }
        self.bundle = bundle
    }
    
    /// Returns localized string for the given key
    func localizedString(for key: String) -> String {
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
    
    /// Changes the app language
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }
    
    /// Returns whether the current language is right-to-left
    var isRTL: Bool {
        return currentLanguage == .chinese ? false : false // Neither English nor Chinese are RTL
    }
}

/// String extension for easy localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

/// Localized string keys for type safety
enum LocalizedKeys {
    
    // MARK: - Tab Titles
    static let tabHome = "tab.home"
    static let tabForum = "tab.forum"
    static let tabChat = "tab.chat"
    static let tabSettings = "tab.settings"
    
    // MARK: - Home View
    static let homeFeaturedCase = "home.featured_case"
    static let homeTrendingDesign = "home.trending_design"
    static let homeSmartHomeDesign = "home.smart_home_design"
    static let homeSmartHomeDescription = "home.smart_home_description"
    static let homeDailyTips = "home.daily_tips"
    static let homeSmartLivingAdvice = "home.smart_living_advice"
    static let homeMoreButton = "home.more_button"
    static let homeEnergySaving = "home.energy_saving"
    static let homeTurnOffLights = "home.turn_off_lights"
    static let homeLightTipDescription = "home.light_tip_description"
    
    // MARK: - Forum View
    static let forumCommunity = "forum.community"
    static let forumTitle = "forum.title"
    static let forumSearchPlaceholder = "forum.search_placeholder"
    static let forumCreatePost = "forum.create_post"
    static let forumNewPostTitle = "forum.new_post_title"
    static let forumNewPostDescription = "forum.new_post_description"
    static let forumCategory = "forum.category"
    static let forumTitle2 = "forum.title2"
    static let forumContent = "forum.content"
    static let forumTitlePlaceholder = "forum.title_placeholder"
    static let forumContentPlaceholder = "forum.content_placeholder"
    static let forumCancel = "forum.cancel"
    static let forumPost = "forum.post"
    
    // MARK: - Chat View
    static let chatSupport = "chat.support"
    static let chatTitle = "chat.title"
    static let chatSupportAgent = "chat.support_agent"
    static let chatTypePlaceholder = "chat.type_placeholder"
    
    // MARK: - Settings View
    static let settingsTitle = "settings.title"
    static let settingsProfile = "settings.profile"
    static let settingsPreferences = "settings.preferences"
    static let settingsLanguage = "settings.language"
    static let settingsLanguageDescription = "settings.language_description"
    static let settingsColorTheme = "settings.color_theme"
    static let settingsColorDescription = "settings.color_description"
    static let settingsSupport = "settings.support"
    static let settingsHelpCenter = "settings.help_center"
    static let settingsContactUs = "settings.contact_us"
    static let settingsFeedback = "settings.feedback"
    static let settingsAbout = "settings.about"
    static let settingsVersion = "settings.version"
    static let settingsTerms = "settings.terms"
    static let settingsPrivacy = "settings.privacy"
    
    // MARK: - Common
    static let commonSave = "common.save"
    static let commonCancel = "common.cancel"
    static let commonDone = "common.done"
    static let commonNext = "common.next"
    static let commonBack = "common.back"
    static let commonClose = "common.close"
    static let commonEdit = "common.edit"
    static let commonDelete = "common.delete"
    static let commonShare = "common.share"
    static let commonSettings = "common.settings"
    
    // MARK: - Login View
    static let loginWelcome = "login.welcome"
    static let loginSubtitle = "login.subtitle"
    static let loginPhone = "login.phone"
    static let loginEmail = "login.email"
    static let loginAnonymous = "login.anonymous"
    static let loginPhoneDescription = "login.phone_description"
    static let loginEmailDescription = "login.email_description"
    static let loginAnonymousDescription = "login.anonymous_description"
}