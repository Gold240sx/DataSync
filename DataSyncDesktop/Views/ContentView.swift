//
//  ContentView.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var showCopiedAlert = false
    @State private var sqlOutput = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("DataSync Schema Management")
                .font(.title)
                .padding(.top)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Generate SQL from Schema")
                    .font(.headline)
                
                Text("Click the button below to generate SQL for your schema and copy it to the clipboard.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 15) {
                    Button("Generate & Copy Complete SQL") {
                        generateAndCopySQL()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Generate & Copy Tables Only") {
                        generateAndCopyTablesSQL()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Generate & Copy RLS Policies") {
                        generateAndCopyRLSSQL()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 5)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            if !sqlOutput.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("SQL Preview")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Copy Again") {
                            copyToClipboard(sqlOutput)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    ScrollView {
                        Text(sqlOutput)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 300)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .overlay(
            showCopiedAlert ?
            VStack {
                Text("SQL copied to clipboard!")
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showCopiedAlert = false
                    }
                }
            }
            : nil
        )
    }
    
    private func generateAndCopySQL() {
        let sql = generateCompleteSupabaseSQL()
        sqlOutput = sql
        copyToClipboard(sql)
    }
    
    private func generateAndCopyTablesSQL() {
        let sql = generateAllSchemasSQL()
        sqlOutput = sql
        copyToClipboard(sql)
    }
    
    private func generateAndCopyRLSSQL() {
        let sql = generateRLSPoliciesSQL()
        sqlOutput = sql
        copyToClipboard(sql)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            showCopiedAlert = true
        }
    }
}

#Preview {
    ContentView()
}