import Cocoa

class PanelViewController: NSViewController {

    private let store = ImageStore.shared
    private var scrollView: NSScrollView!
    private var stackView: NSStackView!
    private var countLabel: NSTextField!

    private let frameWidth: CGFloat = 10

    override func loadView() {
        let corkView = CorkTextureView(frame: NSRect(x: 0, y: 0, width: 300, height: 600))
        corkView.onDrop = { [weak self] image in
            self?.store.add(image: image)
        }
        view = corkView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        reloadImages()

        store.onChange = { [weak self] in
            DispatchQueue.main.async {
                self?.reloadImages()
            }
        }
    }

    private func buildUI() {
        // 木枠
        let frameLeft = WoodFrameView()
        frameLeft.edge = .left
        let frameRight = WoodFrameView()
        frameRight.edge = .right
        let frameTop = WoodFrameView()
        frameTop.edge = .top
        let frameBottom = WoodFrameView()
        frameBottom.edge = .bottom

        // ヘッダー（木枠の上に載せる）
        let headerBg = NSView()
        headerBg.wantsLayer = true
        headerBg.layer?.backgroundColor = NSColor(red: 90/255, green: 55/255, blue: 25/255, alpha: 0.85).cgColor

        let title = NSTextField(labelWithString: "10Shot")
        title.font = NSFont(name: "Marker Felt", size: 18) ?? .boldSystemFont(ofSize: 18)
        title.textColor = NSColor(red: 255/255, green: 230/255, blue: 190/255, alpha: 1)

        countLabel = NSTextField(labelWithString: "(0/10)")
        countLabel.font = NSFont(name: "Marker Felt", size: 12) ?? .systemFont(ofSize: 12)
        countLabel.textColor = NSColor(red: 255/255, green: 230/255, blue: 190/255, alpha: 0.6)

        let ssBtn = makeButton(title: "SS")
        ssBtn.action = #selector(takeScreenshot)
        ssBtn.target = self
        ssBtn.toolTip = "範囲選択スクリーンショット"

        let clearBtn = makeButton(title: "Clear")
        clearBtn.action = #selector(clearAll)
        clearBtn.target = self

        // ドロップゾーン（コルクに溶け込む点線枠）
        let dropZone = NSView()
        dropZone.wantsLayer = true
        dropZone.layer?.cornerRadius = 4
        dropZone.layer?.borderWidth = 0

        let dropLabel = NSTextField(labelWithString: "Drop images here")
        dropLabel.font = NSFont(name: "Marker Felt", size: 13) ?? .systemFont(ofSize: 13)
        dropLabel.textColor = NSColor(red: 100/255, green: 65/255, blue: 30/255, alpha: 0.5)
        dropLabel.alignment = .center

        // スクロールビュー
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay

        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 16
        stackView.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        scrollView.documentView = stackView

        for v: NSView in [frameLeft, frameRight, frameTop, frameBottom,
                          headerBg, title, countLabel, ssBtn, clearBtn,
                          dropZone, dropLabel, scrollView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }

        NSLayoutConstraint.activate([
            // 木枠 四辺
            frameTop.topAnchor.constraint(equalTo: view.topAnchor),
            frameTop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frameTop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frameTop.heightAnchor.constraint(equalToConstant: frameWidth),

            frameBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frameBottom.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frameBottom.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            frameBottom.heightAnchor.constraint(equalToConstant: frameWidth),

            frameLeft.topAnchor.constraint(equalTo: frameTop.bottomAnchor),
            frameLeft.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frameLeft.bottomAnchor.constraint(equalTo: frameBottom.topAnchor),
            frameLeft.widthAnchor.constraint(equalToConstant: frameWidth),

            frameRight.topAnchor.constraint(equalTo: frameTop.bottomAnchor),
            frameRight.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frameRight.bottomAnchor.constraint(equalTo: frameBottom.topAnchor),
            frameRight.widthAnchor.constraint(equalToConstant: frameWidth),

            // ヘッダー（木枠の内側）
            headerBg.topAnchor.constraint(equalTo: frameTop.bottomAnchor),
            headerBg.leadingAnchor.constraint(equalTo: frameLeft.trailingAnchor),
            headerBg.trailingAnchor.constraint(equalTo: frameRight.leadingAnchor),
            headerBg.heightAnchor.constraint(equalToConstant: 40),

            title.leadingAnchor.constraint(equalTo: headerBg.leadingAnchor, constant: 10),
            title.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),

            countLabel.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 4),
            countLabel.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),

            clearBtn.trailingAnchor.constraint(equalTo: headerBg.trailingAnchor, constant: -6),
            clearBtn.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),
            ssBtn.trailingAnchor.constraint(equalTo: clearBtn.leadingAnchor, constant: -3),
            ssBtn.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),

            // ドロップゾーン
            dropZone.topAnchor.constraint(equalTo: headerBg.bottomAnchor, constant: 8),
            dropZone.leadingAnchor.constraint(equalTo: frameLeft.trailingAnchor, constant: 10),
            dropZone.trailingAnchor.constraint(equalTo: frameRight.leadingAnchor, constant: -10),
            dropZone.heightAnchor.constraint(equalToConstant: 36),

            dropLabel.centerXAnchor.constraint(equalTo: dropZone.centerXAnchor),
            dropLabel.centerYAnchor.constraint(equalTo: dropZone.centerYAnchor),

            // スクロール
            scrollView.topAnchor.constraint(equalTo: dropZone.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: frameLeft.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: frameRight.leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: frameBottom.topAnchor),
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
        ])
    }

    private func makeButton(title: String) -> NSButton {
        let btn = NSButton(title: title, target: nil, action: nil)
        btn.bezelStyle = .rounded
        btn.font = .systemFont(ofSize: 10, weight: .medium)
        return btn
    }

    // MARK: - 画像カード生成

    private func makePhotoCard(image: NSImage, index: Int) -> NSView {
        // 白い写真用紙
        let card = NSView()
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.white.cgColor
        card.layer?.shadowColor = NSColor.black.withAlphaComponent(0.5).cgColor
        card.layer?.shadowOffset = CGSize(width: 1.5, height: -2.5)
        card.layer?.shadowRadius = 5
        card.layer?.shadowOpacity = 0.6
        card.translatesAutoresizingMaskIntoConstraints = false

        // ランダムに少し傾ける
        let angle = Double.random(in: -1.8...1.8)
        card.frameCenterRotation = angle

        // テープ（上部に貼る）
        let tape = TapeView()
        let tapeColors: [NSColor] = [
            NSColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 0.7),   // ベージュ
            NSColor(red: 0.75, green: 0.85, blue: 0.8, alpha: 0.65),  // ミント
            NSColor(red: 0.85, green: 0.78, blue: 0.85, alpha: 0.65), // ラベンダー
            NSColor(red: 0.9, green: 0.82, blue: 0.75, alpha: 0.7),   // ピーチ
        ]
        tape.tapeColor = tapeColors[index % tapeColors.count]
        tape.translatesAutoresizingMaskIntoConstraints = false
        // テープも少し傾ける
        tape.frameCenterRotation = Double.random(in: -8...8)

        // 画像
        let imgView = DraggableImageView()
        imgView.image = image
        imgView.translatesAutoresizingMaskIntoConstraints = false

        // ボタン
        let copyBtn = NSButton(title: "Copy", target: self, action: #selector(copyImage(_:)))
        copyBtn.bezelStyle = .rounded
        copyBtn.font = .systemFont(ofSize: 10)
        copyBtn.tag = index
        copyBtn.translatesAutoresizingMaskIntoConstraints = false

        let removeBtn = NSButton(title: "x", target: self, action: #selector(removeImage(_:)))
        removeBtn.bezelStyle = .circular
        removeBtn.font = .boldSystemFont(ofSize: 9)
        removeBtn.tag = index
        removeBtn.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(imgView)
        card.addSubview(copyBtn)
        card.addSubview(removeBtn)
        card.addSubview(tape)

        NSLayoutConstraint.activate([
            imgView.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            imgView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            imgView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            imgView.heightAnchor.constraint(equalToConstant: 140),

            copyBtn.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 5),
            copyBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            copyBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),

            removeBtn.centerYAnchor.constraint(equalTo: copyBtn.centerYAnchor),
            removeBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            removeBtn.widthAnchor.constraint(equalToConstant: 20),
            removeBtn.heightAnchor.constraint(equalToConstant: 20),

            tape.centerXAnchor.constraint(equalTo: card.centerXAnchor, constant: CGFloat.random(in: -15...15)),
            tape.topAnchor.constraint(equalTo: card.topAnchor, constant: -4),
            tape.widthAnchor.constraint(equalToConstant: 50),
            tape.heightAnchor.constraint(equalToConstant: 16),
        ])

        return card
    }

    // MARK: - Reload

    func reloadImages() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        countLabel.stringValue = "(\(store.images.count)/\(store.maxImages))"

        if store.images.isEmpty {
            let empty = NSTextField(labelWithString: "No images pinned yet")
            empty.textColor = NSColor(red: 100/255, green: 65/255, blue: 30/255, alpha: 0.5)
            empty.font = NSFont(name: "Marker Felt", size: 15) ?? .systemFont(ofSize: 15)
            empty.alignment = .center
            stackView.addArrangedSubview(empty)
            return
        }

        for i in stride(from: store.images.count - 1, through: 0, by: -1) {
            guard let img = store.nsImage(at: i) else { continue }
            let card = makePhotoCard(image: img, index: i)
            stackView.addArrangedSubview(card)
            card.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -24).isActive = true
        }
    }

    // MARK: - Actions

    @objc private func copyImage(_ sender: NSButton) {
        guard let img = store.nsImage(at: sender.tag) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([img])
        sender.title = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { sender.title = "Copy" }
    }

    @objc private func removeImage(_ sender: NSButton) {
        store.remove(at: sender.tag)
    }

    @objc private func clearAll() {
        store.clear()
    }

    @objc private func takeScreenshot() {
        view.window?.orderOut(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let tempFile = FileManager.default.temporaryDirectory
                .appendingPathComponent("TenShot_ss_\(UUID().uuidString).png").path

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", tempFile]

            process.terminationHandler = { _ in
                DispatchQueue.main.async {
                    self?.view.window?.orderFrontRegardless()

                    if FileManager.default.fileExists(atPath: tempFile),
                       let img = NSImage(contentsOfFile: tempFile) {
                        self?.store.add(image: img)
                        try? FileManager.default.removeItem(atPath: tempFile)
                    }
                }
            }

            try? process.run()
        }
    }

}
