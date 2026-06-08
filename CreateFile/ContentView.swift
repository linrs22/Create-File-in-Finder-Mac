//
//  ContentView.swift
//  CreateFile
//
//  Created by 林瑞生 on 2026/6/7.
//

import SwiftUI

struct ContentView: View {
    private let finderExtensionBundleID = "com.linruisheng.CreateFile.CreateFileFinderExtension"
    private let appPath = Bundle.main.bundlePath
    @State private var extensionStatus: FinderExtensionStatus = .checking

    private var extensionPath: String {
        "\(appPath)/Contents/PlugIns/CreateFileFinderExtension.appex"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                extensionStatusSection
                statusSection
                developmentSection
                stableInstallSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 680)
        .frame(minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            refreshExtensionStatus()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 34))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("CreateFile")
                    .font(.title.bold())
                Text("Finder 右键新建 TXT、Word、PowerPoint、Excel 文件")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var extensionStatusSection: some View {
        SectionBox(title: "Finder 扩展状态") {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: extensionStatus.icon)
                    .frame(width: 22)
                    .foregroundStyle(extensionStatus.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(extensionStatus.title)
                        .font(.subheadline.bold())
                    Text(extensionStatus.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    refreshExtensionStatus()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .help("重新检测 Finder 扩展状态")
            }

            InfoRow(
                icon: "switch.2",
                title: "启用位置",
                detail: "如果显示未启用，请到系统设置 → 登录项与扩展 → 扩展 → Finder 扩展，打开 CreateFile。"
            )
        }
    }

    private var statusSection: some View {
        SectionBox(title: "当前加载逻辑") {
            InfoRow(
                icon: "puzzlepiece.extension",
                title: "扩展随 App 注册",
                detail: "系统会通过 PlugInKit 发现这个 App 内置的 Finder 扩展。主 App 关闭后，Finder 仍然可以单独加载扩展。"
            )

            InfoRow(
                icon: "folder",
                title: "当前 App 路径",
                detail: appPath
            )

            InfoRow(
                icon: "shippingbox",
                title: "Finder 扩展路径",
                detail: extensionPath
            )
        }
    }

    private var developmentSection: some View {
        SectionBox(title: "开发期怎么更新") {
            InfoRow(
                icon: "hammer",
                title: "改完代码后重新构建",
                detail: "如果构建仍然输出到同一个 Debug 路径，系统记录通常会继续指向同一份扩展。"
            )

            CommandBlock(commands: [
                "xcodebuild -project CreateFile.xcodeproj -scheme CreateFile -configuration Debug build",
                "open ~/Library/Developer/Xcode/DerivedData/CreateFile-bmbxpodulmdpcbbggsenllbfqixi/Build/Products/Debug/CreateFile.app",
                "killall Finder"
            ])

            InfoRow(
                icon: "arrow.clockwise",
                title: "为什么要重启 Finder",
                detail: "Finder 可能还在内存里使用旧扩展实例。重启 Finder 后，它会重新加载刚构建出来的新版本。"
            )
        }
    }

    private var stableInstallSection: some View {
        SectionBox(title: "固定安装时要注意") {
            InfoRow(
                icon: "externaldrive",
                title: "Finder 不会自动复制扩展",
                detail: "系统加载的是注册路径里的 .appex。现在开发期通常是 DerivedData 里的 Debug 版本；固定安装后应指向 /Applications/CreateFile.app 里的扩展。"
            )

            InfoRow(
                icon: "exclamationmark.triangle",
                title: "避免重复扩展",
                detail: "同一个 App 放在多个路径时，系统可能同时记住多个扩展。固定安装后，建议注销旧 Debug 路径，只保留固定位置那一份。"
            )
        }
    }

    private func refreshExtensionStatus() {
        extensionStatus = .checking

        Task.detached {
            let status = FinderExtensionDetector.detect(bundleID: finderExtensionBundleID)

            await MainActor.run {
                extensionStatus = status
            }
        }
    }
}

private enum FinderExtensionStatus: Sendable {
    case checking
    case enabled(path: String)
    case disabled(path: String)
    case notFound
    case failed(String)

    var title: String {
        switch self {
        case .checking:
            return "正在检测 Finder 扩展"
        case .enabled:
            return "Finder 扩展已启用"
        case .disabled:
            return "Finder 扩展已注册，但尚未启用"
        case .notFound:
            return "尚未发现 Finder 扩展"
        case .failed:
            return "无法检测 Finder 扩展状态"
        }
    }

    var detail: String {
        switch self {
        case .checking:
            return "正在读取 PlugInKit 注册信息..."
        case .enabled(let path):
            return "系统已启用 CreateFile Finder 扩展。\n路径：\(path)"
        case .disabled(let path):
            return "系统已经找到扩展，但当前没有启用。\n路径：\(path)"
        case .notFound:
            return "系统还没有注册 CreateFile Finder 扩展。请先打开一次 CreateFile.app，然后重新检测。"
        case .failed(let message):
            return message
        }
    }

    var icon: String {
        switch self {
        case .checking:
            return "hourglass"
        case .enabled:
            return "checkmark.circle.fill"
        case .disabled:
            return "exclamationmark.circle.fill"
        case .notFound:
            return "questionmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .checking:
            return .secondary
        case .enabled:
            return .green
        case .disabled:
            return .orange
        case .notFound, .failed:
            return .red
        }
    }
}

private enum FinderExtensionDetector {
    nonisolated static func detect(bundleID: String) -> FinderExtensionStatus {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-m", "-A", "-p", "com.apple.FinderSync", "-v"]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .failed("无法运行 pluginkit：\(error.localizedDescription)")
        }

        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let errorOutput = String(
            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        guard process.terminationStatus == 0 else {
            let message = errorOutput.isEmpty ? output : errorOutput
            return .failed(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        guard let line = output
            .components(separatedBy: .newlines)
            .first(where: { $0.contains(bundleID) }) else {
            return .notFound
        }

        let path = line
            .components(separatedBy: "\t")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if line.hasPrefix("+") {
            return .enabled(path: path)
        }

        return .disabled(path: path)
    }
}

private struct SectionBox<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct CommandBlock: View {
    let commands: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(commands, id: \.self) { command in
                Text(command)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

#Preview {
    ContentView()
}
