//
//  ProfilePhotoPickerView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import SwiftUI
import PhotosUI

/// Photo picker for child profile photo
struct ProfilePhotoPickerView: View {
    @Binding var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showImagePicker = false

    var body: some View {
        VStack(spacing: 12) {
            // Photo display
            if let photoData = photoData,
               let uiImage = UIImage(data: photoData) {
                // Show selected photo
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                    )
                    .accessibilityLabel("Profile photo")
            } else {
                // Placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
                    .accessibilityLabel("No photo selected")
            }

            // Photo picker button
            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {
                Label(
                    photoData == nil ? "Add Photo" : "Change Photo",
                    systemImage: photoData == nil ? "camera.fill" : "arrow.triangle.2.circlepath"
                )
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .accessibilityLabel(photoData == nil ? "Add profile photo" : "Change profile photo")
            .accessibilityHint("Optional. Select a photo from your photo library")

            if photoData != nil {
                Button(role: .destructive) {
                    withAnimation {
                        photoData = nil
                        selectedItem = nil
                    }
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .accessibilityLabel("Remove photo")
            }
        }
    }
}

// MARK: - Preview

struct ProfilePhotoPickerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            ProfilePhotoPickerView(photoData: .constant(nil))
                .previewDisplayName("No Photo")

            ProfilePhotoPickerView(photoData: .constant(Data()))
                .previewDisplayName("With Photo")
        }
        .padding()
    }
}
