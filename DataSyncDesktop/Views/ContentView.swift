//
//  ContentView.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import SwiftUI
import AppKit

// Custom NSTextView wrapped in a SwiftUI View for selectable text
struct SelectableTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var onCopySelection: ((String) -> Void)?
    
    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.delegate = context.coordinator
        
        // Add a context menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Copy Selection", action: #selector(Coordinator.copySelection(_:)), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Select All", action: #selector(Coordinator.selectAll(_:)), keyEquivalent: "a"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Find...", action: #selector(Coordinator.showFindInterface(_:)), keyEquivalent: "f"))
        textView.menu = menu
        
        // Setup scrollview
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.documentView = textView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SelectableTextView
        
        init(_ parent: SelectableTextView) {
            self.parent = parent
        }
        
        @objc func copySelection(_ sender: Any?) {
            guard let textView = (sender as? NSMenuItem)?.menu?.delegate as? NSTextView else {
                if let textView = NSApp.mainWindow?.firstResponder as? NSTextView {
                    copyFromTextView(textView)
                }
                return
            }
            copyFromTextView(textView)
        }
        
        private func copyFromTextView(_ textView: NSTextView) {
            if let selectedText = textView.string.substring(with: textView.selectedRange()) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(selectedText, forType: .string)
                parent.onCopySelection?(selectedText)
            }
        }
        
        @objc func selectAll(_ sender: Any?) {
            guard let textView = (sender as? NSMenuItem)?.menu?.delegate as? NSTextView else {
                if let textView = NSApp.mainWindow?.firstResponder as? NSTextView {
                    textView.selectAll(nil)
                }
                return
            }
            textView.selectAll(nil)
        }
        
        @objc func showFindInterface(_ sender: Any?) {
            guard let textView = (sender as? NSMenuItem)?.menu?.delegate as? NSTextView else {
                return
            }
            textView.performFindPanelAction(nil)
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
                        
                        if selectedText != nil && !selectedText!.isEmpty {
                            Button("Copy Selection") {
                                copyToClipboard(selectedText ?? "", message: "Selection copied to clipboard!")
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.blue)
                            .padding(.trailing, 10)
                        }
                        
                        Button("Copy All") {
                            copyToClipboard(sqlOutput, message: "All SQL copied to clipboard!")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    // Custom text view that supports selection
                    SelectableTextView(text: $sqlOutput, font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)) { selectedText in
                        self.selectedText = selectedText
                    }
                    .frame(height: 300)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Instructions for text selection
                    Text("Tip: Select text to copy specific parts. Right-click for more options.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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