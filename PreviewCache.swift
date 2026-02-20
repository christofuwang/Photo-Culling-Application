//
//  PreviewCache.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import Foundation
import AppKit

final class PreviewCache {
    static let shared = PreviewCache()

    private let fm = FileManager.default

    private var cacheDir: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("RawPreviews", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func previewURL(for assetID: UUID) -> URL {
        cacheDir.appendingPathComponent("\(assetID.uuidString).jpg")
    }

    func writeJPEG(_ image: NSImage, to url: URL, quality: CGFloat = 0.85) throws {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw NSError(domain: "PreviewCache", code: 1, userInfo: [NSLocalizedDescriptionKey: "JPEG encode failed"])
        }
        try data.write(to: url, options: [.atomic])
    }

    func loadImage(from url: URL) -> NSImage? {
        NSImage(contentsOfFile: url.path)
    }
}

extension NSImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard
            let tiff = self.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }

        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
    }
}
