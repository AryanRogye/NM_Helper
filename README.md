# NM Helper

## Requirements
- macOS
- Xcode (SwiftUI app, `lipo`, `ditto`, SDKs)
- Xcode Command Line Tools (`xcode-select --install`)
- Go 1.21+ (for `NM_Core`)
- Bash (for build scripts)

## Optional
- Homebrew (easy Go install/updates)

## Build Overview
- SwiftUI app lives in `NM_View/`
- Go core lives in `NM_Core/`
- Universal static lib + header are built by `scripts/build-universal.sh`

## Build (core only)
```bash
cd NM_Core
go build -buildmode=c-archive -o libnm_core.a .
```

## Build (universal)
```bash
./scripts/build-universal.sh
```

The script outputs:
- `build/go-universal/libnm_core.a` (or `$(TARGET_BUILD_DIR)/go-universal` when run from Xcode)
- `build/go-universal/libnm_core.h`
