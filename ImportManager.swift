//
//  ImportManager.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import Foundation
import Combine
import UniformTypeIdentifiers
import AppKit

@MainActor
final class ImportManager: ObservableObject {

    @Published var assets: [RawAsset] = []
    @Published var isImporting: Bool = false

    // MARK: - Open Panel (macOS)
    func openFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.rawImage, .image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.title = "Select RAW Files"

        if panel.runModal() == .OK {
            handlePickedURLs(panel.urls)
        }
    }

    // MARK: - Import + Preview Generation
    func handlePickedURLs(_ urls: [URL]) {
        isImporting = true

        Task(priority: .userInitiated) {
            var newAssets: [RawAsset] = []

            for url in urls {

                var fileURLs: [URL] = []

                if url.hasDirectoryPath {
                    if let contents = try? FileManager.default.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: nil
                    ) {
                        fileURLs = contents.filter { !$0.hasDirectoryPath }
                    }
                } else {
                    fileURLs = [url]
                }

                for fileURL in fileURLs {
                    var asset = RawAsset(url: fileURL)

                    if let preview = RawPreviewer.shared.embeddedThumbnail(
                        url: fileURL,
                        maxPixel: 1200
                    ) {
                        let outURL = PreviewCache.shared.previewURL(for: asset.id)
                        try? PreviewCache.shared.writeJPEG(preview, to: outURL)
                        asset.cachedPreviewURL = outURL
                    }

                    newAssets.append(asset)
                }
            }

            self.assets.append(contentsOf: newAssets)
            self.isImporting = false
        }
    }
}
