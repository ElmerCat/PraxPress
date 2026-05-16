---

# PraxPress AI Handoff (Image Import & Preprocessing)

## Project
**PraxPress** (macOS SwiftUI app)

## Current Objective
Run a full codebase audit for stability, safety, architecture consistency, and maintainability before adding further UI/functionality.

---

## Architecture Snapshot

- `PraxModel` is the app-level `@Observable` view model.
- `PraxDropDelegate` handles dropped content and routes files into import pipelines.
- `ImageInspectingPopover` is used for pre-processing image drops before conversion to PDF.
- `MergedPDFDocument` handles document/page insertion and PDF merge behavior.

---

## Work Completed in This Conversation

### Image preprocessing features added/planned
1. Crop before resize.
2. Scale adjustment control.
3. Basic adjustments:
   - brightness
   - contrast
   - exposure
   - sharpness
4. Preview in popover.
5. Metrics in UI:
   - original px
   - output px
   - resulting PDF page inches
   - estimated PDF size KB

### Import sizing changes
- Migrated from width/height app storage to file-size mode:
  - `@AppStorage("import-size-limit")`
- Added/working toward mode-based sizing:
  - file size limit
  - target output width/height in inches (including upscaling/downscaling)

### State and defaults direction
- Strong preference: settings should be non-optional and have defaults.
- `PraxModel` now has:
  - `var importImageOptions = ImageImportOptions()`
- `ImageImportOptions` has default values and should remain non-optional across code paths.

---

## Important Current Conventions

1. **No nil-based settings** for import options.
2. `PraxModel` is canonical source of app settings (bindable from views).
3. Use macOS 14+ `onChange` style:
   - `.onChange(of: value) { ... }`
4. `inspectNextImageDrop` path:
   - stores dropped image URL
   - shows inspector
   - import action applies chosen options

---

## Known Cleanup Needed (High Priority)

There are remnants of old optional option logic mixed with new non-optional model design. Clean these first:

- Remove optional-style checks for `sizingMode`, `sizeLimitKB`, target inches.
- Ensure `processedImage(_:)` switches on `options.sizingMode` (not global references or optional fallback).
- Ensure `resolvedImportOptions(_:)` aligns with non-optional options policy.
- Remove outdated helper methods that only support old optional/default-resolution flow, if no longer used.
- Ensure no accidental reference to `prax.importImageOptions` inside `PraxModel` methods where `self`/method `options` should be used.

---

## Files Most Relevant to Audit

1. `PraxModel.swift`
   - `receiveDroppedURL`
   - `addPageFromImageURL`
   - `processedImageFromURL`
   - `processedImage`
   - sizing/cropping/adjustment helpers
2. `PraxDropDelegate.swift`
   - `performDrop`
   - `ImageInspectingPopover`
3. Any model/state persistence files for import settings
4. `MergedPDFDocument.swift` (next pass if needed)

---

## Requested Audit Scope

Please audit for:

- crash risks / force unwrap hazards
- thread-safety & main-thread UI/state mutations
- security-scoped URL handling correctness
- data consistency and state coupling
- optional-vs-default consistency in settings
- performance hotspots (image processing, preview regeneration, PDF size estimation loops)
- maintainability / complexity
- dead code or stale compatibility branches

---

## Required Audit Output Format

1. **Executive Summary**
2. **Top 10 Findings (ranked severity)**
   - Critical / High / Medium / Low
3. For each finding:
   - file + function
   - why it matters
   - trigger/repro condition
   - minimal compile-safe patch
4. **Quick wins** (safe to do immediately)
5. **Refactor candidates** (later)
6. **Suggested tests**

---

## Next Product Features Planned (Post-Audit)

- Better image preprocessing UI polish.
- Expanded sizing controls UX.
- Additional import constraints and quality controls.
- Broader app-level cleanup and consistency improvements.

---

## Notes for the Agent

- Keep fixes incremental and compile-safe.
- Prefer minimal diff patches over rewrites.
- Do not reintroduce nil settings where defaults exist.
- If uncertainty exists, propose two options with trade-offs.

---

---

### Notes for the Agent (Working Style)

1. Do **not** assume minimal patching is preferred.
2. If a broader refactor is clearly better, propose it.
3. When multiple valid approaches exist, present options **before implementing**:
   - Option A / B / C
   - trade-offs (complexity, risk, maintainability, migration cost)
   - recommended choice with rationale
4. Wait for user selection before committing to a direction.
5. For straightforward, low-risk fixes with no architectural ambiguity, proceed directly.
6. Provide compile-ready code once direction is chosen.

---
