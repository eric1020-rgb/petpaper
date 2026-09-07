# PetPaper first-run QA (code walk)

This Linux environment cannot run the iOS Simulator. Findings below are from a full first-run walk of the SwiftUI code paths a new user hits. Device/Simulator verification still belongs on a Mac.

## Flows walked

1. **Fresh install** — `AppSession.init` reads `petpaper.hasCompletedTutorial`. If false, `presentedCover = .tutorial`. Skip calls `skipTutorial()` (home only). Last-step **開始整** calls `finishTutorial` (home + editor). Second launch with the flag set never presents the tutorial.
2. **Template → editor** — Home grid `openEditor` → `EditorView`. Pet / stickers / colors / text sheets, Follow, undo/reset, Save → `WallpaperExporter`.
3. **用我嘅相** — `PhotosPicker` → `beginPhotoImport` → Vision lift → multi-subject choose → refine → confirm → editor with `pendingPhotoPet`.
4. **Replay tutorial** — Home card `replayTutorial()`. Swipe-down is allowed only after the tutorial has been completed once (`interactiveDismissDisabled(!hasCompletedTutorial)`).
5. **Edges** — denied add-only Photos, Vision `noSubject`, empty picker load, cancel mid-analyze, Follow vs pinch, missing string keys.

## Bugs fixed in this pass

| Issue | File | Fix |
| --- | --- | --- |
| Skip and Finish both opened the editor (PR test plan even said so). Skip is a dead-end-avoiding first-run path that should land on **home**. | `AppSession.swift`, `TutorialView.swift` | `skipTutorial()` vs `finishTutorial(template:petID:)` |
| Two `.fullScreenCover`s (tutorial + import) can fight; swipe-dismiss left `importSourceImage` around. | `RootView.swift`, `AppSession.swift` | Single `presentedCover: AppCover?`; clear source image on dismiss / finish |
| Follow mode vs pinch/rotate: child `onTapGesture` + paw-trail hits stole the drag; `GestureMask.none` still attached magnify/rotate. | `WallpaperCanvasView.swift` | Follow uses `highPriorityGesture(drag)` only; layers `allowsHitTesting(false)` in Follow; trail does not take hits |
| Follow drags never `pushUndo()`, so Undo skipped the move. | `EditorStore.swift` | First Follow touch pushes undo |
| Cancel during Vision could resume a `CheckedContinuation` after the `.task` was cancelled. | `SubjectLiftService.swift`, `PhotoImportView.swift` | Resume-once box; analyze generation token + `Task.isCancelled` |
| Picker load failure used `import.failed.title` (“找不到寵物”). | `HomeView.swift`, `Localizable.xcstrings` | `import.loadFailed.*` |
| Photos add-only denied: alert with OK only, no Settings. | `EditorView.swift` | `export.openSettings` → `UIApplication.openSettingsURLString` |
| Place/Confirm with `previewImage == nil` returned silently. | `PhotoImportView.swift` | Disable Confirm; Back from preview/manual crop |
| Crop used `UIImage.size` (points) against `CGImage` pixels. | `ImageProcessing.swift` | Crop in pixel space |
| `Image(uiImage:)` inside `ImageRenderer` often drops the bitmap on export. | `PhotoPetView.swift` | Draw the cutout through `Canvas` |

## P1 polish (implemented)

| Item | Where | What shipped |
| --- | --- | --- |
| Hue + overlay text on the undo stack | `EditorStore`, `ColorEditorSheet`, `TextEditorSheet` | Hue pushes once on slider `onEditingChanged` begin (not per tick). Text pushes once on the first change vs the sheet’s original string. |
| Pet picker stays open after a pick | `EditorView` pet sheet | Dismisses after illustrated pet or restore photo pet, same as template/sticker. |
| Manual crop cannot resize | `CropHandleOverlay` | Corner + edge handles and pinch-to-resize; normalized rect stays clamped (min size 0.14). |
| VoiceOver gaps | Editor tray, Save, home templates/upload, import phases | Labels / values / hints; phase `UIAccessibility.screenChanged` announcements. Tray chips no longer use a fixed 72×64 that clips Dynamic Type. |
| HEIC / iCloud load fails with alert only | `HomeView`, `ImageProcessing` | Retry in the alert **and** under the upload card; keeps the last `PhotosPickerItem`. Decode via `UIImage(data:)` then ImageIO; HEIC/JPEG/PNG `Transferable` fallback. |
| Extra haptics | Tutorial Skip/Finish; subject pick; Place / Confirm import | Light impact. Save still uses success/error notifications. |
| `NSPhotoLibraryUsageDescription` unused | `Info.plist`, `InfoPlist.xcstrings`, README | **Removed.** PHPicker does not need it; add-only save uses `NSPhotoLibraryAddUsageDescription`. Safe for App Review with current APIs — do not add full-library read unless you request `.readWrite`. |

## Remaining UX (not all implemented)

### P0 (do on device before App Store)

- Run the real first-launch / Skip / Finish / Follow / Save / photo-lift paths on an **iPhone**. Simulator Vision masks are weaker than device.
- Confirm a photo-pet wallpaper actually contains the cutout after Save (the Canvas draw is the code-side mitigation; still needs a device screenshot).
- Privacy Nutrition Labels: picker + add-only save only; cutout is on-device. Info.plist now has **add-only** only — match App Privacy to that (no Photo Library *read* purpose).

### P1

- Done in this pass (see table above). Re-check VoiceOver on a device if Dynamic Type XXL clips any remaining tray labels.

### P2

- Empty Photos library: system picker already handles this; a one-line caption under **用我嘅相** would still help.
- Cutout tips on the refine screen (contrast background, whole pet in frame, avoid group photos).
- Memory: keep `original` on `PhotoPetCutout` after confirm; downscale more aggressively for huge panos.
- Rapid NavigationStack push/pop is standard SwiftUI; no extra debounce.

## Localization

New keys (zh-Hant + en): `common.back`, `import.loadFailed.title`, `import.loadFailed.detail`, `export.openSettings`, plus P1 a11y keys (`a11y.on`, `a11y.off`, `a11y.follow.hint`, `a11y.trail.hint`, `a11y.save.hint`, `a11y.upload.hint`, `a11y.template.hint`, `a11y.crop.move`, `a11y.crop.resize`). Other user-facing Swift keys were already in `Localizable.xcstrings`. Missing-key risk is now limited to future strings not added to the catalog.
