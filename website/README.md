# Static website

Plain HTML/CSS/JavaScript. Run `make web` from the repository root or `python3 -m http.server 4173 --bind 127.0.0.1 --directory website`.

`python3 website/check.py` verifies local routes, static images, script image references and release metadata. Binary installers/PDFs are intentionally not committed; download links point to the preview GitHub Release. The checker does not claim to re-hash absent binary files.

Deploy this directory as a static site root. No private deployment binding, Node runtime, API key, tracking SDK or backend is required. Root-relative paths need adjustment for subdirectory hosting. This source copy corrects the data-management copy to say CSV template download and JSON archive export; it does not add CSV readings export or JSON restore.
