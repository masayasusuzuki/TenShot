import AppKit

class ImageStore {
    static let shared = ImageStore()

    private(set) var images: [Data] = []
    let maxImages = 10
    private let indexKey = "TenShot.imageIndex"
    private let legacyKey = "TenShot.images"
    private let jpegQuality: CGFloat = 0.75

    var onChange: (() -> Void)?

    private init() {
        migrateFromLegacyIfNeeded()
        load()
    }

    func add(image: NSImage) {
        guard let jpeg = image.jpegData(quality: jpegQuality) else { return }
        if images.count >= maxImages { images.removeFirst() }
        images.append(jpeg)
        save()
        onChange?()
    }

    func remove(at index: Int) {
        guard images.indices.contains(index) else { return }
        images.remove(at: index)
        save()
        onChange?()
    }

    func clear() {
        images.removeAll()
        save()
        onChange?()
    }

    func nsImage(at index: Int) -> NSImage? {
        guard images.indices.contains(index) else { return nil }
        return NSImage(data: images[index])
    }

    private func save() {
        let dir = imagesDirectory()
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var names: [String] = []
        for (i, data) in images.enumerated() {
            let name = String(format: "%03d.jpg", i)
            let url = dir.appendingPathComponent(name)
            try? data.write(to: url)
            names.append(name)
        }
        UserDefaults.standard.set(names, forKey: indexKey)
    }

    private func load() {
        let dir = imagesDirectory()
        let names = UserDefaults.standard.array(forKey: indexKey) as? [String] ?? []
        images = names.compactMap { name in
            try? Data(contentsOf: dir.appendingPathComponent(name))
        }
    }

    private func migrateFromLegacyIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: legacyKey) != nil else { return }
        defaults.removeObject(forKey: legacyKey)
    }

    private func imagesDirectory() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = base.appendingPathComponent("TenShot/images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

extension NSImage {
    func jpegData(quality: CGFloat) -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
    }

    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
