//
//  ContentView.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var importer = ImportManager()
    @State private var showPicker = false
    @State private var exportingURL: URL?
    @State private var selectedIndex: Int = 0

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 10)]
    
    func openFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK {
            importer.handlePickedURLs(panel.urls)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                HStack {
                    Button("Import RAWs") {
                        openFiles()
                    }
                    Spacer()
                    Button("Export by Stars") {
                        Task {
                            do {
                                let url = try ExportManager.exportByRating(assets: importer.assets)
                                exportingURL = url
                            } catch {
                                print("Export failed:", error)
                            }
                        }
                    }
                    .disabled(importer.assets.isEmpty)
                }
                .padding(.horizontal)

                if importer.isImporting {
                    ProgressView("Importing…")
                        .padding(.horizontal)
                }

                VStack {

                    // 🔵 Large Image
                    if importer.assets.indices.contains(selectedIndex) {
                        let asset = importer.assets[selectedIndex]

                        if let url = asset.cachedPreviewURL,
                           let image = PreviewCache.shared.loadImage(from: url) {

                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 500)

                            // ⭐ Star Rating
                            HStack {
                                ForEach(0..<5) { i in
                                    Image(systemName:
                                        i < importer.assets[selectedIndex].rating
                                        ? "star.fill"
                                        : "star"
                                    )
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        importer.assets[selectedIndex].rating = i + 1
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // 🔘 Thumbnail Strip
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(importer.assets.indices, id: \.self) { i in
                                if let url = importer.assets[i].cachedPreviewURL,
                                   let image = PreviewCache.shared.loadImage(from: url) {

                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 70)
                                        .clipped()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(
                                                    i == selectedIndex
                                                    ? Color.blue
                                                    : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                        .onTapGesture {
                                            selectedIndex = i
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Photo Culler")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .onMoveCommand { direction in
            switch direction {
            case .left:
                selectedIndex = max(0, selectedIndex - 1)
            case .right:
                selectedIndex = min(importer.assets.count - 1, selectedIndex + 1)
            default:
                break
            }
        }
        .sheet(isPresented: Binding(
            get: { exportingURL != nil },
            set: { if !$0 { exportingURL = nil } }
        )) {
            if let url = exportingURL {
                ShareSheet(items: [url])
            }
        }
    }
}

private struct AssetCell: View {
    @Binding var asset: RawAsset

    var body: some View {
        VStack(spacing: 6) {
            PreviewImageView(cachedURL: asset.cachedPreviewURL)
                .frame(height: 120)
                .clipped()
                .cornerRadius(10)

            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    Image(systemName: i < asset.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            asset.rating = i + 1
                        }
                }
            }

            Text(asset.filename)
                .font(.caption2)
                .lineLimit(1)
                .opacity(0.8)
        }
        .padding(8)
        .background(.thinMaterial)
        .cornerRadius(14)
    }
}

struct PreviewImageView: View {
    let cachedURL: URL?

    var body: some View {
        if let url = cachedURL,
           let image = PreviewCache.shared.loadImage(from: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Rectangle().opacity(0.1)
                ProgressView()
            }
        }
    }
}

import AppKit

