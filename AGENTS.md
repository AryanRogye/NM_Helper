# Repository Guidelines

## Project Structure & Module Organization
- `NM_View/` is the macOS app (Xcode project `NM_View.xcodeproj`).
  - `NM_View/App/` app entry, `NM_View/View/` UI, `NM_View/View/ViewModel/` view models.
  - `NM_View/Assets.xcassets/` app assets.
  - `NM_View/CoreNative/` receives the generated Go static lib + header for linking.
- `NM_Core/` is the Go core (c-archive exports).
- `scripts/` contains build helpers (notably `build-universal.sh`).
- `NM_View/TextEditor/` and `NM_View/LocalShortcuts/` are Swift packages used by the app.

## Build, Test, and Development Commands
- Build Go core (local, single arch):
  - `cd NM_Core && go build -buildmode=c-archive -o libnm_core.a .`
- Build Go core (universal, arm64 + amd64):
  - `./scripts/build-universal.sh`
  - Outputs to `build/go-universal/` (or `$(TARGET_BUILD_DIR)/go-universal` when run by Xcode).
- Run the app:
  - Open `NM_View/NM_View.xcodeproj` in Xcode and Run.
- Swift package tests (editor package):
  - `cd NM_View/TextEditor && swift test`

## Coding Style & Naming Conventions
- Swift: follow standard Xcode formatting (4 spaces, type names in `UpperCamelCase`, methods/vars in `lowerCamelCase`).
- Go: use `gofmt`; keep cgo exports with `//export name` directly above the function, and use C types (`*C.char`, `C.int`).
- Files are grouped by feature (e.g., `View/Components`, `ViewModel`).
- Prefer clean, readable code.
- ViewModels: structure with `// MARK:` sections and extensions that tell a clear story.
- Views: keep `var body: some View` small and concise; push subviews into `private var` blocks.
- When adding new Swift files, ensure they are included in the Xcode target (Target Membership).

## Testing Guidelines
- No app-level test suite is currently configured.
- Swift package tests live under `NM_View/TextEditor/Tests`.
- Name test types `*Tests` and use `swift test` from the package root.

## Commit & Pull Request Guidelines
- This repo does not include git history, so no commit convention is enforced.
- Suggested convention: short, imperative subject (e.g., “Add URL save toolbar action”).
- PRs (or large changes) should include:
  - Summary of behavior change
  - Steps to verify
  - UI screenshots for visual changes

## Security & Configuration Notes
- The Go core shells out to `/usr/bin/nm`; this requires **App Sandbox disabled** or user-granted file access.
- When exporting new C functions from Go, rebuild the core so `libnm_core.h` updates.
