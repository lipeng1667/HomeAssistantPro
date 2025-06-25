//
//  KeyboardDismissModifier.swift
//  HomeAssistantPro
//
//  Purpose: Adds a drag gesture to dismiss the keyboard on downward swipe.
//  Author: Michael
//  Created: 2025-06-24
//

import SwiftUI

/// Extension to UIApplication for dismissing the keyboard.
extension UIApplication {
    /// Ends editing (dismisses the keyboard) for the current key window.
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// A view modifier that adds a drag gesture to dismiss the keyboard on downward swipe.
struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height > 40 {
                            UIApplication.shared.endEditing()
                        }
                    }
            )
    }
}

extension View {
    /// Adds a drag gesture to dismiss the keyboard on downward swipe.
    func dismissKeyboardOnSwipeDown() -> some View {
        self.modifier(KeyboardDismissModifier())
    }
} 