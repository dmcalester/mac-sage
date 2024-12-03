//
//  SettingsView.swift
//  macSage
//
//  Created by Duncan McAlester on 12/3/24.
//

// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("username") private var username: String = ""
    @AppStorage("apiKey") private var apiKey: String = ""
    @Environment(\.presentationMode) var presentationMode

    var onSave: (() -> Void)?
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.headline)
                .padding()

            TextField("Email", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save") {
                // Dismiss the settings view
                presentationMode.wrappedValue.dismiss()
                // Notify parent about the update
                onSave?()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
        .padding()
    }
}

#Preview {
    SettingsView()
}
