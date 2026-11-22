#!/bin/bash
# Builds SethWriter.app for macOS with the Swift compiler from Apple's Command Line Tools. Nothing else to install.
#   ./build-mac.sh            build build/SethWriter.app
#   ./build-mac.sh --install  build it and copy it into /Applications (or ~/Applications)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
build="$here/build"
app="$build/SethWriter.app"
version="1.0.0"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

# 1. The editor page, wrapped in a full HTML document (same wrapper as build.ps1), with Mac wording:
#    Ctrl+ shortcuts become ⌘, Focus Mode is ⌃⌘F, and documents live "in SethWriter" rather than "in this browser".
#    The last line hands a few editor actions to the Mac menu bar as window.sethwriter.
{
  printf '%s' '<!doctype html><html lang="en"><head><meta charset="utf-8">'
  printf '%s' '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
  printf '%s\n' '<style>:root{color-scheme:light}body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style></head><body>'
  sed -e 's/Ctrl+/⌘/g' \
      -e 's/a simple word processor that runs in your browser\. Everything you type is saved automatically to this browser, so you can close the tab and/a simple word processor for your Mac. Everything you type is saved automatically, so you can quit and/' \
      -e 's/(F11)/(⌃⌘F)/g' \
      -e 's/ to this browser//g' \
      -e 's/Recent documents in this browser/Recent documents/' \
      -e 's/browser storage is full/storage is full/g' \
      -e 's/^})();$/window.sethwriter = { undo, redo, saveNow, toast, openBackstage, toggleFocus: () => setFocus(!inFocus()) }; })();/' \
      "$here/app/SethWriter.html"
  printf '\n%s\n' '</body></html>'
} > "$app/Contents/Resources/SethWriter.html"

# 2. The app itself
swiftc -O -swift-version 5 -target arm64-apple-macos13 -o "$build/SethWriter-arm64" "$here/mac/main.swift"
swiftc -O -swift-version 5 -target x86_64-apple-macos13 -o "$build/SethWriter-x86_64" "$here/mac/main.swift"
lipo -create "$build/SethWriter-arm64" "$build/SethWriter-x86_64" -output "$app/Contents/MacOS/SethWriter"
rm "$build/SethWriter-arm64" "$build/SethWriter-x86_64"

# 3. Icon
iconset="$build/SethWriter.iconset"; rm -rf "$iconset"; mkdir -p "$iconset"
swift "$here/mac/make-icon.swift" "$build/icon-1024.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$build/icon-1024.png" --out "$iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$build/icon-1024.png" --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/SethWriter.icns"
rm -rf "$iconset" "$build/icon-1024.png"

# 4. Info.plist
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>SethWriter</string>
  <key>CFBundleDisplayName</key><string>SethWriter</string>
  <key>CFBundleIdentifier</key><string>com.stickmanninja.sethwriter</string>
  <key>CFBundleExecutable</key><string>SethWriter</string>
  <key>CFBundleIconFile</key><string>SethWriter</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$version</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHumanReadableCopyright</key><string>A simple word processor.</string>
</dict></plist>
PLIST

# 5. Ad-hoc signature so macOS will run it on this Mac
codesign --force --deep --sign - "$app"
echo "Built $app"

if [[ "${1:-}" == "--install" ]]; then
  dest="/Applications"; [[ -w "$dest" ]] || { dest="$HOME/Applications"; mkdir -p "$dest"; }
  rm -rf "$dest/SethWriter.app"
  cp -R "$app" "$dest/"
  echo "Installed $dest/SethWriter.app"
fi
