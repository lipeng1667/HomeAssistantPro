//
//  ImagePicker.swift
//  HomeAssistantPro
//
//  Purpose: Reusable UIImagePickerController wrapper for SwiftUI image selection
//  Author: Claude
//  Created: 2025-08-04
//  Modified: 2025-08-04
//
//  Modification Log:
//  - 2025-08-04: Extracted from CreatePostView for reusability across forum components
//
//  Functions:
//  - ImagePicker: SwiftUI wrapper for UIImagePickerController
//  - makeUIViewController: Creates and configures picker controller
//  - makeCoordinator: Creates delegate coordinator
//  - Coordinator: Handles picker delegate methods and image selection
//

import SwiftUI
import UIKit

/// UIImagePickerController wrapper for SwiftUI image selection
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    /// Creates the UIImagePickerController
    /// - Parameter context: Representable context
    /// - Returns: Configured UIImagePickerController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    /// Updates the UIImagePickerController (not used)
    /// - Parameters:
    ///   - uiViewController: The picker controller
    ///   - context: Representable context
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    /// Creates the coordinator for handling picker events
    /// - Returns: Coordinator instance
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class to handle UIImagePickerController delegate methods
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        /// Initialize coordinator with parent picker
        /// - Parameter parent: Parent ImagePicker instance
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        /// Handle image selection completion
        /// - Parameters:
        ///   - picker: The picker controller
        ///   - info: Media info dictionary
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        /// Handle picker cancellation
        /// - Parameter picker: The picker controller
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}