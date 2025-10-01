//
//  NewProjectForm.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation
import SwiftUI
import SwiftData
import AppKit

struct NewProjectForm: View {
    @State private var project_name: String = ""
    @State private var project_description: String = ""
    @State private var created_at: Date = Date()
    @State private var updated_at: Date?
    @State private var logoData: Data?
    @State private var logoImage: NSImage?

    var body: some View {
        Form {
            Section {
                TextField("Project Name", text: $project_name)
                TextField("Project Description", text: $project_description)
                DatePicker("Created At", selection: $created_at, displayedComponents: .date)
                if #available(macOS 13.0, *) {
                    DatePicker("Updated At", selection: Binding($updated_at, replacingNilWith: Date()), displayedComponents: .date)
                }
                Button(action: {
                    pickLogo()
                }) {
                    if let logoImage {
                        Image(nsImage: logoImage)
                            .resizable()
                            .frame(width: 100, height: 100)
                    } else {
                        Text("Select Logo")
                    }
                }
            }.padding(10)
            
            Section {
                Button(action: {
                    let newProject = Project(
                        logo: logoData,
                        logo_url: "",
                        project_name: project_name,
                        project_description: project_description,
                        updated_at: updated_at
                    )
                    // Save the new project to the database here, using your model context
                    print("New Project Created: \(newProject)")
                }) {
                    Text("Save Project")
                }
            }
        }
    }
    
    private func pickLogo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .gif, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url), let data = try? Data(contentsOf: url) {
                logoImage = image
                logoData = data
            }
        }
    }
}

// Helper to bind optional date for backwards compatibility
extension Binding {
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}
