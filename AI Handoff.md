# PraxPress AI Handoff (macOS / Xcode)

## Scope worked
- `PDFPageOverlayView`
- `PageItem`
- `MergedPage`
- (renaming in document model: `pageSections` -> `mergedPages`)

---

## ✅ Implemented / confirmed behavior

### Overlay + guides
1. Added width guide candidates:
   - `guideXWidthFromLeft`
   - `guideXWidthFromRight`
2. Width-candidate positions are based on:
   - guide page width, and
   - current pageItem trims.
3. Overlay rendering changed to dim **outside** `currentRect` (spotlight effect).
4. If `prax.selectedPageItem != pageItem`:
   - do **not** draw handles or guide lines,
   - use stronger outside mask opacity.

### Handles
- Edge handles now run along full edges (not just center points), with corner-handle priority in hit testing.

### Snapping
- Drag snapping now includes:
   - primary left/right guides
   - width guides (`guideXWidthFromLeft`, `guideXWidthFromRight`)

### Rule-based click behavior
- Tie-breaks:
  - left vs right equal distance -> **left**
  - top vs bottom equal distance -> **top**

- Rules implemented:
  1. If left/right trims are both zero: first click snaps to nearest primary left/right guide.
  2. If one side exactly matches guide trim: next click snaps opposite primary guide.
  3. If one side set to non-guide value: next click snaps to nearest width guide.
  4. If left+right are set and top/bottom include zeros:
     - both zero -> set nearest (tie top),
     - one zero -> set that one.
  5. Rules are state-based (not one-shot).
  6. If all four trims are non-zero:
     - single-click does **not** guide-snap (acts like no guide page),
     - drag-snapping still active.

### Undo/redo overlay updates
- `PageItem.trims` posts notification (`.praxPageItemTrimsChanged`).
- Overlay listens and refreshes rect display.
- `overlayView` is cached per `PageItem` (single instance), not recreated each access.

---

## ✅ Structural refactor completed
- `MergedPage` initialized with `prax` (not document).
- `PageItem` initialized with `prax` directly.
- `PageItem.overlayView` cached with backing storage:
  - `@ObservationIgnored private var _overlayView: PDFPageOverlayView?`

---

## ⚠️ Important current setting
- Trim quantization currently uses:
  - `trimQuantizationScale = 1.0`
  - => integer trim values.
- If 2 decimal precision is desired, set scale to `100.0`.

---

## 🔍 Suggested next checks / TODO
1. Confirm ownership/lifetime model:
   - decide `unowned` vs `weak` for long-lived graph references.
2. Ensure async refresh coalescing (if rapid updates are dropping refresh requests).
3. Validate moving a `PageItem` between different `MergedPage`s updates both old/new pages correctly.
4. Optional polish:
   - visual indicator for actively snapped guide during drag.

---

## Quick manual regression checklist
- [ ] Rule 1/2/3 click flow works from zero trims.
- [ ] Rule 4 top/bottom completion works with tie-to-top.
- [ ] Rule 6 disables click-snapping only when all 4 trims are set.
- [ ] Drag snap hits primary + width guides.
- [ ] Non-selected overlay hides guides/handles and shows stronger outside mask.
- [ ] Undo/redo of trims updates overlay immediately.