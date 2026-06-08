//
//  FinderSync.swift
//  CreateFileFinderExtension
//
//  Created by 林瑞生 on 2026/6/7.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    override init() {
        super.init()

        NSLog("CreateFileFinderExtension loaded")

        let fileManager = FileManager.default
        let userHomeURL = URL(fileURLWithPath: "/Users/\(NSUserName())")
        let directoryURLs = [
            userHomeURL,
            userHomeURL.appendingPathComponent("Desktop"),
            userHomeURL.appendingPathComponent("Downloads"),
            userHomeURL.appendingPathComponent("Documents")
        ].filter { fileManager.fileExists(atPath: $0.path) }

        NSLog("CreateFileFinderExtension watch directories: %@", directoryURLs.map(\.path).joined(separator: ", "))

        FIFinderSyncController.default().directoryURLs = Set(directoryURLs)
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        NSLog("CreateFileFinderExtension menu requested: %@", "\(menuKind)")

        let menu = NSMenu(title: "")
        let newFileItem = NSMenuItem(title: "新建文件", action: nil, keyEquivalent: "")
        let newFileMenu = NSMenu(title: "新建文件")

        let textItem = NSMenuItem(
            title: "TXT 文件",
            action: #selector(createTextFile(_:)),
            keyEquivalent: ""
        )
        textItem.target = self
        newFileMenu.addItem(textItem)

        let wordItem = NSMenuItem(
            title: "Word 文档",
            action: #selector(createWordFile(_:)),
            keyEquivalent: ""
        )
        wordItem.target = self
        newFileMenu.addItem(wordItem)

        let powerpointItem = NSMenuItem(
            title: "PowerPoint 演示文稿",
            action: #selector(createPowerPointFile(_:)),
            keyEquivalent: ""
        )
        powerpointItem.target = self
        newFileMenu.addItem(powerpointItem)

        let excelItem = NSMenuItem(
            title: "Excel 工作簿",
            action: #selector(createExcelFile(_:)),
            keyEquivalent: ""
        )
        excelItem.target = self
        newFileMenu.addItem(excelItem)

        newFileItem.submenu = newFileMenu
        menu.addItem(newFileItem)

        return menu
    }

    @objc func createTextFile(_ sender: Any?) {
        NSLog("CreateFileFinderExtension: createTextFile invoked")
        createEmptyFile(baseName: "新建文本", ext: "txt")
    }

    @objc func createWordFile(_ sender: Any?) {
        NSLog("CreateFileFinderExtension: createWordFile invoked")
        createFileFromTemplate(templateName: "Blank", ext: "docx", baseName: "新建 Word 文档")
    }

    @objc func createPowerPointFile(_ sender: Any?) {
        NSLog("CreateFileFinderExtension: createPowerPointFile invoked")
        createFileFromTemplate(templateName: "Blank", ext: "pptx", baseName: "新建 PowerPoint 演示文稿")
    }

    @objc func createExcelFile(_ sender: Any?) {
        NSLog("CreateFileFinderExtension: createExcelFile invoked")
        createFileFromTemplate(templateName: "Blank", ext: "xlsx", baseName: "新建 Excel 工作簿")
    }

    private func createEmptyFile(baseName: String, ext: String) {
        guard let directoryURL = currentFinderDirectory() else {
            NSLog("CreateFileFinderExtension: failed to resolve Finder target directory")
            return
        }

        NSLog("CreateFileFinderExtension: target directory %@", directoryURL.path)

        let fileURL = uniqueFileURL(
            in: directoryURL,
            baseName: baseName,
            ext: ext
        )

        NSLog("CreateFileFinderExtension: creating file %@", fileURL.path)

        do {
            try Data().write(to: fileURL, options: .withoutOverwriting)
            NSLog("CreateFileFinderExtension: created file %@", fileURL.path)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch {
            NSLog(
                "CreateFileFinderExtension: failed to create file at %@: %@",
                fileURL.path,
                error.localizedDescription
            )
        }
    }

    private func createFileFromTemplate(templateName: String, ext: String, baseName: String) {
        guard let directoryURL = currentFinderDirectory() else {
            NSLog("CreateFileFinderExtension: failed to resolve Finder target directory")
            return
        }

        guard let templateURL = templateURL(name: templateName, ext: ext) else {
            NSLog("CreateFileFinderExtension: missing template %@.%@", templateName, ext)
            return
        }

        NSLog("CreateFileFinderExtension: target directory %@", directoryURL.path)

        let fileURL = uniqueFileURL(
            in: directoryURL,
            baseName: baseName,
            ext: ext
        )

        NSLog("CreateFileFinderExtension: copying template %@ to %@", templateURL.path, fileURL.path)

        do {
            try FileManager.default.copyItem(at: templateURL, to: fileURL)
            NSLog("CreateFileFinderExtension: created file %@", fileURL.path)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch {
            NSLog(
                "CreateFileFinderExtension: failed to copy template to %@: %@",
                fileURL.path,
                error.localizedDescription
            )
        }
    }

    private func templateURL(name: String, ext: String) -> URL? {
        Bundle(for: FinderSync.self).url(
            forResource: name,
            withExtension: ext,
            subdirectory: "Templates"
        )
        ?? Bundle(for: FinderSync.self).url(
            forResource: name,
            withExtension: ext
        )
    }

    private func currentFinderDirectory() -> URL? {
        let controller = FIFinderSyncController.default()

        if let selectedURL = controller.selectedItemURLs()?.first {
            return directoryToCreateFile(from: selectedURL)
        }

        if let targetedURL = controller.targetedURL() {
            return directoryToCreateFile(from: targetedURL)
        }

        return nil
    }

    private func directoryToCreateFile(from url: URL) -> URL {
        var isDirectory: ObjCBool = false

        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // 如果右键的是文件夹，就在这个文件夹里面新建文件。
                return url
            } else {
                // 如果右键的是文件，就在这个文件所在的文件夹里新建文件。
                return url.deletingLastPathComponent()
            }
        }

        // 如果路径判断失败，保守地使用它的上一级目录。
        return url.deletingLastPathComponent()
    }

    private func uniqueFileURL(in directory: URL, baseName: String, ext: String) -> URL {
        var fileURL = directory.appendingPathComponent("\(baseName).\(ext)")
        var index = 1

        while FileManager.default.fileExists(atPath: fileURL.path) {
            fileURL = directory.appendingPathComponent("\(baseName) \(index).\(ext)")
            index += 1
        }

        return fileURL
    }
    override func beginObservingDirectory(at url: URL) {
        NSLog("CreateFileFinderExtension begin observing: %@", url.path)
    }

    override func endObservingDirectory(at url: URL) {
        NSLog("CreateFileFinderExtension end observing: %@", url.path)
    }

    override func requestBadgeIdentifier(for url: URL) {
        NSLog("CreateFileFinderExtension request badge for: %@", url.path)
    }
    override var toolbarItemName: String {
        return "CreateFile"
    }

    override var toolbarItemToolTip: String {
        return "新建文件"
    }

    override var toolbarItemImage: NSImage {
        return NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
            ?? NSImage()
    }
}
