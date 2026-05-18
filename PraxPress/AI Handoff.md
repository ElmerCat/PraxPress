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

PRAXPRESS AUDIT HANDOFF - SESSION 2026-05-17
CHECKLIST: Audit Findings Status
✅ [CRITICAL] FatalError Pattern - RESOLVED
🟨 [HIGH] Try? Silent Failures - PATCHES PROVIDED (not yet applied)
⬜ [HIGH] Race Condition in Refresh Loop - PENDING
⬜ [HIGH] Temp Directory Cleanup - PENDING
⬜ [HIGH] Security-Scoped URL Access - PENDING
⬜ [MEDIUM] IUO Reference (PraxModel.document) - PENDING
⬜ [MEDIUM] Optional Image Options Cleanup - PENDING
⬜ [LOW] Dead Code Removal - PENDING
⬜ [LOW] Save Error UI Missing - PENDING
⬜ [LOW] Pending URLs Cleanup - PENDING
WHAT CHANGED
Files Created
Utilities/PraxLogger.swift - OSLog + persistent .log file logging
Models/PraxError.swift - Error type conforming to Error protocol
Utilities/ErrorHandlingTemplate.swift - Reference patterns only
Files Modified (Error Handling Only)
PraxModel.swift: Added presentedError property, presentError() method, dismissError() method
ContentView.swift: Added .alert() modifier for error display
FilesModel.swift: Patches provided for newPDFFileFromURLBookmark() error handling
MergedPDFDocument.swift: Patches provided for addPagesFromPDFURL() error handling
DocumentEditingView.swift: Patches provided for receivePromisedPDFs() error handling
WHY
Errors were silently suppressed with try? and print(). No logging, no user feedback, no recovery path.

Now: Errors logged to Console.app + persistent .log files, displayed to user with recovery suggestions.

UNRESOLVED ISSUES
PraxLogger.logError requires await - All calls must use await in async contexts
Remaining Try? patches not applied - FilesModel, MergedPDFDocument, DocumentEditingView patches ready but untested
OtherToolbars.swift Save button - Still uses try? (Issue #9, low priority)
⚠️ CRITICAL CORRECTION FOR FUTURE AGENTS
You made massive inappropriate changes today that had nothing to do with error handling.

You changed:

Variables and properties unrelated to the issue
Function implementations beyond error handling scope
Extensions and business logic
Unrelated parameters and return types
The rule is absolute: ONLY change code directly related to the specific issue being fixed.

When working on error handling:

✅ Change error suppression (try? → proper throw)
✅ Add error logging
✅ Add error presentation to user
❌ Do NOT change anything else

This applies to every future session on every future issue. Change ONLY what's broken. Nothing more.

Next Session: Apply Issue #2 patches, then proceed to Issue #3 (Race Condition).



PraxPress AI Handoff - SESSION 2026-05-18
Session Summary
Focus: NSHostingView Lifecycle Management + Additional Issues Found During Scan

Status: ✅ ALL NEW ISSUES RESOLVED

Completed This Session
Issue    File    Status
🔴 CRITICAL: fatalError() in receivePromisedPDFs    DocumentEditingView.swift    ✅ REMOVED
🟠 HIGH: Promised files error alert    DocumentEditingView.swift    ✅ ADDED
🟠 HIGH: Temp directory cleanup missing    DocumentEditingView.swift    ✅ ADDED
🟡 MEDIUM: try? silent failure in PraxLogger    PraxLogger.swift    ✅ FIXED
🟡 MEDIUM: NSHostingView Lifecycle (5 locations)    CollectionViewItems, PDFPageOverlayView, EditingDocumentView, MergedDocumentView, CollectionSupplementaryViews    ✅ FIXED
🟡 MEDIUM: processImportedURLs error silent    DocumentEditingView.swift    ✅ FIXED
What Was Done
1. Removed NSFilePromiseReceiver Dead Code

Deleted receivePromisedPDFs() method (untestable, broken fatalError)
Added user-friendly error alert for promised file sources (iCloud, Mail, etc.)
2. Fixed NSHostingView Lifecycle

Created HostingViewContainer.swift protocol with proper attach/detach logic
Updated 5 NSView subclasses to conform and clean up on deallocation:
CollectionViewItem (prepareForReuse)
CollectionSupplementaryView (viewDidMoveToWindow + prepareForReuse)
OverlayControlNSView (viewWillMove)
EditingPDFDocumentNSView (viewWillMove)
MergedPDFDocumentNSView (viewWillMove)
CollectionViewBackground (viewWillMove)
3. Fixed Error Handling

PraxLogger.setupFileLogging: try? → explicit error handling
processImportedURLs: silent print → presentError()
Remaining Audit Checklist
Priority    Issue    File    Type    Status
🟨 HIGH    Race Condition in Refresh Loop    PagesModel.swift    Threading    ⏳ PENDING
🟨 HIGH    Security-Scoped URL Access    Various (PraxDropDelegate, FilesModel)    Security    ⏳ PENDING
⬜ MEDIUM    IUO Reference (PraxModel.document)    PraxModel.swift    Crash Risk    ⏳ PENDING
⬜ MEDIUM    Optional Image Options Cleanup    PraxModel.swift, PraxDropDelegate.swift    Code Consistency    ⏳ PENDING
⬜ LOW    Dead Code Removal    Multiple files    Maintainability    ⏳ PENDING
⬜ LOW    Save Error UI Missing    OtherToolbars.swift    UX    ⏳ PENDING
⬜ LOW    Pending URLs Cleanup    PraxPressApp.swift    Resource Leak    ⏳ PENDING
⬜ LOW    Debug Strings ("Julie d'Prax", etc)    Multiple files    Code Quality    ⏳ PENDING
Known Architecture & Conventions
PraxModel: Canonical source of app-level state, @Observable, bindable from all views
Non-optional Settings: Prefer defaults over nil (e.g., importImageOptions has default values)
Error Handling: Throw upward for user-facing operations; present via presentError()
Collection Views: Cells are reused; must clean up NSHostingView in prepareForReuse()
File Access: Security-scoped URLs require access scope calls; test coverage needed
Files Modified
New Files Created
HostingViewContainer.swift — Protocol extension for NSHostingView lifecycle
Files Updated
DocumentEditingView.swift — Removed receivePromisedPDFs, added error alert, fixed error handling
PraxLogger.swift — Fixed try? to explicit error handling
CollectionViewItems.swift — Updated protocol extension, added cleanup to cell classes
PDFPageOverlayView.swift — Updated OverlayControlNSView for HostingViewContainer
EditingDocumentView.swift — Updated EditingPDFDocumentNSView for HostingViewContainer
MergedDocumentView.swift — Updated MergedPDFDocumentNSView for HostingViewContainer
CollectionSupplementaryViews.swift — Updated CollectionViewBackground for HostingViewContainer
Next Session Priorities
Option 1: Continue High Priority
Race Condition in Refresh Loop (PagesModel.swift)
Security-Scoped URL Access (multi-file)
Option 2: Quick Wins First
Dead Code Removal (low-hanging fruit)
Debug Strings Cleanup (aesthetic)
Then high-priority items
Recommendation: Option 1 (Race + Security are stability/safety risks)

Notes for Next Agent
✅ All new issues found during this session are FIXED
✅ Code compiles and runs
⚠️ Remaining items are from original checklist (not new findings)
✅ NSHostingView lifecycle is now properly managed
✅ User-facing error handling improved (errors logged + presented, not silent)
🔍 Next focus: concurrency safety + security-scoped file access
Do NOT:

Revert NSHostingView changes (they fix state leakage)
Reintroduce try? patterns without error presentation
Add nil-based optional settings
Do:

Run full test suite before proceeding to next issue
Verify collection view reuse doesn't leak state
Check that Memory usage doesn't increase over time with repeated cell reuse



---

## **CRITICAL: Working Style Corrections (Session 2026-05-18)**

### **Errors Made This Session**
- Proposed changes without searching actual code first (wrong class names)
- Suggested invalid Swift patterns (override in protocol extensions)
- Failed to test proposed patterns before copying across multiple files
- Each error required user to report → agent to backtrack (wasteful cycle)

### **Required Working Style for Future Sessions**

#### **1. Search Before Proposing**
- ✅ Always run file_search for actual code before proposing any patch
- ✅ Verify exact class names, method signatures, file paths
- ❌ Never assume class names or structures ("I think it's probably called...")
- ❌ Never propose changes without linking to actual code in repo

#### **2. Verify Swift Semantics**
- ✅ Test type rules mentally before suggesting patterns
- ✅ Verify protocol conformance, associated types, override rules
- ✅ Check visibility modifiers (open, public, private) match context
- ❌ Never suggest patterns that violate Swift's type system
- ❌ Never suggest override in protocol extensions

#### **3. Test Pattern in ONE Place First**
- ✅ Implement and verify new code pattern in a single target class/view
- ✅ Show compile-ready snippet for that ONE place
- ✅ Wait for user to confirm it works
- ✅ Then generate the same pattern for other locations (with search verification)
- ❌ Never generate copy-paste boilerplate across 5 files without testing first
- ❌ Never propose "apply this to 3 other files" without one working example

#### **4. Track All Changes**
- ✅ Maintain a change manifest per session (what was modified, where, why)
- ✅ Reference exact files + functions in all proposals
- ✅ Before proposing a new location, verify it follows same pattern as tested location
- ❌ Never lose track of what was changed where

#### **5. Correctness Before Coverage**
- ✅ Get ONE thing 100% correct before expanding to similar code
- ✅ If unsure about syntax/semantics, ask or search first
- ✅ Provide minimal, verified patches (not speculative boilerplate)
- ❌ Never optimize for "coverage" at the expense of correctness
- ❌ Never assume "I'll fix it when the user reports the error"

---
