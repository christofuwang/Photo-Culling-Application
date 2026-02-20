//
//  ShareSheet.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import SwiftUI
import AppKit

struct ShareSheet: NSViewRepresentable {
    let items: [Any]

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: .zero,
                        of: view,
                        preferredEdge: .minY)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
