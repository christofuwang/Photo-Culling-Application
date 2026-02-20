//
//  RawPreviewer.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import Foundation
import ImageIO
import AppKit
import CoreImage

final class RawPreviewer {
    static let shared = RawPreviewer()

    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates: true
    ])

    /// Fast path: embedded thumbnail or preview (typically JPEG inside RAW).
    func embeddedThumbnail(url: URL, maxPixel: Int) -> NSImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        // Prefer embedded thumbnail; allow creation if absent (still usually cheap)
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        return NSImage(cgImage: cg, size: .zero)
    }

    /// Higher quality (slower): Core Image RAW decode in draft mode + downscale.
    func draftRawPreview(url: URL, maxDimension: CGFloat) -> NSImage? {
        guard let raw = CIRAWFilter(imageURL: url) else { return nil }
        raw.isDraftModeEnabled = true
        raw.extendedDynamicRangeAmount = 0
        raw.boostAmount = 0

        guard var img = raw.outputImage else { return nil }
        let extent = img.extent
        let scale = min(maxDimension / max(extent.width, extent.height), 1.0)
        img = img.transformed(by: .init(scaleX: scale, y: scale))

        guard let cg = ciContext.createCGImage(img, from: img.extent) else { return nil }
        return NSImage(cgImage: cg, size: .zero)
    }
}
