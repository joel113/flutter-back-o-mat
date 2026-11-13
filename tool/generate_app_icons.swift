// Run from the repository root: swift tool/generate_app_icons.swift
// Exports the shared artwork without requiring a Flutter package dependency.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("assets/branding/app_icon.png")
guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
      let artwork = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
    fatalError("Cannot read \(source.path)")
}

func export(_ relativePath: String, size: Int, inset: CGFloat = 0, rounded: Bool = false) {
    let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.interpolationQuality = .high
    let edge = CGFloat(size)
    let rect = CGRect(x: edge * inset, y: edge * inset,
                      width: edge * (1 - 2 * inset), height: edge * (1 - 2 * inset))
    if rounded {
        let radius = rect.width * 0.22
        context.addPath(CGPath(roundedRect: rect, cornerWidth: radius,
                               cornerHeight: radius, transform: nil))
        context.clip()
    }
    context.draw(artwork, in: rect)
    var output = context.makeImage()!
    // App Store icons must be opaque, including their PNG color format.
    if !rounded {
        let rgb = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        rgb.draw(output, in: CGRect(x: 0, y: 0, width: size, height: size))
        output = rgb.makeImage()!
    }
    let url = root.appendingPathComponent(relativePath)
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, output, nil)
    precondition(CGImageDestinationFinalize(destination), "Cannot write \(relativePath)")
}

for platform in ["macos", "ios"] {
    let directory = "\(platform)/Runner/Assets.xcassets/AppIcon.appiconset"
    let data = try Data(contentsOf: root.appendingPathComponent("\(directory)/Contents.json"))
    let manifest = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    var written = Set<String>()
    for entry in manifest["images"] as! [[String: Any]] {
        guard let filename = entry["filename"] as? String,
              written.insert(filename).inserted else { continue }
        let points = Double((entry["size"] as! String).components(separatedBy: "x")[0])!
        let scale = Double((entry["scale"] as! String).replacingOccurrences(of: "x", with: ""))!
        export("\(directory)/\(filename)", size: Int(points * scale),
               inset: platform == "macos" ? 0.10 : 0, rounded: platform == "macos")
    }
    print("Exported \(written.count) \(platform) icons")
}

for (density, size) in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)] {
    export("android/app/src/main/res/mipmap-\(density)/ic_launcher.png", size: size, rounded: true)
}
print("Exported 5 Android icons")
