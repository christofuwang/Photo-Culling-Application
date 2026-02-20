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

    func openFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image] // reliable for many RAWs on macOS
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.title = "Select RAW files or folders"

        if panel.runModal() == .OK {
            handlePickedURLs(panel.urls)
        }
    }

    func handlePickedURLs(_ urls: [URL]) {
        isImporting = true

        Task(priority: .userInitiated) {
            var newAssets: [RawAsset] = []

            let rawExts: Set<String> = [
                "cr2","cr3","nef","arw","dng","raf","orf","rw2","srw","pef","3fr","iiq",
                "mos","kdc","dcr","erf","mrw","nrw"
            ]
            let imgExts: Set<String> = ["jpg","jpeg","heic","png","tif","tiff"]

            func isSupported(_ url: URL) -> Bool {
                let ext = url.pathExtension.lowercased()
                return rawExts.contains(ext) || imgExts.contains(ext)
            }

            func collectFilesRecursively(from url: URL) -> [URL] {
                if !url.hasDirectoryPath {
                    return isSupported(url) ? [url] : []
                }

                var out: [URL] = []
                if let en = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) {
                    for case let fileURL as URL in en {
                        let isRegular = (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
                        if isRegular && isSupported(fileURL) {
                            out.append(fileURL)
                        }
                    }
                }
                return out
            }

            for picked in urls {
                let fileURLs = collectFilesRecursively(from: picked)
                print("ImportManager: \(picked.lastPathComponent) -> \(fileURLs.count) files")

                for fileURL in fileURLs {
                    var asset = RawAsset(url: fileURL)

                    if let preview = RawPreviewer.shared.embeddedThumbnail(url: fileURL, maxPixel: 1200) {
                        let outURL = PreviewCache.shared.previewURL(for: asset.id)
                        try? PreviewCache.shared.writeJPEG(preview, to: outURL)
                        asset.cachedPreviewURL = outURL
                    } else if let fallback = RawPreviewer.shared.draftRawPreview(url: fileURL, maxDimension: 1600) {
                        let outURL = PreviewCache.shared.previewURL(for: asset.id)
                        try? PreviewCache.shared.writeJPEG(fallback, to: outURL)
                        asset.cachedPreviewURL = outURL
                    }

                    newAssets.append(asset)
                }
            }

            self.assets.append(contentsOf: newAssets)
            self.isImporting = false
        }
    }}
