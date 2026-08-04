---
name: dataset-readme
description:
  Generate a comprehensive install.md documentation file for an image dataset. Use when asked to document a dataset,
  create a dataset readme, or prepare dataset documentation.
argument-hint: <path-to-dataset-root>
allowed-tools: Bash, Read, Glob, Grep, Write, Edit
---

# dataset-readme

Document the image dataset at `$ARGUMENTS`.

## Safety

**The only file you may create or edit is `install.md` or `install-new.md` in the dataset root.**

Do not create, modify, move, rename, or delete any other file in the dataset, and write no temporary files inside it --
use the scratchpad directory. All inspection is read-only: open images to read dimensions, read JSONs, load `.npz`
files, never write back. If you are unsure whether an action would modify dataset files, do not do it.

## If `install.md` already exists

Check before exploring. If it does not exist, explore and write `install.md`. If it does, read it in full, run the same
exploration anyway, and compare your findings against it -- file count mismatches, new or deleted files, undocumented
file types or directories, metadata schema changes (new/removed JSON keys, changed NPZ shapes), resolution or format
changes, new or removed shards. If the existing file is accurate and complete, report that no update is needed and list
what you verified. If there are real discrepancies, write **`install-new.md`** and summarize what changed.

## Exploration

Use `uv run --with <deps>` for Python one-liners.

1. **Structure** -- list top-level entries, recurse into subdirectories (shards, splits, subsets), count files by
   extension at each level, and identify the naming convention (e.g. `NNNNN_face=0.png`).
2. **Counts** -- total files per extension (`.png`, `.jpg`, `.json`, `.npz`, `.npy`, `.txt`, `.csv`, `.parquet`), unique
   sample IDs (strip suffixes and extensions), shard count. Report discrepancies such as images without metadata or
   missing masks.
3. **Images** -- per distinct image type (main, masks, segmentation maps, visualizations, augmentations), check
   resolution, color mode, and format:
   ```
   uv run --with Pillow python3 -c "from PIL import Image; i=Image.open('<path>'); print(i.size, i.mode)"
   ```
   For anything that looks like a mask or segmentation map, enumerate the palette with numpy
   (`np.unique(arr.reshape(-1, arr.shape[-1]), axis=0)`) so you can build a class table. Sample 5-10 files from
   different shards to confirm consistency.
4. **Metadata** -- read 2-3 sample `.json` files and document the full schema (every key, value type, nesting). For
   `.npz`/`.npy`, load with `allow_pickle=True` and report each key's shape and dtype. For `.csv`/`.parquet`/`.txt`,
   show headers and sample rows. For `.yaml`, summarize the config schema. Explain what each field means from its name
   and values.
5. **Relationships** -- pair related files (image + mask, source + augmented, original + caption), follow
   cross-references in metadata (`source_image`-style fields), and note any train/val/test or filtered-subset
   organization.
6. **Provenance** -- if a generation script for this data exists in a sibling project, read it for class-name mappings,
   color tables, and enum definitions that document label meanings, and cite what you find.

## Output

Write the file in the dataset root with these sections:

1. **Title and summary** -- dataset name, one-paragraph description, key highlights.
2. **Statistics** -- a table of counts: total samples, files per type, unique IDs, shards.
3. **Directory structure** -- an ASCII tree with inline comments explaining each file type.
4. **File formats** -- per type: format, resolution or shape, dtype; the full schema for structured data; color/class
   mapping tables for segmentation maps; truncated example content.
5. **Usage with PyTorch** -- ready-to-use `torch.utils.data.Dataset` subclasses (a basic image + metadata one, plus any
   specialized cases the data supports: segmentation, landmarks, paired data) with proper imports, `__len__`,
   `__getitem__`, and a minimal `DataLoader` example.

GitHub-flavored Markdown. Stay factual -- describe what IS in the data, never speculate. Use exact numbers from your
counts. Show real (truncated with `...`) JSON examples. Always use a table for class or label mappings, with ID, name,
and any visual identifier. PyTorch code must be clean, typed, and copy-pasteable.

See [example.md](example.md) for a reference output.
