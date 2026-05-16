//
//  00_REPO_MAP.md
//  PraxPress
//
//  Created by Elmer Cat on 5/15/26.
//

# 00_REPO_MAP.md

## Purpose
This file is a neutral map of the PraxPress repository to support full-codebase audits.
It is not a design spec and should not be treated as exhaustive architectural guidance.

## Audit Rule
Treat source code as authoritative.
If this file conflicts with code, prefer code.

## Repository Inventory (fill/update as needed)

### Top-level
- `PraxPress.xcodeproj` — Xcode project
- `PraxPress/` — app source
- `info.plist` — project properties
- `00_REPO_MAP.md` — this file
- `AI Handoff.MD` — handoff to agent information

### App source (`PraxPress/`)
- `Application/` — controller-style integration points (if present)
- `Models/` — app/domain/view models (state, business logic)
- `Views/` — SwiftUI views
- `Resources/` — icons, assets, and bundled files

> Note: Folder names may differ; update this map to match the repository exactly.

## Key Entry Points (update with actual file paths)
- App entry: `.../PraxPressApp.swift`
- Main app-level state model: `.../PraxModel.swift`
- Main document model: `.../MergedPDFDocument.swift`
- Main drop/import routing: `.../PraxDropDelegate.swift`
- Primary navigation/root view: `.../MainSceneRoot.swift`
- Primary content/root view: `.../ContentView.swift`

## Build / Test Commands (example)
- Build (Xcode): Product → Build
- Test (Xcode): Product → Test
- CLI build (if used): `xcodebuild ...`
- CLI test (if used): `xcodebuild test ...`

## Generated / External / Ignore Paths
Exclude from deep audit unless directly relevant:
- `DerivedData/`
- `.git/`
- build artifacts (`.build/`, `build/`)
- third-party generated code/vendor folders (list actual paths if present)

## Audit Coverage Checklist
Use this checklist to ensure full-repo coverage.

- [ ] App entry and lifecycle
- [ ] Global state/view models
- [ ] Document/persistence layer
- [ ] Import/export pipelines
- [ ] All major SwiftUI views
- [ ] Delegate/coordinator logic
- [ ] Utilities/extensions
- [ ] Tests (unit + UI) structure and gaps
- [ ] Error handling + user-facing failure paths
- [ ] Performance-sensitive paths
- [ ] Security/privacy-sensitive paths
- [ ] Concurrency/thread-safety

## Notes
- This map should stay concise and neutral.
- Do not include feature recommendations here.
- Keep this file updated when modules/folders are renamed.
