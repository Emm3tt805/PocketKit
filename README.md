# PocketKit

An iPhone app with three tabs:

- **Timers**: quick-start presets, custom timers with names, pause/resume/reset, and a notification when a timer finishes (even if the app is closed).
- **Notify**: schedule your own notifications for any date and time, optionally repeating daily, plus a 5-second test button.
- **Browser**: a built-in web browser with an address/search bar, back/forward, reload, share, and swipe gestures.

## Get the .ipa (free, works from Windows)

1. Make a free account at github.com and create a new **public** repository.
2. Click "uploading an existing file" and drag in everything from this folder, including the `.github` folder. Commit.
   - If the `.github` folder doesn't upload, go to the **Actions** tab, choose "set up a workflow yourself", and paste in the contents of `.github/workflows/build-ipa.yml`.
3. Open the **Actions** tab. The "Build IPA" job runs automatically (or press "Run workflow"). It takes about 5 minutes.
4. When it shows a green check, open the run and download **PocketKit-ipa** at the bottom. Unzip it to get `PocketKit.ipa`.

## Install it on your iPhone

1. On your PC, install iTunes and iCloud from apple.com (not the Microsoft Store versions), then install **Sideloadly**.
2. Plug in your iPhone, drag `PocketKit.ipa` into Sideloadly, enter your Apple ID, and press Start.
3. On the iPhone: Settings → General → VPN & Device Management → trust your Apple ID. On iOS 16+, also turn on Settings → Privacy & Security → Developer Mode.
4. Open PocketKit and allow notifications.

With a free Apple ID the app stops opening after 7 days. Reinstall it with Sideloadly to reset the clock (your timers are kept).

## Changing the app

Edit the Swift files in `Sources/` on GitHub and commit. A new .ipa builds automatically.
