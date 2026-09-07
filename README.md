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

First launch shows a short tutorial (Traditional Chinese if the device language is zh-Hant, otherwise English). Re-open it anytime from the home card **快速教學 / Quick tutorial**.

### 中文速覽

1. 用 Xcode 打開 `PetPaper.xcodeproj`。
2. 選 iPhone 模擬器，在 Signing 選你的 Team，按 ⌘R 執行。
3. 首次啟動會進入教學：選模板 → 選寵物 → 拖曳跟著走 → 儲存。
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

Photos permission copy lives in `PetPaper/Info.plist` and `PetPaper/InfoPlist.xcstrings` (zh-Hant + English).

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
  Models/                   Templates, pets, stickers, editor state
  Store/                    AppSession, EditorStore
  Services/                 Photos export (PHPhotoLibrary)
  Views/                    Home, editor, tutorial, procedural art
```

No CocoaPods, SPM packages, or paid APIs. The MVP does not require an account.

---

## Features (MVP)

- **Gallery:** 8 SwiftUI scenes (pastel, night sky, park, cozy room, neon, sakura, beach, snow).
- **Pets:** 6 cats and 6 dogs, drawn with Canvas / shapes (tabby, calico, tuxedo, Siamese, grey, white; golden, corgi, husky, Dalmatian, shiba, black dog).
- **Editor:** colors (hue + accent), stickers (paws, hearts, bowls, balls, yarn, …), short text, place / scale / rotate.
- **Follow mode:** the pet springs after your finger; optional fading paw-print trail.
- **Undo / reset** and **save to Photos**.
- **Tutorial** on first launch, replayable from home.

---

## App Store Connect checklist

Use this as a high-level list, not a substitute for Apple’s current review guidelines.

1. **Apple Developer Program** membership is active.
2. **Bundle ID** matches App Store Connect (change the placeholder).
3. **Signing:** Release archive with your distribution certificate / App Store profile (Automatic signing is fine).
4. **Version:** `MARKETING_VERSION` 1.0 and `CURRENT_PROJECT_VERSION` 1 (bump build for each upload).
5. **Privacy:** Photos add-only usage strings are set. Privacy Nutrition Labels: the app does not collect account data; it only writes images the user saves. Confirm in App Privacy.
6. **Privacy manifest:** `PrivacyInfo.xcprivacy` declares UserDefaults reason `CA92.1` (tutorial completion flag).
7. **Icons:** replace the placeholder 1024×1024 `AppIcon` if you want a custom marketing icon. iOS app icons must be opaque.
8. **Screenshots:** capture iPhone 6.7" (and any other required sizes) of home, editor, follow mode, and export.
9. **Description:** mention 寵物壁紙 / PetPaper, cat & dog wallpapers, no account required.
10. **Age rating:** typical 4+ for this kind of app; complete the questionnaire honestly.
11. **Product page:** localized zh-Hant + English recommended.
12. **Archive:** Product → Archive → Distribute App → App Store Connect.

Replace the generated paw-print icon and review copy before submitting if you want a stronger brand identity.

---

## Notes

- Primary UI language is **Traditional Chinese (zh-Hant)**; **English** is the secondary localization via String Catalogs.
- All artwork is original procedural / SF Symbols so it is safer for App Store than scraped or stock photos. Do not drop in copyrighted character art.
- This repository was authored so it opens as a standard Xcode iOS app. Build and archive on a Mac; Linux CI cannot compile for iOS without Xcode.
