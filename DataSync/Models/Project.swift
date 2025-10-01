//
//  Item.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation
import SwiftData

// encorporate offline access syncing with supabase and cloudkit. keep this project as simple as possible.

@Model
final class Project {
    var id: String
    var logo: Data?
    var logo_url: String
    var project_name: String
    var project_description: String
    var created_at: Date
    var updated_at: Date?

    init(
        logo: Data? = nil,
        logo_url: String = "",
        project_name: String = "New Project",
        project_description: String = "",
        updated_at: Date? = nil
    ) {
        self.id = UUID().uuidString
        self.logo = logo
        self.logo_url = logo_url
        self.project_name = project_name
        self.project_description = project_description
        self.created_at = Date()
        self.updated_at = updated_at
    }
}