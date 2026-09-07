# PetPaper / 寵物壁紙

A native SwiftUI iPhone app for creating original cat and dog wallpapers. Templates, pets, and stickers are drawn with SwiftUI shapes, gradients, Canvas, and SF Symbols — no stock photos and no third-party packages.

**Display name:** 寵物壁紙  
**Bundle ID (placeholder):** `com.eric1020.petpaper`  
**Requires:** iOS 17+, Xcode 15+ (Xcode 16 recommended), an Apple Developer account for device / App Store builds.

---

## Open and run

1. Clone this repo and open **`PetPaper.xcodeproj`** in Xcode (File → Open).
2. Select the **PetPaper** scheme and an iPhone simulator (for example iPhone 16).
3. Choose your team for signing:
   - Select the **PetPaper** target → **Signing & Capabilities**.
   - Enable **Automatically manage signing**.
   - Set **Team** to your Apple ID / developer team.
4. Press **Run** (⌘R).

First launch shows a short tutorial (Traditional Chinese if the device language is zh-Hant, otherwise English). **Skip** goes to the home gallery; **開始整 / Start creating** on the last step opens the editor with the chosen template and pet. Re-open the tutorial anytime from the home card **快速教學 / Quick tutorial**.

Code-level first-run QA (this repo cannot run Simulator) lives in **[QA.md](QA.md)**.

### 中文速覽

1. 用 Xcode 打開 `PetPaper.xcodeproj`。
2. 選 iPhone 模擬器，在 Signing 選你的 Team，按 ⌘R 執行。
3. 首次啟動會進入教學：選模板 → 選寵物 → 拖曳跟著走 → 儲存。主畫面也可「用我嘅相」上傳貓狗照片去背。
4. 在編輯器點右上角 **儲存**，壁紙會寫入「照片」（1290×2796）。再到 iOS 設成鎖定／主畫面壁紙。

---

## Change the bundle identifier

The placeholder is `com.eric1020.petpaper`. Change it before App Store submission:

1. Xcode → PetPaper target → **Signing & Capabilities** → **Bundle Identifier**.
2. Or edit `PRODUCT_BUNDLE_IDENTIFIER` in `PetPaper.xcodeproj/project.pbxproj`.
3. Use a reverse-DNS id you own, for example `com.yourname.petpaper`.

Keep it in sync with the App ID you create in [Apple Developer](https://developer.apple.com/account) and App Store Connect.

---

## Export wallpapers

- In the editor, tap **儲存 / Save**.
- PetPaper requests **add-only** Photos access (`NSPhotoLibraryAddUsageDescription`).
- The canvas is rendered at **1290 × 2796**, a size that fits modern iPhone wallpapers.
- Then in iOS: Photos → share / wallpaper, or Settings → Wallpaper.

Photos permission copy lives in `PetPaper/Info.plist` and `PetPaper/InfoPlist.xcstrings` (zh-Hant + English). The picker uses the system photo picker (`PhotosPicker` / PHPicker — no full-library permission). Saving wallpapers requests **add-only** access.

`NSPhotoLibraryUsageDescription` is **not** included. With PHPicker + add-only save, that key is unused and can look like a full-library read to App Review. Do not add it back unless you start calling `PHPhotoLibrary.requestAuthorization` for `.readWrite`.

---

## Upload a photo and lift the pet (iOS 17+)

Home screen card **用我嘅相 / Upload a pet photo**:

1. Pick an image with `PhotosPicker`.
2. On-device **Vision** (`VNGenerateForegroundInstanceMaskRequest`) lifts foreground subjects. Cats/dogs are preferred when `VNRecognizeAnimalsRequest` can label them.
3. If several subjects are found, tap the one you want.
4. Optional refine: edge, inward crop, tint, soft shadow.
5. Confirm onto a template, then edit (move / scale / rotate / Follow / stickers / text) and save like any other wallpaper.

**Privacy:** subject lift, animal hints, and masking all run on-device. No cloud APIs and no third-party ML packages.

**If Vision finds nothing:** a clear error plus tips, and a **manual crop** fallback (soft elliptical cutout of the framed area). Quality is better on a real iPhone than Simulator.

Requires **iOS 17.0+** (already the app’s deployment target) because instance-mask subject lift shipped in iOS 17.

---

## Project layout

```
PetPaper.xcodeproj          Xcode project + shared scheme
PetPaper/
  PetPaperApp.swift         App entry
  Info.plist                Photos usage + portrait
  Localizable.xcstrings     UI strings (zh-Hant primary, English secondary)
  InfoPlist.xcstrings       Display name + privacy strings
  PrivacyInfo.xcprivacy     UserDefaults reason CA92.1
  Assets.xcassets           App icon + accent
  Models/                   Templates, pets, stickers, editor state, idle actions
  Store/                    AppSession, EditorStore, PetIdleDirector
  Services/                 Photos export, on-device Vision subject lift
  Views/                    Home, editor, photo import, tutorial, idle settings, procedural art
```

No CocoaPods, SPM packages, or paid APIs. The MVP does not require an account.

---

## Features (MVP)

- **Gallery:** 8 SwiftUI scenes (pastel, night sky, park, cozy room, neon, sakura, beach, snow).
- **Pets:** 6 cats and 6 dogs, drawn with Canvas / shapes (tabby, calico, tuxedo, Siamese, grey, white; golden, corgi, husky, Dalmatian, shiba, black dog).
- **Editor:** colors (hue + accent), stickers (paws, hearts, bowls, balls, yarn, …), short text, place / scale / rotate.
- **Photo pets:** upload from Photos, on-device Vision cutout (iOS 17 subject lift), tap to choose if several subjects, then edit like an illustrated pet.
- **Follow mode:** the pet springs after your finger; optional fading paw-print trail.
- **Idle activities:** the pet randomly blinks, looks around, flicks, yawns, rolls, scratches, naps, zoomies, or (rarely) **飛天出門 / flies out the door**. Default about every **2 hours**; 30m / 1h / 2h / 4h plus an 8-second demo interval. Toggle on/off. **預覽動作 / Preview action** forces a roll (fly-out stays 2%).
- **Undo / reset** and **save to Photos**.
- **Tutorial** on first launch, replayable from home.

---

## App Store Connect checklist

Use this as a high-level list, not a substitute for Apple’s current review guidelines.

1. **Apple Developer Program** membership is active.
2. **Bundle ID** matches App Store Connect (change the placeholder).
3. **Signing:** Release archive with your distribution certificate / App Store profile (Automatic signing is fine).
4. **Version:** `MARKETING_VERSION` 1.0 and `CURRENT_PROJECT_VERSION` 1 (bump build for each upload).
5. **Privacy:** Photos picker + add-only save. Cutout is on-device Vision only. Do **not** declare full Photo Library read in Privacy Nutrition Labels — `NSPhotoLibraryUsageDescription` was dropped because PHPicker does not need it. Confirm App Privacy matches Info.plist (`NSPhotoLibraryAddUsageDescription` only).
6. **Privacy manifest:** `PrivacyInfo.xcprivacy` declares UserDefaults reason `CA92.1` (tutorial completion flag).
7. **Icons:** replace the placeholder 1024×1024 `AppIcon` if you want a custom marketing icon. iOS app icons must be opaque.
8. **Screenshots:** capture iPhone 6.7" (and any other required sizes) of home, editor, follow mode, and export.
9. **Description:** mention 寵物壁紙 / PetPaper, cat & dog wallpapers, no account required.
10. **Age rating:** typical 4+ for this kind of app; complete the questionnaire honestly.
11. **Product page:** localized zh-Hant + English recommended.
12. **Archive:** Product → Archive → Distribute App → App Store Connect.

Replace the generated paw-print icon and review copy before submitting if you want a stronger brand identity.

---

## Idle activities (in-app only)

The background pet plays a weighted random activity on a timer (default **2 hours**). Weights sum to 100; **飛天出門 / fly out the door is exactly 2%** of every roll, including **預覽動作** and photo-cutout rolls.

Illustrated pets use the full set (blink/breathe, look around, ear/tail flick, yawn/stretch, belly roll 翻肚, scratch, sleep curl, zoomies, fly-out). Photo cutouts skip ear/tail and yawn (no separate parts) and remap those tickets to look-around / blink; fly-out stays 2%.

Idle **pauses while Follow is on**, **cancels if you drag / pinch / rotate the pet**, then applies a short cooldown after each action. Optional toast shows the action name (zh-Hant + English). Settings persist in UserDefaults (`petpaper.idleEnabled`, `petpaper.idleInterval`, `petpaper.idleToast`).

Animations are **temporary transforms** on the editor canvas (and home template / mini previews). They are **not** written into the saved wallpaper. Export remains a still image at 1290×2796.

### Static Photos wallpaper cannot animate

iOS Home Screen and Lock Screen **Photos wallpapers are still images**. PetPaper cannot play idle motion on the system wallpaper, and this project does **not** implement Live Wallpaper / video wallpaper export. Live idle plays **inside the app** only:

- Editor canvas
- Home template cards and the idle mini-preview

Do not block release on Live Wallpaper export. After **儲存 / Save**, set the still image as wallpaper the usual way (Photos → Share → Use as Wallpaper).

---

## Notes

- Primary UI language is **Traditional Chinese (zh-Hant)**; **English** is the secondary localization via String Catalogs.
- All artwork is original procedural / SF Symbols so it is safer for App Store than scraped or stock photos. Do not drop in copyrighted character art.
- This repository was authored so it opens as a standard Xcode iOS app. Build and archive on a Mac; Linux CI cannot compile for iOS without Xcode.
