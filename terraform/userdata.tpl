#!/bin/bash
set -euxo pipefail
exec > /var/log/user-data.log 2>&1
systemctl enable --now amazon-ssm-agent || true
logger "SSM READY"