#!/usr/bin/env bash
set -euo pipefail

if ! command -v colmap >/dev/null 2>&1; then
  echo 'COLMAP not found. Install: sudo apt install colmap' >&2
  exit 1
fi

DATASET="${1:-dataset/test_scene}"
mkdir -p "$DATASET/sparse"
if [[ ! -d "$DATASET/images" ]]; then
  echo "Missing input images directory: $DATASET/images" >&2
  exit 1
fi
if [[ -e "$DATASET/database.db" ]]; then
  echo "Database already exists: $DATASET/database.db" >&2
  echo 'Use a fresh dataset directory to rerun reconstruction from scratch.' >&2
  exit 1
fi
if [[ -n "$(find "$DATASET/sparse" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "Sparse directory is not empty: $DATASET/sparse" >&2
  echo 'Use a fresh directory to avoid mixing existing reconstructions.' >&2
  exit 1
fi
colmap feature_extractor \
  --database_path "$DATASET/database.db" \
  --image_path "$DATASET/images" \
  --ImageReader.single_camera 1 \
  --SiftExtraction.use_gpu 0 \
  --SiftExtraction.max_image_size 1200 \
  --SiftExtraction.num_threads 4
colmap exhaustive_matcher \
  --database_path "$DATASET/database.db" \
  --SiftMatching.use_gpu 0
colmap mapper \
  --database_path "$DATASET/database.db" \
  --image_path "$DATASET/images" \
  --output_path "$DATASET/sparse"
echo "Reconstruction finished. Inspect $DATASET/sparse/0 and verify cameras.bin, images.bin, points3D.bin exist."
