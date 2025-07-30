TF_DIR  := terraform
BUCKET  := $(shell terraform -chdir=$(TF_DIR) output -raw bucket 2>/dev/null)
INST_ID := $(shell terraform -chdir=$(TF_DIR) output -raw instance_id 2>/dev/null)

.PHONY: init apply destroy sync setup train logs

init:
	terraform -chdir=$(TF_DIR) init

apply: ## インフラ構築
	terraform -chdir=$(TF_DIR) apply -auto-approve

sync:   ## scripts → S3 へ反映
	aws s3 sync scripts s3://$(BUCKET)/DD2/scripts --exact-timestamps

setup: sync ## GPU ドライバ & 環境構築
	aws ssm send-command \
	  --instance-ids $(INST_ID) \
	  --document-name AWS-RunShellScript \
	  --cloud-watch-output-config CloudWatchLogGroupName=/dd2/setup,CloudWatchOutputEnabled=true \
	  --parameters commands='["aws s3 cp s3://$(BUCKET)/DD2/scripts/setup.sh /tmp/setup.sh","chmod +x /tmp/setup.sh","/tmp/setup.sh"]'

train: ## 学習実行
	aws ssm send-command \
	  --instance-ids $(INST_ID) \
	  --document-name AWS-RunShellScript \
	  --cloud-watch-output-config CloudWatchLogGroupName=/dd2/train,CloudWatchOutputEnabled=true \
	  --parameters commands='["export MODEL_S3_URI=s3://$(BUCKET)/DD2/outputs/ckpt_latest.pt","aws s3 cp s3://$(BUCKET)/DD2/scripts/train.sh /tmp/train.sh","chmod +x /tmp/train.sh","/tmp/train.sh"]' \
	  --timeout-seconds 172800

logs: ## CloudWatch Logs を tail
	aws logs tail /dd2/train --follow

destroy: ## 後片付け
	terraform -chdir=$(TF_DIR) destroy -auto-approve