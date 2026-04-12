import Cocoa

class DraggableImageView: NSView {

    var image: NSImage? {
        didSet { needsDisplay = true }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        if image != nil {
            addCursorRect(bounds, cursor: .openHand)
        }
    }

    override func mouseDown(with event: NSEvent) {
        NSCursor.closedHand.push()
    }

    override func mouseUp(with event: NSEvent) {
        NSCursor.pop()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image = image else { return }

        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let widthRatio = bounds.width / imageSize.width
        let heightRatio = bounds.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        let drawWidth = imageSize.width * scale
        let drawHeight = imageSize.height * scale
        let drawX = (bounds.width - drawWidth) / 2
        let drawY = (bounds.height - drawHeight) / 2

        image.draw(in: NSRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight),
                   from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let image = image, let pngData = image.pngData() else { return }

        // 一時ファイルに書き出し
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "TenShot_\(UUID().uuidString).png"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try pngData.write(to: fileURL)
        } catch {
            return
        }

        // ファイルURLとしてドラッグ
        let provider = NSFilePromiseProvider(fileType: "public.png", delegate: self)
        provider.userInfo = fileURL

        let dragItem = NSDraggingItem(pasteboardWriter: fileURL as NSURL)
        dragItem.setDraggingFrame(bounds, contents: image)
        beginDraggingSession(with: [dragItem], event: event, source: self)
    }
}

extension DraggableImageView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
}

extension DraggableImageView: NSFilePromiseProviderDelegate {
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             fileNameForType fileType: String) -> String {
        return "TenShot_\(UUID().uuidString).png"
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             writePromiseTo url: URL,
                             completionHandler: @escaping (Error?) -> Void) {
        guard let sourceURL = filePromiseProvider.userInfo as? URL else {
            completionHandler(NSError(domain: "TenShot", code: 1))
            return
        }
        do {
            try FileManager.default.copyItem(at: sourceURL, to: url)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }

    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return .main
    }
}
