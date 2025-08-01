#!/bin/bash
set -euxo pipefail
# exec > >(tee -a /var/log/dd2-setup.log) 2>&1 #CloudWatchへログ出力のためコメントアウト

# 0. Miniconda install
cd /tmp
curl -fsSLo miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
if [ ! -d /opt/conda ]; then
  bash miniconda.sh -b -p /opt/conda
else
  echo "/opt/conda already exists. Skipping Miniconda install."
fi
export PATH="/opt/conda/bin:$PATH"
eval "$(/opt/conda/bin/conda shell.bash hook)"

# 🆕 ToS に非対話で同意
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Python env
conda create -y -n dd2 python=3.10

export PATH="/opt/conda/bin:$PATH"
eval "$(/opt/conda/bin/conda shell.bash hook)"

# 1. Conda
source /opt/conda/etc/profile.d/conda.sh || true
conda create -y -n dd2 python=3.10
conda activate dd2

# 2. PyTorch + 依存
pip install --upgrade pip
pip install torch==2.3.0+cu121 torchvision --index-url https://download.pytorch.org/whl/cu121
pip install pandas h5py tqdm omegaconf accelerate scikit-image opencv-python boto3 kaggle

# 3. ソース取得
if [ ! -f drivedreamer2/train.py ]; then
  rm -rf drivedreamer2  # 途中までcloneされた不完全ディレクトリを削除
  git clone https://github.com/f1yfisher/DriveDreamer2.git drivedreamer2
fi

if [ ! -d drivedreamer2/third_party/pandaset-devkit ]; then
  git clone https://github.com/scaleapi/pandaset-devkit.git drivedreamer2/third_party/pandaset-devkit
fi

# debug log
ls -l /opt/dd2/drivedreamer2 | tee /tmp/dd2_setup_files.log

# 4. Kaggle 認証 (任意)
if [ -n "${KAGGLE_JSON:-}" ]; then
  mkdir -p ~/.kaggle
  echo "$KAGGLE_JSON" > ~/.kaggle/kaggle.json
  chmod 600 ~/.kaggle/kaggle.json
fi