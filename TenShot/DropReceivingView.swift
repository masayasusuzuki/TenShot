import Cocoa

class DropReceivingView: NSView {

    var onDrop: ((NSImage) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([
            .tiff, .png, .fileURL,
            NSPasteboard.PasteboardType("public.image"),
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([
            .tiff, .png, .fileURL,
            NSPasteboard.PasteboardType("public.image"),
        ])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard

        // ファイルURLから
        if let urls = pb.readObjects(forClasses: [NSURL.self],
                                     options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            for url in urls {
                if let img = NSImage(contentsOf: url) {
                    onDrop?(img)
                    return true
                }
            }
        }

        // 画像データから
        if let img = NSImage(pasteboard: pb) {
            onDrop?(img)
            return true
        }

        return false
    }
}
