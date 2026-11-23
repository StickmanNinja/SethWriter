# Writer

A simple word processor for Windows and Mac that looks and feels like the classic desktop word processors, with only the features you actually use.

## Download

| | |
| --- | --- |
| **Windows** | **[Download Writer-Setup.exe](https://github.com/StickmanNinja/SethWriter/releases/latest/download/Writer-Setup.exe)** (about 230 KB). Windows 7 SP1, 8, 8.1, 10 and 11. |
| **Mac** | **[Download Writer.dmg](https://github.com/StickmanNinja/SethWriter/releases/latest/download/Writer.dmg)** (about 350 KB). macOS 13 Ventura or later, Apple Silicon or Intel. |

### Windows

1. Open the downloaded `Writer-Setup.exe`.
2. Windows may show **"Windows protected your PC"** because the app isn't code-signed. Choose **More info**, then **Run anyway**.
3. Writer installs itself for your Windows account (no admin rights needed), adds a **Start menu** shortcut and a **Desktop** shortcut, lists itself in **Apps & features**, and opens.

You can delete the downloaded file afterwards. To pin Writer to the taskbar, right-click it in the Start menu and choose **Pin to taskbar**.

Writer opens in its own Microsoft Edge app window. On older Windows without Edge it uses Google Chrome, and without either it opens in your default browser. Windows 7 needs .NET Framework 4, which Windows Update installs; Windows 8 and later already have it.

### Mac

1. Open `Writer.dmg` and drag **Writer** onto **Applications**.
2. The first time you open it, macOS may say it can't check Writer for malicious software, because the app isn't notarized by Apple. Choose **Done**, then open **System Settings › Privacy & Security**, scroll down and choose **Open Anyway**.

## What it does

- **Home:** fonts and sizes, bold, italic, underline, strikethrough, subscript and superscript, text and highlight colors, bullets, numbering, indents, alignment, line spacing, and the Normal, Title, Heading 1, Heading 2 and Quote styles. Cut, copy, and find and replace.
- **Insert:** tables, pictures, links, horizontal lines, today's date and symbols.
- **Layout:** margins, portrait or landscape, and Letter, Legal or A4 page sizes.
- **View:** zoom, ruler, page boundaries, word count and **Focus Mode**.
- **File:** new documents (blank, letter, or the welcome guide), recent documents, open `.txt` and `.html` files, and save a copy as a **Word document (.docx)**, PDF, web page or plain text.
- **Print:** Ctrl+P (⌘P on a Mac), the printer button at the top, or **File › Print**. Pages print at the size and margins set on the Layout tab, with just your document on them.
- Your work saves automatically as you type, with full undo and redo.

### Focus Mode

Press **F11** or choose **View › Focus Mode**. Writer goes full screen with green text on a black background and hides everything except your words. A small word and page count sits in the corner. Press **Esc** to return.

### Keyboard shortcuts

| Action | Shortcut |
| --- | --- |
| Bold, italic, underline | Ctrl+B, Ctrl+I, Ctrl+U |
| Undo, redo | Ctrl+Z, Ctrl+Y |
| Find, replace | Ctrl+F, Ctrl+H |
| Insert link | Ctrl+K |
| Align left, center, right, justify | Ctrl+L, Ctrl+E, Ctrl+R, Ctrl+J |
| Bigger or smaller text | Ctrl+], Ctrl+[ |
| Save now | Ctrl+S |
| Print | Ctrl+P |
| Focus Mode | F11 |

## Where your documents are kept

- **Windows:** in `%LOCALAPPDATA%\Programs\Writer\Profile`.
- **Mac:** inside the app's storage, in `~/Library/WebKit/com.stickmanninja.sethwriter`.

Use **File › Download** to keep a copy anywhere else or to move a document to another computer. Documents saved by SethWriter (Writer's old name) move over to Writer on its first run.

## Uninstall

- **Windows:** open **Apps & features** (Windows 10/11) or **Programs and Features** (Windows 7/8), choose **Writer**, then **Uninstall**.
- **Mac:** drag **Writer** from Applications to the Trash.

Uninstalling on Windows removes the documents saved in Writer, so download anything you want to keep first.

## How it works

The editor is one web page, `app/Writer.html`, shared by both versions. It works offline; the extra document fonts load from Google Fonts when you're online and fall back to similar system fonts when you're not.

- **Windows:** `Writer-Setup.exe` is a small installer and launcher in one (`launcher/Program.cs`). It carries the editor inside it, copies itself to `%LOCALAPPDATA%\Programs\Writer`, and opens the editor in its own Edge (or Chrome) app window.
- **Mac:** `Writer.app` is a small Swift app (`mac/main.swift`) that shows the editor in a WebKit window, with the Mac menu bar, ⌘ shortcuts, Print (⌘P), and Focus Mode on ⌃⌘F. Its build changes the Windows wording (Ctrl, F11, "this browser") to Mac wording in the copy of the editor it packs.

## Build it yourself

**Windows**, with the C# compiler that comes with Windows (nothing to install):

```powershell
.\build.ps1        # builds build\Writer-Setup.exe
```

**Mac**, with the Swift compiler from Apple's Command Line Tools (`xcode-select --install` if you don't have them):

```bash
./build-mac.sh            # builds build/Writer.app
./build-mac.sh --install  # builds it and copies it into /Applications
./build-mac.sh --dmg      # builds build/Writer.dmg
```

`tools/make-icon.swift` (run on a Mac) draws the icon for both: `--mac` for the Mac app and `--ico assets/icon.ico` for Windows.

## Releases

GitHub Actions (`.github/workflows/build.yml`) builds and tests both installers on every pull request. Pushing a version tag such as `v1.2.0` publishes them as a release, which is where the download links above point.
