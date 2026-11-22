# SethWriter

A simple word processor for Windows 11 that looks and feels like the classic desktop word processors, with only the features you actually use.

## Download

**[Download SethWriter.exe](https://github.com/StickmanNinja/SethWriter/releases/latest/download/SethWriter.exe)** (about 210 KB)

1. Open the downloaded `SethWriter.exe`.
2. Windows may show **"Windows protected your PC"** because the app isn't code-signed. Choose **More info**, then **Run anyway**.
3. SethWriter installs itself for your Windows account (no admin rights needed), adds a **Start menu** shortcut and a **Desktop** shortcut, and opens.

You can delete the downloaded file afterwards. To pin SethWriter to the taskbar, right-click it in the Start menu and choose **Pin to taskbar**.

## What it does

- **Home:** fonts and sizes, bold, italic, underline, strikethrough, subscript and superscript, text and highlight colors, bullets, numbering, indents, alignment, line spacing, and the Normal, Title, Heading 1, Heading 2 and Quote styles. Cut, copy, and find and replace.
- **Insert:** tables, pictures, links, horizontal lines, today's date and symbols.
- **Layout:** margins, portrait or landscape, and Letter, Legal or A4 page sizes.
- **View:** zoom, ruler, page boundaries, word count and **Focus Mode**.
- **File:** new documents (blank, letter, or the welcome guide), recent documents, open `.txt` and `.html` files, and download as `.html` or `.txt`.
- Your work saves automatically as you type, with full undo and redo.

### Focus Mode

Press **F11** or choose **View › Focus Mode**. SethWriter goes full screen with green text on a black background and hides everything except your words. A small word and page count sits in the corner. Press **Esc** to return.

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
| Focus Mode | F11 |

## Where your documents are kept

Documents are saved on your PC in `%LOCALAPPDATA%\Programs\SethWriter\Profile`. Use **File › Download** to keep a copy anywhere else or to move a document to another computer.

## How it works

`SethWriter.exe` is a small launcher. It carries the editor (`app/SethWriter.html`) inside it, copies itself to `%LOCALAPPDATA%\Programs\SethWriter`, and opens the editor in its own Microsoft Edge app window. Edge comes with Windows 11, so there's nothing else to install. The editor works offline; the extra document fonts load from Google Fonts when you're online and fall back to similar Windows fonts when you're not.

## Uninstall

Run this in PowerShell. It removes SethWriter, its shortcuts and the documents saved in it, so download anything you want to keep first.

```powershell
& "$env:LOCALAPPDATA\Programs\SethWriter\SethWriter.exe" --uninstall
```

## Build it yourself

Uses the C# compiler that comes with Windows; nothing to install.

```powershell
.\build.ps1
```

`tools\make-icon.ps1` redraws `assets\icon.ico` if you change the icon design.
