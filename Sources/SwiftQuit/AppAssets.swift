import AppKit

enum AppAssets {
    // A packaged app must resolve its installed resources before SwiftPM's
    // development fallback, which can point into the original build directory.
    static let bundle: Bundle = {
        if let url = Bundle.main.url(forResource: "SwiftQuit_SwiftQuit", withExtension: "bundle"),
           let installed = Bundle(url: url) {
            return installed
        }
        return Bundle.module
    }()

    static let appLogo = loadImage("AppIcon")
    static let menuBarIcon: NSImage = {
        let image = loadImage("MenuBarIcon")
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }()

    private static func loadImage(_ name: String) -> NSImage {
        guard let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "Resources"),
              let image = NSImage(contentsOf: url) else {
            preconditionFailure("Missing bundled image: \(name)")
        }
        return image
    }
}
