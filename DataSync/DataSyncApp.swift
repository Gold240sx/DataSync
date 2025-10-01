//
//  DataSyncApp.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import SwiftUI

@main
struct DataSyncApp: App {
    @State private var loggedIn = false

    var body: some Scene {
        WindowGroup {
            if loggedIn {
                ContentView()
            } else {
                SupaLoginView(onLogin: {
                    loggedIn = true
                })
            }
        }
    }
}