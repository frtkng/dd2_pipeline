#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/dd2-setup.log) 2>&1

# 1. Conda
source /opt/conda/etc/profile.d/conda.sh || true
conda create -y -n dd2 python=3.10
conda activate dd2

# 2. PyTorch + 依存
pip install --upgrade pip
pip install torch==2.3.0+cu121 torchvision --index-url https://download.pytorch.org/whl/cu121
pip install pandas h5py tqdm omegaconf accelerate scikit-image opencv-python boto3 kaggle

# 3. ソース取得
mkdir -p /opt/dd2 && cd /opt/dd2
[ -d drivedreamer2 ] || git clone https://github.com/f1yfisher/DriveDreamer2.git drivedreamer2
[ -d drivedreamer2/third_party/pandaset-devkit ] || \
  git clone https://github.com/scaleapi/pandaset-devkit.git drivedreamer2/third_party/pandaset-devkit

# 4. Kaggle 認証 (任意)
if [ -n "${KAGGLE_JSON:-}" ]; then
  mkdir -p ~/.kaggle
  echo "$KAGGLE_JSON" > ~/.kaggle/kaggle.json
  chmod 600 ~/.kaggle/kaggle.json
fi