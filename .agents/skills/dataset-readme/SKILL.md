---
name: dataset-readme
description: Generate a comprehensive install.md documentation file for an image dataset. Use when asked to document a dataset, create a dataset readme, or prepare dataset documentation.
argument-hint: <path-to-dataset-root>
allowed-tools: Bash, Read, Glob, Grep, Write, Edit
---

# Dataset Documentation Generator

Generate a comprehensive `install.md` for the image dataset located at:

```
$ARGUMENTS
```

## CRITICAL SAFETY RULES

**The ONLY file you may create or edit is `install.md` or `install-new.md` in the dataset root directory.**

- **DO NOT** create, modify, move, rename, or delete ANY other file in the dataset.
- **DO NOT** write any temporary files inside the dataset directory.
- All dataset inspection MUST be read-only: open images to check dimensions, read JSONs, load `.npz` files — never write back.
- Use the scratchpad directory for any temporary scripts or intermediate files.
- If you are unsure whether an action modifies dataset files, DO NOT do it.

## When `install.md` Already Exists

Before starting exploration, check whether `install.md` already exists in the dataset root directory.

- If `install.md` does **NOT** exist → proceed with the full exploration below and write **`install.md`**.
- If `install.md` **already exists** → follow the **verification workflow**:

### Verification Workflow

1. **Read the existing `install.md`** in full.
2. **Run the same exploration steps** described below (directory structure, file counts, image checks, metadata schemas, etc.).
3. **Compare your findings against the existing documentation.** Check for:
   - File count mismatches (new or deleted files, changed totals)
   - New file types or directories not documented
   - Schema changes in metadata (new/removed JSON keys, changed NPZ shapes)
   - Resolution or format changes in images
   - New or removed shards/subsets
   - Incorrect or outdated descriptions
4. **If the existing `install.md` is accurate and complete** → report to the user that no updates are needed, listing what you verified.
5. **If there are actual discrepancies or new data** → write **`install-new.md`** with the corrected/updated documentation. Summarize what changed for the user.

## Exploration Procedure

Work through these steps systematically. Use `uv run --with <deps>` for any Python one-liners.

### Step 1: Directory Structure

- List top-level directories and files.
- Recursively explore subdirectories to understand the hierarchy (shards, splits, subsets).
- Count files by extension at each level.
- Identify the naming convention (e.g., `NNNNN_face=0.png`, `sample_001.jpg`).

### Step 2: Count Samples

- Count total files per extension (`.png`, `.jpg`, `.json`, `.npz`, `.npy`, `.txt`, `.csv`, `.parquet`, etc.).
- Count unique sample IDs (strip suffixes/extensions to find the base ID).
- Note if the dataset is sharded and how many shards exist.
- Report any discrepancies (e.g., images without metadata, missing masks).

### Step 3: Image Data

For each distinct image type found (main images, masks, segmentation maps, visualizations, augmented versions):

- Check resolution, color mode (RGB, L, RGBA), and format using:
  ```
  uv run --with Pillow python3 -c "from PIL import Image; img = Image.open('<path>'); print(f'size={img.size}, mode={img.mode}')"
  ```
- For images that look like segmentation maps or masks (few unique colors, binary patterns), analyze the color palette:
  ```
  uv run --with "Pillow,numpy" python3 -c "
  from PIL import Image; import numpy as np
  img = np.array(Image.open('<path>'))
  colors = np.unique(img.reshape(-1, img.shape[-1]) if img.ndim == 3 else img.reshape(-1), axis=0)
  print(f'unique values: {len(colors)}')
  for c in colors: print(f'  {c}')
  "
  ```
- Sample multiple files (at least 5-10 from different shards) to confirm consistency.

### Step 4: Metadata Files

- Read 2-3 sample `.json` files and document the full schema (all keys, value types, nesting).
- For `.npz`/`.npy` files, load and report keys, shapes, dtypes:
  ```
  uv run --with numpy python3 -c "
  import numpy as np
  d = np.load('<path>', allow_pickle=True)
  for k in d: print(f'{k}: shape={d[k].shape}, dtype={d[k].dtype}')
  "
  ```
- For `.csv`/`.parquet`/`.txt` files, show headers and a few sample rows.
- For `.yaml` files, read and summarize the configuration schema.
- Document what each metadata field means based on field names and values.

### Step 5: Paired/Related Data

- Identify relationships between files (e.g., image + mask, source + augmented, original + caption).
- Check for cross-references in metadata (e.g., `source_image` fields pointing to other files).
- Note any subset/split organization (train/val/test, filtered subsets).

### Step 6: Context from Scripts (if available)

- Check if the toolbox project at `/home/artem.kotov/projects/toolbox/` has relevant generation scripts (in `scripts/`, `src/`) that explain how the data was produced.
- Look for class name mappings, color tables, enum definitions that document label meanings.
- Reference these findings in the documentation.

## Output

Write the output file (`install.md` or `install-new.md`, as determined above) in the dataset root with these sections:

### Required Sections

1. **Title and Summary** — Dataset name, one-paragraph description, key highlights.

2. **Dataset Statistics** — Table with counts: total samples, files per type, unique IDs, shards.

3. **Directory Structure** — ASCII tree showing the layout with inline comments explaining each file type.

4. **File Formats** — For each file type, document:
   - Format, resolution/shape, data type
   - Full schema for structured data (JSON keys, NPZ arrays, CSV columns)
   - Color/class mapping tables for segmentation maps
   - Example content (truncated JSON, array shapes)

5. **Usage with PyTorch** — Provide ready-to-use `torch.utils.data.Dataset` subclass(es):
   - A basic dataset class that loads images + metadata
   - Additional dataset classes for specialized use cases (segmentation, landmarks, paired data, etc.)
   - Include proper imports, `__len__`, `__getitem__`
   - Show a minimal working example with `DataLoader`
   - Use `uv run` compatible imports (standard PyTorch + torchvision + PIL + numpy)

### Style Guidelines

- Use GitHub-flavored Markdown with tables, code blocks, and ASCII trees.
- Keep it factual — describe what IS in the data, not speculation.
- Include exact numbers from your counts.
- For JSON schemas, show a real (but potentially truncated) example with `...` for long arrays.
- For class/label mappings, always use a table with ID, name, and any visual identifier (color, etc.).
- PyTorch code should be clean, typed, and copy-pasteable.

See [example.md](example.md) for a reference output.
