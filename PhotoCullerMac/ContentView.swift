import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        Text("Testing preview extraction")
            .task {
                openAndExtractRaw()
            }
    }

    /// Shows an open panel so the user can pick a RAW file,
    /// then extracts both thumbnail and full raw data.
    private func openAndExtractRaw() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.rawImage]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Select a RAW file"

        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path
            print("User selected:", path)

            // ---- Thumbnail extraction ----
            if let thumbData = PreviewExtractor.extractThumbnail(atPath: path) {
                print("Thumbnail extracted:", thumbData.count, "bytes")
            } else {
                print("Thumbnail extraction failed")
            }

            // ---- Full raw extraction ----
            var width: Int32 = 0
            var height: Int32 = 0
            var channels: Int32 = 0

            if let fullData = PreviewExtractor.extractFullImage(
                atPath: path,
                width: &width,
                height: &height,
                channels: &channels
            ) {
                print("Full image extracted:", fullData.count, "bytes")
                print("Dimensions:", width, "x", height, "Channels:", channels)
            } else {
                print("Full image extraction failed")
            }

        } else {
            print("No file selected")
        }
    }
}

/*
 #Preview {
 ContentView()
 }
 */
