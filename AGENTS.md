# Repository Guidelines

## Project Structure & Module Organization
- `NM_View/` is the macOS app (Xcode project `NM_View.xcodeproj`).
  - `NM_View/App/` app entry, `NM_View/View/` UI, `NM_View/View/ViewModel/` view models.
  - `NM_View/Assets.xcassets/` app assets.
- `nmcore/` is the Swift package that runs `/usr/bin/nm` and provides search helpers.
- `NM_View/TextEditor/` and `NM_View/LocalShortcuts/` are Swift packages used by the app.

## Build, Test, and Development Commands
- Run the app:
  - Open `NM_View/NM_View.xcodeproj` in Xcode and Run.
- Swift package tests (editor package):
  - `cd NM_View/TextEditor && swift test`

## Coding Style & Naming Conventions
- Swift: follow standard Xcode formatting (4 spaces, type names in `UpperCamelCase`, methods/vars in `lowerCamelCase`).
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
- The `nmcore` package shells out to `/usr/bin/nm`; this requires **App Sandbox disabled** or user-granted file access.
