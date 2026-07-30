# Example Output: selfie-37k-align=1024px/install.md

This is a trimmed reference showing the expected structure and style. The actual output should be tailored to the specific dataset being documented.

---

# selfie-37k-align=1024px

A face-centric selfie dataset containing **37,126 aligned face images** at 1024x1024 resolution, with rich metadata including facial landmarks, face parsing segmentation maps, VLM captions, quality scores, and makeup detection labels.

## Dataset Statistics

| Metric | Count |
|---|---|
| Face images (`.png`) | 37,126 |
| Unique source photographs | 36,763 |
| Face parsing maps (`.paps.png`) | 37,126 |
| Metadata JSONs (`.json`) | 37,126 |
| Landmark files (`.landmarks.npz`) | 36,929 |

Images are sharded into **38 subdirectories** (`00/`–`37/`), ~1,000 samples per shard.

## Directory Structure

```
selfie-37k-align=1024px/
├── images/
│   ├── 00/
│   │   ├── 00001_face=0.png              # aligned face image (1024x1024 RGB)
│   │   ├── 00001_face=0.json             # metadata (captions, quality, detections)
│   │   ├── 00001_face=0.landmarks.npz    # facial landmarks (sparse + dense)
│   │   ├── 00001_face=0.pafl.png         # landmark visualization (1024x1024 RGB)
│   │   └── 00001_face=0.paps.png         # face parsing segmentation (1024x1024 RGB)
│   ├── 01/
│   └── ...37/
└── makeups/
    └── ...
```

## File Formats

### Face Image (`NNNNN_face=N.png`)

- **Resolution**: 1024x1024
- **Mode**: RGB
- **Format**: PNG

### Metadata JSON (`NNNNN_face=N.json`)

```json
{
    "OpenGVLab/InternVL3_5-38B": "The person in the image appears to be...",
    "faces": [
        {
            "angles": {"pitch": -21.6, "roll": -7.9, "yaw": 30.3},
            "area": 513125,
            "confidence": 0.814
        }
    ],
    "makeup_detection": {
        "class_ids": [4],
        "confidences": [0.93]
    },
    "quality/clipiqa+_vitL14_512": 0.517
}
```

| Field | Description |
|---|---|
| `OpenGVLab/InternVL3_5-38B` | Caption from InternVL3.5-38B VLM |
| `faces[].angles` | Head pose: pitch, roll, yaw (degrees) |
| `quality/clipiqa+_vitL14_512` | CLIP-IQA+ quality score |

### Face Parsing Segmentation (`NNNNN_face=N.paps.png`)

| Class | ID | RGB Color |
|---|---|---|
| Background | 0 | (0, 0, 0) |
| Hair | 1 | (199, 132, 191) |
| Skin | 2 | (195, 131, 66) |
| Lips | 3 | (100, 122, 53) |

## Usage with PyTorch

```python
import json
from pathlib import Path
from PIL import Image
from torch.utils.data import Dataset
from torchvision import transforms


class Selfie37kDataset(Dataset):
    def __init__(self, root: str, transform=None):
        self.root = Path(root) / "images"
        self.transform = transform
        self.samples = sorted(self.root.glob("*/*_face=*.png"))
        self.samples = [p for p in self.samples if ".pafl." not in p.name and ".paps." not in p.name]

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img_path = self.samples[idx]
        image = Image.open(img_path).convert("RGB")
        if self.transform:
            image = self.transform(image)

        with open(img_path.with_suffix(".json")) as f:
            metadata = json.load(f)

        return {
            "image": image,
            "caption": metadata.get("OpenGVLab/InternVL3_5-38B", ""),
            "quality": metadata.get("quality/clipiqa+_vitL14_512", 0.0),
        }


# Usage
transform = transforms.Compose([transforms.Resize((512, 512)), transforms.ToTensor()])
dataset = Selfie37kDataset("/path/to/selfie-37k-align=1024px", transform=transform)
print(f"Dataset size: {len(dataset)}")
```
