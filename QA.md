# PetPaper first-run QA (code walk)

This Linux environment cannot run the iOS Simulator. Findings below are from walking the SwiftUI code paths a new user hits. Device/Simulator verification still belongs on a Mac.

## Flows walked (this pass)

1. **Fresh install** — `AppSession.init` reads `petpaper.hasCompletedTutorial`. If false, `presentedCover = .tutorial`. Skip → home. Last-step **開始整** → home + editor. Second launch with the flag set never presents the tutorial.
2. **Template → editor** — Home grid `openEditor` restores the last illustrated pet (UserDefaults) and marks the last template. Pet / stickers / colors / text sheets, Follow, undo/reset, Save → `WallpaperExporter`.
3. **用我嘅相** — Caption under the card (including empty Photos). `PhotosPicker` → ImageIO downsample → Vision lift → multi-subject choose → refine (with cutout tips) → confirm → editor with `pendingPhotoPet`.
4. **Replay tutorial** — Home card `replayTutorial()`. Swipe-down is allowed only after the tutorial has been completed once. Replay seeds template/pet from last-used picks.
5. **Idle activities** — Home idle card + editor tray + **桌面寵物** widget. Weighted `PetIdleAction` (fly-out **2%**). Demo interval and **預覽動作**. WidgetKit timeline on the Home Screen; static Photos wallpaper cannot animate.
6. **Edges** — denied add-only Photos, Vision `noSubject`, empty picker load, cancel mid-analyze, Follow vs pinch, Follow off disables trail, pop editor drops pending cutout, missing string keys.

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
- iOS Home/Lock Screen Photos wallpapers cannot animate. Use the **桌面寵物** Home Screen widget for live idle poses. Do not block on Live Wallpaper export.

## Idle activities + Home Screen widget (this pass)

In-app preview (editor canvas / home cards) plus a WidgetKit extension **桌面寵物**. `PetIdleAction` tickets `0..<100`, **flyOutDoor = 98–99 (exactly 2%)**. App Group `group.com.eric1020.petpaper` shares interval, idle on/off, last pet/template, and an optional photo-cutout PNG.

| Surface | How motion works |
| --- | --- |
| In-app | `PetIdleDirector` timer + temporary transforms |
| Home Screen | WidgetKit timeline entries (pose frames). Fly-out = leave → empty/sparkle → return |
| Photos wallpaper | Still image only. Optional background behind the widget |

### Device / Simulator test plan

**In-app (unchanged)**  
1. Idle card toggle, **預覽（8 秒）**, **預覽動作**, Follow pause, drag cancel, photo subset, toast, persistence.

**Home Screen widget**  
2. Run **PetPaper** (embeds the widget). Home Screen → long-press → Add Widget → PetPaper → **桌面寵物**. Small and medium families.  
3. Optional: scheme **PetPaperWidget** with `_XCWidgetKind=DesktopPetWidget` to preview on Simulator SpringBoard.  
4. Set interval to **Demo** in the app (跟隨 App) or in widget Edit Widget. Within about 20s the pet should change pose. Fly-out is rare (~2%): portal, pet leaves, empty sparkle, return.  
5. Edit Widget: pick a catalog pet, a template tint, idle off (stays at rest), idle on again.  
6. Confirm a photo cutout in the app, set widget pet to **我的去背寵物** (or 跟隨 App while using a photo pet). Widget shows the snapshot.  
7. Tap widget: app opens editor (`petpaper://editor`).  
8. Lock the device / wait: updates may be delayed or coalesced. Documented; 2h is best-effort.  
9. Save wallpaper during in-app idle: still resting pose. Widget is independent of the export.

### Uninstall + background (honest iOS behavior)

iOS has **no** `applicationWillBeDeleted`. Do not add a fake uninstall API. Deleting the app already kills the process, removes **桌面寵物** from the Home Screen, cancels that app’s local notifications, stops BG tasks (none registered), and wipes the app container + App Group.

**Audit (code walk, this pass):** no `UIBackgroundModes`, no `BGTaskScheduler`, no `aps-environment` / silent push, no location/audio/VoIP background, no server jobs. Idle is in-process `Task` loops; the widget is a local WidgetKit timeline. Nothing schedules work that can outlive the app.

**In-app hygiene (not a substitute for uninstall):** Home and editor cancel `PetIdleDirector` when `scenePhase` is not `.active` (resign active / background), when the idle `.task` ends, and on disappear. Turning the idle toggle off still stops scheduled motion.

**Device checks**

10. Background or switch apps while a home/editor idle pose is playing: animation should snap back to rest (no keep-alive).  
11. Delete the app with **桌面寵物** on the Home Screen: the widget is gone immediately; no leftover pet motion. (Linux cannot run this.)  
12. Signing & Capabilities: App Groups + In-App Purchase only — no Background Modes, no Push Notifications.

Idle settings copy includes `idle.uninstallNote` (zh-Hant + en): 刪除 App 後，主畫面桌面寵物 Widget 會一併消失，背景活動會即時停止。

## Localization

New keys (zh-Hant + en): … idle.*, `idle.uninstallNote`, `editor.tool.idle`, `widget.displayName`, `widget.description`, `widget.pet*`, `widget.template*`, `widget.interval.appSetting`, `widget.idle.appSetting`, `widget.install.*`.

Plus / paywall keys (this pass): `paywall.*`, `plus.badge`, `home.plus.*`, `home.upload.locked`, `editor.pet.freeHint`, `a11y.plus.locked`, `a11y.paywall.*`, `a11y.pet.hint`, `idle.locked`.

Updated: `export.success.message`, `a11y.trail.hint`, `idle.wallpaperNote`.

UserDefaults / App Group keys: `petpaper.hasCompletedTutorial`, `petpaper.lastTemplate`, `petpaper.lastPetID`, `petpaper.idleEnabled`, `petpaper.idleInterval`, `petpaper.idleToast`, `petpaper.usesPhotoPet`, `petpaper.hasPlusAccess` (privacy manifest reason **CA92.1**). App Group `group.com.eric1020.petpaper`. Plus **receipts** are not stored — `hasPlusAccess` is a derived widget cache of StoreKit `Transaction.currentEntitlements`.

## PetPaper Plus / StoreKit (this pass)

Linux cannot run Simulator StoreKit. Walk the code, then verify on a Mac as below.

### Model

- Download free. `SubscriptionManager` loads `com.eric1020.petpaper.plus.monthly`, purchases with StoreKit 2, restores via `AppStore.sync()`, and listens to `Transaction.updates`.
- Trial or subscribed → `hasPlusAccess`. After expiry without renewal: templates + tabby cat + Follow + save + resting Home Screen widget remain; photo import, extra pets, in-app idle activities, and widget premium poses lock (`canUsePremiumMotion()`).
- Price in `Products.storekit` is **$0.99 / month** with a **1-month free** introductory offer. App Store Connect should use the **$0.99 USD** tier (closest to US$1). No third-party IAP SDK.

### Xcode `.storekit` scheme

1. Open `PetPaper.xcodeproj`. The shared **PetPaper** scheme’s Run (and Test) actions already reference `PetPaper/Products.storekit`.
2. Confirm: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration = **Products.storekit**.
3. Run on Simulator. Home should show the Plus banner (no entitlement yet).
4. Tap the banner or a locked photo-import / extra-pet / idle-preview control. Paywall must show localized price (or `US$0.99` fallback), 1-month trial, Subscribe / Restore / Not now, legal auto-renew copy, EULA + privacy.
5. Subscribe with the StoreKit test sheet. After success, banner switches to Plus, photo import, extra pets, idle activities, and widget premium poses unlock.
6. Debug → StoreKit → Manage Transactions: expire / refund the subscription and confirm locks return (tabby + save + resting widget still work). Speed up renewal to watch the trial convert to paid.
7. Restore Purchases with no transaction → “nothing to restore”. With a transaction on the Apple ID → Plus unlocks.
8. For TestFlight / sandbox, **remove** the StoreKit Configuration from the scheme (or use a scheme without it) so the app uses App Store Connect products.

### Device / Simulator checks still needed on a Mac

- Paywall Dynamic Type XXL and VoiceOver on Subscribe / Restore / locked pet cells.
- Nested editor pet sheet: locked pet dismisses the picker then shows the paywall.
- Tutorial pet grid locks extra pets and can still finish with the tabby cat.
- Idle toggle / preview without Plus opens the paywall; widget stays at rest.
- Sandbox Apple ID: intro-offer eligibility only once per subscription group.
