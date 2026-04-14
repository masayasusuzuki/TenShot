import Cocoa

class ImagePreviewWindow: NSPanel {

    init(image: NSImage) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let imgSize = image.size
        guard imgSize.width > 0, imgSize.height > 0 else {
            super.init(contentRect: .zero, styleMask: [.titled, .closable],
                       backing: .buffered, defer: false)
            return
        }

        // 画面の70%に収まるサイズを計算
        let maxW = screen.visibleFrame.width * 0.7
        let maxH = screen.visibleFrame.height * 0.7
        let scale = min(maxW / imgSize.width, maxH / imgSize.height, 1.0)
        let winW = imgSize.width * scale
        let winH = imgSize.height * scale

        // 画面中央に配置
        let x = screen.frame.midX - winW / 2
        let y = screen.frame.midY - winH / 2
        let rect = NSRect(x: x, y: y, width: winW, height: winH)

        super.init(contentRect: rect,
                   styleMask: [.titled, .closable, .resizable],
                   backing: .buffered, defer: false)

        title = "Preview"
        level = .floating
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        backgroundColor = .black

        let imageView = NSImageView(frame: .zero)
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        imageView.frame = contentView!.bounds
        contentView?.addSubview(imageView)
    }

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            close()
        }
    }
}
