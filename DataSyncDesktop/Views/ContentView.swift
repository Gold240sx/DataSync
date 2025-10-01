//
//  ContentView.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import SwiftUI
import AppKit

// TextEditor wrapped in a SwiftUI View for selectable text
struct SelectableTextEditor: View {
    @Binding var text: String
    var onSelectionChange: ((String) -> Void)?
    
    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .onChange(of: NSPasteboard.general.string(forType: .string)) { _, newValue in
                if let selectedText = newValue {
                    onSelectionChange?(selectedText)
                }
            }
            .onHover { _ in
                // This enables text selection in the TextEditor
                NSCursor.iBeam.set()
            }
    }
}

struct ContentView: View {
    @State private var showCopiedAlert = false
    @State private var copiedMessage = "SQL copied to clipboard!"
    @State private var sqlOutput = ""
    @State private var selectedText: String?
    
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
                        
                        Button("Copy All") {
                            copyToClipboard(sqlOutput, message: "All SQL copied to clipboard!")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    // Simple TextEditor with selection enabled
                    ScrollView {
                        TextEditor(text: $sqlOutput)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 300)
                            .textSelection(.enabled)
                            .scrollContentBackground(.hidden)
                            .background(Color(NSColor.textBackgroundColor))
                    }
                    .frame(height: 300)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Instructions for text selection
                    HStack {
                        Text("Tip: Select text to copy specific parts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Copy Selected Text") {
                            if let selectedText = getSelectedText() {
                                copyToClipboard(selectedText, message: "Selection copied to clipboard!")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(getSelectedText() == nil)
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 700, minHeight: 550)
        .overlay(
            showCopiedAlert ?
            VStack {
                Text(copiedMessage)
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
        copyToClipboard(sql, message: "Complete SQL copied to clipboard!")
    }
    
    private func generateAndCopyTablesSQL() {
        let sql = generateAllSchemasSQL()
        sqlOutput = sql
        copyToClipboard(sql, message: "Tables SQL copied to clipboard!")
    }
    
    private func generateAndCopyRLSSQL() {
        let sql = generateRLSPoliciesSQL()
        sqlOutput = sql
        copyToClipboard(sql, message: "RLS Policies copied to clipboard!")
    }
    
    private func copyToClipboard(_ text: String, message: String = "SQL copied to clipboard!") {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        copiedMessage = message
        withAnimation {
            showCopiedAlert = true
        }
    }
    
    private func getSelectedText() -> String? {
        // Get the current first responder
        guard let window = NSApp.mainWindow,
              let fieldEditor = window.fieldEditor(false, for: nil),
              let selectedRange = fieldEditor.selectedRanges.first as? NSRange,
              selectedRange.length > 0 else {
            return nil
        }
        
        return fieldEditor.string.substring(with: selectedRange)
    }
}

// Extension to help with string ranges
extension String {
    func substring(with range: NSRange) -> String? {
        guard range.location != NSNotFound,
              let lowerBound = index(startIndex, offsetBy: range.location, limitedBy: endIndex),
              let upperBound = index(lowerBound, offsetBy: range.length, limitedBy: endIndex) else {
            return nil
        }
        return String(self[lowerBound..<upperBound])
    }
}

#Preview {
    ContentView()
}