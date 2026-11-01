# Anime Sahab v0.3 — Source + automated build workflow

This package contains the Flutter source and a GitHub Actions workflow to compile:
- Android release APK
- Windows x64 release application folder (ZIP)

## Important
The current execution environment has no Flutter SDK and cannot compile a Windows executable. Therefore this package is **not** an APK or EXE installer. The workflow is prepared to build both targets on GitHub-hosted runners once the source is placed in a GitHub repository.

## Build artifacts using GitHub Actions
1. Create a GitHub repository and upload/extract all files from this ZIP into its `main` branch.
2. Open the repository's **Actions** tab.
3. Select **Build Anime Sahab**, then choose **Run workflow** (or push to `main`).
4. When both jobs finish, open the workflow run and download:
   - `anime-sahab-android-apk`
   - `anime-sahab-windows`

The Windows ZIP contains the release app files. Extract it and run `anime_sahab.exe` (the exact executable name is determined by Flutter project metadata; if different, run the `.exe` in the extracted folder). Keep the included DLLs and data folder beside the EXE.

## Features in this source
- Dark theme
- English/Arabic interface switch
- Search catalogue through AniList
- Arabic aliases for common anime names
- Metadata details
- Video playback and MP4 download hooks for authorized HTTPS sources

## Content rights
AniList provides metadata, not full anime episodes. Full original episodes with original voices, subtitles and downloadable MP4 require a licensed provider. The sample catalog is intentionally empty of episode URLs. This project does not scrape piracy sites or bypass DRM.
