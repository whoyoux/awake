#!/bin/zsh
# Builds a Developer ID signed, notarized and stapled Awake.zip for a GitHub
# release. It does not publish anything; it prints the `gh release` command.
#
# One-time setup (done by the owner, never in chat):
#   1. Xcode > Settings > Accounts > Manage Certificates > + >
#      "Developer ID Application".
#   2. Store notarization credentials in the keychain (app-specific password
#      from account.apple.com):
#        xcrun notarytool store-credentials awake-notary \
#          --apple-id <apple id> --team-id 73SQTP34GN
#
# Usage: scripts/release.sh            (run from the repo root)
#        NOTARY_PROFILE=other scripts/release.sh
set -euo pipefail

cd "${0:A:h}/.."
PROFILE="${NOTARY_PROFILE:-awake-notary}"
OUT=build/release
VERSION=$(xcodebuild -project Awake.xcodeproj -scheme Awake -configuration Release \
    -showBuildSettings 2>/dev/null | awk '$1 == "MARKETING_VERSION" { print $3 }')
ZIP="$OUT/Awake-$VERSION.zip"

rm -rf "$OUT"
mkdir -p "$OUT"

echo "==> Archiving Awake $VERSION"
xcodebuild -project Awake.xcodeproj -scheme Awake -configuration Release \
    -destination generic/platform=macOS -archivePath "$OUT/Awake.xcarchive" \
    -allowProvisioningUpdates archive -quiet

echo "==> Exporting with Developer ID"
xcodebuild -exportArchive -archivePath "$OUT/Awake.xcarchive" \
    -exportOptionsPlist scripts/ExportOptions.plist -exportPath "$OUT/export" \
    -allowProvisioningUpdates -quiet
APP="$OUT/export/Awake.app"
codesign --verify --strict --deep "$APP"

echo "==> Notarizing (this can take a few minutes)"
ditto -c -k --keepParent "$APP" "$OUT/Awake-unstapled.zip"
xcrun notarytool submit "$OUT/Awake-unstapled.zip" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
spctl --assess --type execute --verbose=2 "$APP"

# Zip again so the download carries the stapled ticket and opens offline.
ditto -c -k --keepParent "$APP" "$ZIP"
rm "$OUT/Awake-unstapled.zip"

echo
echo "==> Ready: $ZIP"
shasum -a 256 "$ZIP"
echo
echo "To publish (public!):"
echo "  gh release create v$VERSION $ZIP --title \"Awake $VERSION\" --generate-notes"
