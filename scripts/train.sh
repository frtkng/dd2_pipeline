#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/dd2-train.log) 2>&1

source /opt/conda/etc/profile.d/conda.sh
conda activate dd2
cd /opt/dd2/drivedreamer2

# データ同期 (事前 S3 推奨)
if [ -n "${PANDASET_S3_PREFIX:-}" ]; then
  mkdir -p /opt/dd2/data
  aws s3 sync "$PANDASET_S3_PREFIX" /opt/dd2/data
fi

python scripts/filter_and_preprocess.py --data_root /opt/dd2/data || true
python train.py --config configs/minimal_panda_l4.yaml | tee -a /var/log/dd2-train.log

ckpt=/opt/dd2/drivedreamer2/runs/panda/ckpt_latest.pt
if [ -f "$ckpt" ] && [ -n "${MODEL_S3_URI:-}" ]; then
  aws s3 cp "$ckpt" "$MODEL_S3_URI"
fi