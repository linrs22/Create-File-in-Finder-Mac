# CreateFile

CreateFile is a lightweight macOS Finder extension that adds a "New File" submenu to the Finder context menu. It lets you quickly create TXT, Word, PowerPoint, and Excel files in common Finder locations.

CreateFile 是一个轻量级 macOS Finder 扩展工具。它会在 Finder 右键菜单中添加“新建文件”入口，支持快速创建 TXT、Word、PowerPoint 和 Excel 文件。

## Features

- Create TXT files directly from the Finder context menu.
- Create valid `.docx`, `.pptx`, and `.xlsx` files from bundled blank templates.
- Automatically avoids filename conflicts, such as `新建文本 1.txt`.
- Selects the newly created file in Finder after creation.
- Supports common folders including Home, Desktop, Downloads, and Documents.

## 功能

- 在 Finder 右键菜单中直接新建 TXT 文件。
- 通过内置空白模板创建有效的 `.docx`、`.pptx`、`.xlsx` 文件。
- 自动处理重名文件，例如 `新建文本 1.txt`。
- 创建完成后自动在 Finder 中选中新文件。
- 支持用户 Home、桌面、下载、文稿等常用目录。

## Development

Open the project with Xcode:

```bash
open CreateFile.xcodeproj
```

Build the Debug version:

```bash
xcodebuild -project CreateFile.xcodeproj -scheme CreateFile -configuration Debug build
```

Run the built app once so macOS can discover the Finder extension:

```bash
open ~/Library/Developer/Xcode/DerivedData/CreateFile-bmbxpodulmdpcbbggsenllbfqixi/Build/Products/Debug/CreateFile.app
```

Restart Finder to reload the extension during development:

```bash
killall Finder
```

## Download

An early unsigned release package is available in the repository:

```text
Releases/CreateFile-v1.0.0.zip
```

This build is not notarized. After unzipping, move `CreateFile.app` to `/Applications`, right-click it and choose `Open`, then enable the Finder extension in System Settings. See `Releases/INSTALL.txt` for detailed steps.

System requirement: macOS 26.4 or later.

## Templates

Office files are created by copying blank templates bundled with the Finder extension:

```text
CreateFileFinderExtension/Templates/Blank.docx
CreateFileFinderExtension/Templates/Blank.pptx
CreateFileFinderExtension/Templates/Blank.xlsx
```

These templates are part of the app resources and should be included in the `CreateFileFinderExtension` target.

## Notes

This project is currently intended for local development and personal use. If you want to distribute it, you may need to configure code signing, sandboxing, notarization, and App Store metadata.

## License

This project is licensed under the MIT License.
