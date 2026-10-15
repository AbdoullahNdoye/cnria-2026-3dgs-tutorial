# 3D Gaussian Splatting: From Images to a 3D Scene

**CNRIA 2026 — Hands-on tutorial**  
**Platform:** Ubuntu 24.04 (CPU-only; no CUDA or NVIDIA GPU required)  
**Tools:** [COLMAP](https://colmap.github.io/) + [OpenSplat](https://github.com/WebODM/OpenSplat)

This repository provides a small image dataset and reproducible instructions to create a 3D Gaussian Splatting (3DGS) scene. COLMAP recovers camera poses and a sparse 3D point cloud from images; OpenSplat uses them to optimize a Gaussian scene and export a `.ply` file for interactive visualization.

> **Dataset status:** The dataset is supplied separately by the repository maintainer. Before publishing, copy the original photographs and a verified COLMAP sparse reconstruction into `dataset/test_scene/` as described below. The repository template alone contains no images or camera models.

## 1. Repository layout

```text
cnria-2026-3dgs-tutorial/
├── README.md
├── .gitignore
├── dataset/
│   └── test_scene/
│       ├── images/          # source photographs
│       └── sparse/
│           └── 0/           # COLMAP cameras.bin, images.bin, points3D.bin
└── scripts/
    └── reconstruct_cpu.sh  # optional command-line COLMAP pipeline
```

Only the original images and valid reconstruction are required for the OpenSplat demo. The COLMAP `database.db` is optional and is excluded from Git because it can be regenerated.

## 2. Requirements

- Ubuntu 24.04 (the commands are intended for Ubuntu; other versions may need adjustments)
- Several GB of available disk space and sufficient RAM for LibTorch/C++ compilation
- A collection of overlapping photographs of a static scene (or the included dataset once published)
- Internet connection to download system packages and LibTorch

For a first experiment, use a relatively small scene and image collection. CPU training can be slow.

## 3. Install COLMAP

```bash
sudo apt update
sudo apt install -y colmap git cmake build-essential libopencv-dev wget unzip
colmap -h
```

Launch COLMAP's graphical interface:

```bash
colmap gui
```

### COLMAP GUI reconstruction

1. In **File → New project**, select an SQLite database (e.g. `dataset/test_scene/database.db`) and the `dataset/test_scene/images` folder.
2. Run **Processing → Feature extraction**. Set the SIFT extraction GPU option to **off**.
3. Run **Processing → Feature matching**. For a small image collection, select exhaustive matching and disable GPU matching.
4. Run **Reconstruction → Start** to estimate camera poses and sparse 3D points.
5. Export/save the reconstructed model into `dataset/test_scene/sparse/0/` in COLMAP binary format if it is not already saved there.

The sparse model should contain:

```text
cameras.bin
images.bin
points3D.bin
```

If you are using the provided sparse reconstruction, you may skip COLMAP entirely and proceed to OpenSplat.

### Optional: reproduce COLMAP entirely from the terminal

From the repository root, run:

```bash
bash scripts/reconstruct_cpu.sh dataset/test_scene
```

The script creates `database.db` and writes reconstructions to `sparse/`. Run it on a fresh workspace without an existing sparse model to avoid confusion. CPU SIFT may take some time.

## 4. Install OpenSplat (CPU)

OpenSplat is a separate project and is **not** included or vendored here. These commands document the CPU build used for the workshop. We tested the tutorial workflow with OpenSplat **1.2.2** and a **LibTorch 2.5.1 CPU** archive (C++11 ABI); the latest upstream version may differ.

Install prerequisites (if not installed in Section 3):

```bash
sudo apt update
sudo apt install -y git cmake build-essential libopencv-dev wget unzip
```

Create a tools folder and obtain LibTorch CPU:

```bash
mkdir -p "$HOME/3dgs-tools"
cd "$HOME/3dgs-tools"
wget -O libtorch.zip \
  'https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-2.5.1%2Bcpu.zip'
unzip -q libtorch.zip
ls "$HOME/3dgs-tools/libtorch/share/cmake/Torch/TorchConfig.cmake"
```

Clone OpenSplat:

```bash
cd "$HOME/3dgs-tools"
git clone https://github.com/WebODM/OpenSplat.git
cd OpenSplat
```

> For exact reproducibility with the version used in this workshop, check out commit `688944f` if it is available in your clone: `git checkout 688944f`. Otherwise, use the current code and consult its documentation if build options change.

Build with CPU enabled explicitly:

```bash
cmake -S . -B build \
  -DCMAKE_PREFIX_PATH="$HOME/3dgs-tools/libtorch" \
  -DGPU_RUNTIME=CPU \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build -j4
./build/opensplat --help
```

**No CUDA toolkit is required.** The download is the C++ LibTorch distribution; installing Python's `torch` package is not necessary.

## 5. Train 3D Gaussians

From the **repository root**, set:

```bash
DATASET="$(pwd)/dataset/test_scene"
OPEN_SPLAT="$HOME/3dgs-tools/OpenSplat/build/opensplat"
```

Run a short CPU experiment:

```bash
mkdir -p outputs
"$OPEN_SPLAT" "$DATASET" -n 300 -o "$(pwd)/outputs/splat.ply"
```

Here `-n 300` specifies 300 training iterations and `-o` sets the resulting output file. The dataset path is a **positional argument**. Increase the number of iterations for a better result if time and memory permit:

```bash
"$OPEN_SPLAT" "$DATASET" -n 2000 -o "$(pwd)/outputs/splat_2000.ply"
```

Training speed depends on the number/resolution of images, reconstruction complexity, CPU and RAM. A 300-iteration result is for checking that the pipeline works, not a guarantee of good visual quality.

## 6. Visualize and edit

Open [PlayCanvas Gaussian Splat Viewer](https://playcanvas.com/viewer) in a browser and load `outputs/splat.ply`. You can also experiment with the [SuperSplat editor](https://playcanvas.com/supersplat/editor). Use a viewer that supports **Gaussian-splat PLY**; an ordinary point-cloud viewer may not render splat attributes as intended.

## 7. Troubleshooting

**`Could not find TorchConfig.cmake`** — Check that LibTorch was extracted and that `CMAKE_PREFIX_PATH` points to the `libtorch` directory containing `share/cmake/Torch/TorchConfig.cmake`.

**`Could not find nvcc`** — Harmless for CPU builds if you specify `-DGPU_RUNTIME=CPU`.

**`No space left on device`** — Free disk space before building, and inspect `df -h "$HOME"`. C++ precompiled headers can take substantial disk space.

**COLMAP registers few or no images** — Capture photos with substantial overlap, steady lighting and visible texture. Inspect reconstruction in the COLMAP GUI; OpenSplat needs sparse 3D points as well as camera poses.

**Slow CPU training** — Reduce image count/resolution, start with 100–300 iterations and close memory-heavy programs. GPU hardware is not required but makes training substantially faster.

## 8. Dataset attribution and license

**Dataset:** Workshop `test_scene` image collection.  
**Capture details:** _To be filled in by the dataset author (location, camera, date, number of photos, scene description)._  
**Dataset license:** _Not yet specified. Choose a license only after confirming ownership and permission for every image._

COLMAP and OpenSplat are third-party projects; consult their own licenses and documentation. This repository does not redistribute LibTorch or OpenSplat.

## References

- [COLMAP documentation](https://colmap.github.io/)
- [OpenSplat repository and usage](https://github.com/WebODM/OpenSplat)
- [Original 3D Gaussian Splatting paper](https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/)
