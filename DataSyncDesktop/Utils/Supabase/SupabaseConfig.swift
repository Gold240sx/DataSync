//
//  SupabaseConfig.swift
//  DataSync
//
//  Created by Michael Martell on 10/1/25.
//

import Foundation

/// Configuration for Supabase connection
struct SupabaseConfig {
    static let url = ENV.supabaseUrl
    static let anonKey = ENV.supabasePublishableKey
}
