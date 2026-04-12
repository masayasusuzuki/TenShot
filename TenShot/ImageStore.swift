import AppKit

class ImageStore {
    static let shared = ImageStore()

    private(set) var images: [Data] = []
    let maxImages = 10
    private let key = "TenShot.images"

    // 画像変更時に呼ばれるコールバック
    var onChange: (() -> Void)?

    private init() { load() }

    func add(image: NSImage) {
        guard let png = image.pngData() else { return }
        if images.count >= maxImages { images.removeFirst() }
        images.append(png)
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
        UserDefaults.standard.set(images, forKey: key)
    }

    private func load() {
        images = UserDefaults.standard.array(forKey: key) as? [Data] ?? []
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
