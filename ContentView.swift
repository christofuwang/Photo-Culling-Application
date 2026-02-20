//
//  ContentView.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var importer = ImportManager()
    @State private var exportingURL: URL?
    @State private var selectedIndex: Int = 0
    
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showExportError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                // Top bar
                HStack {
                    Button("Import RAWs") { openFiles() }
                    Spacer()
                    Button("Export by Stars") { chooseExportFolderAndExport() }
                        .disabled(importer.assets.isEmpty)
                }
                .padding(.horizontal)

                if importer.isImporting {
                    ProgressView("Importing…")
                        .padding(.horizontal)
                }
                
                if isExporting {
                    ProgressView("Exporting…")
                        .padding(.horizontal)
                }

                // Gallery
                VStack(spacing: 12) {
                    LargePreview(
                        asset: importer.assets.indices.contains(selectedIndex) ? importer.assets[selectedIndex] : nil,
                        rating: importer.assets.indices.contains(selectedIndex)
                            ? Binding(
                                get: { importer.assets[selectedIndex].rating },
                                set: { importer.assets[selectedIndex].rating = $0 }
                              )
                            : .constant(0)
                    )

                    Divider()

                    ThumbnailStrip(
                        assets: importer.assets,
                        selectedIndex: $selectedIndex
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Photo Culler")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .onMoveCommand(perform: handleMoveCommand)
        .onKeyPress(.init("0")) { setRating(0); return .handled }
        .onKeyPress(.init("1")) { setRating(1); return .handled }
        .onKeyPress(.init("2")) { setRating(2); return .handled }
        .onKeyPress(.init("3")) { setRating(3); return .handled }
        .onKeyPress(.init("4")) { setRating(4); return .handled }
        .onKeyPress(.init("5")) { setRating(5); return .handled }
        .sheet(isPresented: Binding(
            get: { exportingURL != nil },
            set: { if !$0 { exportingURL = nil } }
        )) {
            if let url = exportingURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Actions

    private func openFiles() {
        let panel = NSOpenPanel()
        panel.title = "Select RAW files or folders"
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK {
            importer.handlePickedURLs(panel.urls)
        }
    }

    private func chooseExportFolderAndExport() {
        let panel = NSOpenPanel()
        panel.title = "Choose export destination"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let destFolder = panel.url else { return }

        // ✅ IMPORTANT for sandboxed apps
        let ok = destFolder.startAccessingSecurityScopedResource()
        defer { if ok { destFolder.stopAccessingSecurityScopedResource() } }

        isExporting = true

        Task(priority: .userInitiated) {
            do {
                let exportRoot = try ExportManager.exportByRating(assets: importer.assets, to: destFolder)

                // defer state publish to avoid "Publishing changes from within view updates"
                DispatchQueue.main.async {
                    isExporting = false
                    NSWorkspace.shared.activateFileViewerSelecting([exportRoot])
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    exportError = error.localizedDescription
                    showExportError = true
                }
            }
        }
    }

    private func setRating(_ r: Int) {
        guard importer.assets.indices.contains(selectedIndex) else { return }
        DispatchQueue.main.async {
            importer.assets[selectedIndex].rating = r
        }
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        guard !importer.assets.isEmpty else { return }
        switch direction {
        case .left:
            selectedIndex = max(0, selectedIndex - 1)
        case .right:
            selectedIndex = min(importer.assets.count - 1, selectedIndex + 1)
        default:
            break
        }
    }
}

// MARK: - Large Preview

private struct LargePreview: View {
    let asset: RawAsset?
    @Binding var rating: Int

    var body: some View {
        VStack(spacing: 8) {
            if let asset,
               let url = asset.cachedPreviewURL,
               let image = PreviewCache.shared.loadImage(from: url) {

                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 520)
                    .frame(maxWidth: .infinity)

                StarRow(rating: $rating)
            } else {
                ZStack {
                    Rectangle().opacity(0.08)
                    Text("Import RAWs to begin")
                        .foregroundStyle(.secondary)
                }
                .frame(height: 520)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Stars

private struct StarRow: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        rating = (rating == star) ? 0 : star
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Thumbnail Strip

private struct ThumbnailStrip: View {
    let assets: [RawAsset]
    @Binding var selectedIndex: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(assets.indices, id: \.self) { i in
                        ThumbnailCell(
                            asset: assets[i],
                            isSelected: i == selectedIndex
                        )
                        .id(i)
                        .onTapGesture { selectedIndex = i }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned) // macOS 14+
            .onChange(of: selectedIndex) { _, newValue in
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

private struct ThumbnailCell: View {
    let asset: RawAsset
    let isSelected: Bool

    var body: some View {
        Group {
            if let url = asset.cachedPreviewURL,
               let img = PreviewCache.shared.loadImage(from: url) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle().opacity(0.08)
                    ProgressView().scaleEffect(0.8)
                }
            }
        }
        .frame(width: 110, height: 72)
        .clipped()
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? .blue : .clear, lineWidth: 2)
        )
    }
}

