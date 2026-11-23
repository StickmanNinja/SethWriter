#!/bin/bash
# Builds Writer.app for macOS with the Swift compiler from Apple's Command Line Tools. Nothing else to install.
#   ./build-mac.sh            build build/Writer.app
#   ./build-mac.sh --install  build it and copy it into /Applications (or ~/Applications)
#   ./build-mac.sh --dmg      build it and pack it into build/Writer.dmg, the download for other Macs
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
build="$here/build"
app="$build/Writer.app"
version="1.2.0"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

# 1. The editor page, wrapped in a full HTML document (same wrapper as build.ps1), with Mac wording:
#    Ctrl+ shortcuts become ⌘, Focus Mode is ⌃⌘F, and documents live "in Writer" rather than "in this browser".
#    The last line hands a few editor actions to the Mac menu bar as window.writer.
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
      -e 's/^})();$/window.writer = { undo, redo, saveNow, toast, openBackstage, print: printDoc, toggleFocus: () => setFocus(!inFocus()) }; })();/' \
      "$here/app/Writer.html"
  printf '\n%s\n' '</body></html>'
} > "$app/Contents/Resources/Writer.html"

# 2. The app itself
swiftc -O -swift-version 5 -target arm64-apple-macos13 -o "$build/Writer-arm64" "$here/mac/main.swift"
swiftc -O -swift-version 5 -target x86_64-apple-macos13 -o "$build/Writer-x86_64" "$here/mac/main.swift"
lipo -create "$build/Writer-arm64" "$build/Writer-x86_64" -output "$app/Contents/MacOS/Writer"
rm "$build/Writer-arm64" "$build/Writer-x86_64"

# 3. Icon
iconset="$build/Writer.iconset"; rm -rf "$iconset"; mkdir -p "$iconset"
swift "$here/tools/make-icon.swift" --mac "$build/icon-1024.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$build/icon-1024.png" --out "$iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$build/icon-1024.png" --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/Writer.icns"
rm -rf "$iconset" "$build/icon-1024.png"

# 4. Info.plist. The bundle identifier keeps the app's first name (SethWriter) on purpose: documents are stored
#    under it, so changing it would leave earlier documents behind.
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Writer</string>
  <key>CFBundleDisplayName</key><string>Writer</string>
  <key>CFBundleIdentifier</key><string>com.stickmanninja.sethwriter</string>
  <key>CFBundleExecutable</key><string>Writer</string>
  <key>CFBundleIconFile</key><string>Writer</string>
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
  pkill -x SethWriter 2>/dev/null || true; pkill -x Writer 2>/dev/null || true
  rm -rf "$dest/Writer.app" "$dest/SethWriter.app"   # SethWriter.app is this app under its old name
  cp -R "$app" "$dest/"
  echo "Installed $dest/Writer.app"
fi

if [[ "${1:-}" == "--dmg" ]]; then
  # A disk image with Writer.app and a shortcut to Applications, so people drag one onto the other.
  stage="$build/dmg"; rm -rf "$stage" "$build/Writer.dmg"; mkdir -p "$stage"
  cp -R "$app" "$stage/"
  ln -s /Applications "$stage/Applications"
  hdiutil create -volname "Writer" -srcfolder "$stage" -fs HFS+ -format UDZO -imagekey zlib-level=9 -ov "$build/Writer.dmg" >/dev/null
  rm -rf "$stage"
  echo "Built $build/Writer.dmg"
fi
