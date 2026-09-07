# PetPaper first-run QA (code walk)

This Linux environment cannot run the iOS Simulator. Findings below are from walking the SwiftUI code paths a new user hits. Device/Simulator verification still belongs on a Mac.

## Flows walked (this pass)

1. **Fresh install** — `AppSession.init` reads `petpaper.hasCompletedTutorial`. If false, `presentedCover = .tutorial`. Skip → home. Last-step **開始整** → home + editor. Second launch with the flag set never presents the tutorial.
2. **Template → editor** — Home grid `openEditor` restores the last illustrated pet (UserDefaults) and marks the last template. Pet / stickers / colors / text sheets, Follow, undo/reset, Save → `WallpaperExporter`.
3. **用我嘅相** — Caption under the card (including empty Photos). `PhotosPicker` → ImageIO downsample → Vision lift → multi-subject choose → refine (with cutout tips) → confirm → editor with `pendingPhotoPet`.
4. **Replay tutorial** — Home card `replayTutorial()`. Swipe-down is allowed only after the tutorial has been completed once. Replay seeds template/pet from last-used picks.
5. **Edges** — denied add-only Photos, Vision `noSubject`, empty picker load, cancel mid-analyze, Follow vs pinch, Follow off disables trail, pop editor drops pending cutout, missing string keys.

## P2 polish (implemented)

| Item | Where | What shipped |
| --- | --- | --- |
| Empty / first-time caption under **用我嘅相** | `HomeView`, `home.upload.emptyTip` | Always-visible one-line tip. The app cannot query library emptiness without full-library permission; the system picker still handles empty. |
| Cutout tips on refine / preview | `PhotoImportView` preview + manual crop | Contrast background, whole pet in frame, avoid crowded group photos. |
| Aggressive downsample for huge originals | `ImageProcessing`, import pipeline, `PhotoPetCutout` | ImageIO thumbnail decode at 1920px long edge; stored `original` + cutout capped the same way. 48MP / panos never stay in RAM at full size. Export pet is typically ~700px (max ~1800px on 1290×2796). |
| Last-used template + pet | `AppSession` UserDefaults | Persisted after editor open / tutorial finish / photo place. Home badge **上次使用**. Photo-import template picker defaults to last template. Not shown on a fresh install. |
| Post-save wallpaper how-to | `export.success.message` | Explicit: the app cannot set wallpaper; Photos → Share → Use as Wallpaper → Lock / Home / both. |
| Trail only with Follow | `EditorView`, `WallpaperCanvasView`, `EditorStore` | Paw-trail chip disabled (and forced off) when Follow is off. Trail layer not drawn. Expired paw dots prune so `TimelineView` does not tick forever. |
| Dynamic Type / editor tray | `EditorView` | Canvas `maxHeight: .infinity` so the tray is not pushed off-screen. Follow/trail `ViewThatFits` stack. Tray labels wrap + `minimumScaleFactor`. Hint line scales. |
| Photo-import swipe-dismiss | `RootView` | Import cover is not interactively dismissible (Cancel only) so refine work is not lost. |
| Pending cutout leak | `AppSession`, `RootView` | `pendingPhotoPet` cleared when no photo-pet route remains on the stack. |

## Bugs fixed in this pass

| Issue | File | Fix |
| --- | --- | --- |
| Import kept full-resolution originals (48MP / panos) after picker decode | `ImageProcessing`, `AppSession.beginPhotoImport`, confirm | Thumbnail decode + 1920 long-edge cap for working original and stored cutout |
| `pendingPhotoPet` stayed in the session after popping the editor | `RootView`, `AppSession` | Clear when the navigation path has no photo-pet route |
| Paw-trail `TimelineView` kept running after Follow ended (expired dots never pruned) | `WallpaperCanvasView` | Prune on the timeline tick; hide trail unless Follow + trail are on |
| Trail chip could be on while Follow was off | `EditorView` | Disable chip; turning Follow off clears trail + preference |
| Accidental swipe-down dismissed photo import mid-refine | `RootView` | `interactiveDismissDisabled()` on the import cover |

## Earlier passes (P0/P1, still shipped)

Skip vs Finish landing, single `AppCover`, Follow vs pinch, Follow undo, Vision cancel resume-once, picker load-failed copy, add-only Settings deep link, Confirm disabled without preview, pixel-space crop, Canvas cutout draw, hue/text undo, pet-sheet dismiss, crop handles, VoiceOver, HEIC retry, haptics, drop unused `NSPhotoLibraryUsageDescription`.

## Remaining UX (not all implemented)

### P0 (do on device before App Store)

- Run the real first-launch / Skip / Finish / Follow / Save / photo-lift paths on an **iPhone**. Simulator Vision masks are weaker than device.
- Confirm a photo-pet wallpaper actually contains the cutout after Save (Canvas draw is the code-side mitigation; still needs a device screenshot).
- Save a 48MP / pano pet photo and confirm memory stays reasonable and the exported pet is sharp enough.
- Privacy Nutrition Labels: picker + add-only save only; cutout is on-device. Info.plist has **add-only** only — match App Privacy to that (no Photo Library *read* purpose).
- Dynamic Type: Accessibility XXL / AX1–AX3 on the editor tray, Follow chips, and import refine tips.
- VoiceOver: upload empty tip, last-used badge, trail-disabled hint, post-save alert.

### P1

- Done in the previous pass. Re-check VoiceOver on a device if Dynamic Type XXL still clips any remaining tray labels.

### P2

- Done in this pass (see table above). Rapid NavigationStack push/pop is standard SwiftUI; no extra debounce.

### Later ideas

- Persist a richer editor draft (stickers / overlay text / photo cutout on disk). Currently only last template + last illustrated pet.
- Re-refine a confirmed photo pet from the editor (the downscaled `original` is kept for that).
- In-app “set wallpaper” deep link is not possible; keep the post-save Photos instructions.

## Localization

New keys (zh-Hant + en): `home.upload.emptyTip`, `home.lastUsed`, `import.preview.tipsTitle`, `import.preview.tip.contrast`, `import.preview.tip.frame`, `import.preview.tip.group`, `a11y.trail.disabled`.

Updated: `export.success.message`, `a11y.trail.hint`.

UserDefaults keys: `petpaper.hasCompletedTutorial`, `petpaper.lastTemplate`, `petpaper.lastPetID` (privacy manifest reason **CA92.1**).
