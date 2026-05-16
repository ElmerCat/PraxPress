
# PraxPress Architecture Notes

## Project Overview
PraxPress is a macOS SwiftUI app for importing, inspecting, merging, and exporting PDF content.  
Core image-drop behavior supports pre-processing images before conversion to PDF pages.

## Core Architecture
- **App-level view model:** `PraxModel` (`@Observable`)
- **Document model:** `MergedPDFDocument`
- **Drop handling:** `PraxDropDelegate`
- **Image preprocessing UI:** `ImageInspectingPopover`

### Design conventions
1. `PraxModel` holds app-wide bindable settings/state.
2. Settings should be **non-optional with defaults** unless strongly justified.
3. Prefer explicit option structs for import pipelines.
4. Non-trivial implementation choices should be proposed as options (A/B/C) before coding.

## Key Flows

### 1) File/Image Drop Flow
1. `DropTargetControl.onDrop(...)` delegates to `PraxDropDelegate`.
2. `PraxDropDelegate.performDrop(info:)` extracts URLs and calls:
   - `prax.receiveDroppedURL(...)`.
3. `PraxModel.receiveDroppedURL(...)` routes by extension:
   - PDF -> `document.addPagesFromPDFURL(...)`
   - image -> either:
     - open `ImageInspectingPopover` (if `inspectNextImageDrop`)
     - direct import via `addPageFromImageURL(...)`

### 2) Image Import Processing Flow
Main methods in `PraxModel`:
- `addPageFromImageURL(_:at:title:options:)`
- `processedImageFromURL(_:options:)`
- `processedImage(_:options:)`
- helpers:
  - `cropRect(for:options:)`
  - `applyAdjustments(to:options:)`
  - sizing helpers (`file size limit` and `target inches`)

Pipeline order:
1. load image
2. crop
3. apply adjustments (brightness/contrast/exposure/sharpness)
4. resize according to sizing strategy
5. convert to `PDFPage`
6. insert as `PageItem`

## Import Settings

### Current settings container
- `PraxModel.importImageOptions` (global defaults for image import)
- `PraxModel.ImageImportOptions` includes:
  - crop: left/right/top/bottom
  - scaleDown
  - brightness/contrast/exposure/sharpness
  - sizing mode:
    - `fileSizeLimit` (KB)
    - `targetInches` (width/height)

### Sizing intent
- **File-size mode:** downscale as needed to meet KB target.
- **Target-inches mode:** scale up/down to match requested PDF dimensions (aspect-preserving fit).

## UI Components Relevant to Import
- `ImageInspectingPopover`
  - preview + controls
  - imports via chosen options
  - shows metrics:
    - source px
    - output px
    - output PDF inches
    - estimated PDF KB
- `DropTargetControl`
  - drop zone UI + popover presentation

## Current Technical Priorities
1. Keep import option handling consistent (non-optional defaults).
2. Ensure processing uses explicit effective options (stable snapshot per import).
3. Improve UI/UX polish for sizing modes and validation messaging.
4. Run full codebase audit for crash risk/threading/performance/maintainability.

## Coding/Review Preferences
- Do not assume minimal patching is preferred.
- If multiple valid approaches exist, present options + trade-offs first.
- For approved path, provide compile-ready code and verification checklist.

## Suggested Audit Focus
- Force unwraps / crash paths
- Main-thread mutations for UI-observed state
- Security-scoped URL lifecycle correctness
- Image processing performance (preview recalculation, repeated PDF size estimation)
- State consistency between global defaults and per-import overrides
- Dead code / stale optional-logic remnants
