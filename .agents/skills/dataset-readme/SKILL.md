---
name: dataset-readme
description: Generate or refresh install.md documentation for an image dataset after read-only inspection.
---

# Dataset Readme

Document the dataset root named by the user. The only file this workflow may
create or edit there is `install.md`, or `install-new.md` when an existing
`install.md` is materially stale. Keep temporary work outside the dataset.

If `install.md` exists, read it first, perform the full inspection, and compare
counts, layout, formats, schemas, resolutions, and shards. Report no change when
it remains complete; otherwise write `install-new.md` and summarize the drift.

## Inspect

Use read-only commands and `uv run --with <deps>` for Python diagnostics.

1. Map top-level entries, nested splits or shards, naming patterns, and file
   counts by extension and directory.
2. Count unique sample IDs and check expected pairings such as image plus mask,
   metadata, caption, or augmentation.
3. Sample 5-10 files across shards for each image type. Record dimensions,
   color mode, format, and segmentation palettes where applicable.
4. Read representative JSON, NPZ, NPY, CSV, Parquet, text, or YAML metadata.
   Document all keys, nesting, shapes, dtypes, headers, and representative rows.
5. Follow cross-references and identify splits, filtered subsets, and provenance.
   Read a nearby generation script when it defines label names or color maps.

Never modify, rename, move, or delete dataset content. Do not write inspection
artifacts into the dataset.

## Write

Produce factual GitHub-flavored Markdown with:

- a title, short summary, and exact statistics table;
- an ASCII directory tree with concise comments;
- file formats, image properties, structured-data schemas, and label tables;
- real but truncated examples;
- typed, copy-pasteable PyTorch `Dataset` and `DataLoader` examples appropriate
  to the observed relationships.

Use exact measured counts and do not infer meanings unsupported by the data.
See [example.md](example.md) for the expected level of detail.
