# Builds for restricted uploads

Run `npm run build:upload` for a host with a **2 MB per-file** upload limit.
Upload **every file in `dist-upload/` into the same directory**: `index.html`
and all `assets-*.bin` files. Open the hosted `index.html` over HTTP(S).
Do not upload just the HTML or open this version by double-clicking it.
The host must allow companion binary files and requests to them.

The build enforces a 2,000,000-byte HTML ceiling and divides the compressed
assets into pieces of at most 1,900,000 bytes. It does not depend on server
compression settings. The browser downloads and reconstructs the archive,
then the existing asset resolver serves the original JSON, images and music.
All four music tracks and every gameplay feature remain included.

Measured sizes for the current project (decimal MB):

| Build | Files | Largest file | Total |
| --- | ---: | ---: | ---: |
| Original standalone | 1 | 44.15 MB | 44.15 MB |
| Optimized standalone | 1 | 33.33 MB | 33.33 MB |
| Upload build | 14 | 1.90 MB | 25.27 MB |

The normal `npm run build:standalone` still creates a single, offline-capable
`dist-standalone/game.html`. Both packaging modes now omit unused source OBJ/MTL
files, redundant source textures and other files the running game never reads.
JSON is stored as text before gzip instead of base64, improving compression.
The original files in `public/` are untouched. Referenced scene images and
sound-manifest files are collected automatically.

**This does not fit a 2 MB total upload or ZIP limit.** The original music alone
is 19.70 MB. Such a limit requires a separate reduced-content build, aggressive
audio/model reduction, or hosting assets elsewhere. Upload splitting preserves
quality but cannot reduce the total to 2 MB.

Run `npm run test:upload` to build and verify every file's limit, asset hashes,
split loading, missing/truncated upload errors, and legacy single-file loading.
Re-upload the HTML and all chunks together after rebuilding.
