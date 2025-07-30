# DriveDreamer‑2 Pipeline (IaC + SSM)

> **One‑command GPU training on AWS** for DriveDreamer‑2 using PandaSet Core‑40. Terraform builds everything, scripts live in S3, **SSM RunCommand** orchestrates training – no manual SSH required.

---

## ✨ Features

* **IaC** – Terraform 1.6 + AWS provider v5
* **Secure automation** – SSM RunCommand / CloudWatch Logs, no inbound 22/tcp
* **Makefile launcher** – `make apply → setup → train → logs`
* **Spot‑friendly** – optional watchdog script to catch ITN & upload ckpt
* **Full teardown** – `make destroy` wipes all resources

---

## 🗂 Repo Layout

```
terraform/        # main.tf, variables.tf, outputs.tf, userdata.tpl
scripts/
  ├─ setup.sh     # conda env + PyTorch + repos
  ├─ train.sh     # preprocess & training
  └─ spot_watchdog.sh (optional)
Makefile          # command shortcuts
README.md         # you are here
```

---

## 🚀 Quick Start

1. **Clone & configure**

   ```bash
   git clone https://github.com/<you>/dd2-pipeline.git
   cd dd2-pipeline
   export TF_VAR_bucket=dd2-model-bucket   # ← your unique S3 bucket
   # optional SSH key
   # export TF_VAR_key_name=mykeypair
   ```
2. **Provision infrastructure**

   ```bash
   make init apply   # Terraform build (~3‑5 min)
   ```
3. **Kick training**

   ```bash
   make setup train  # GPU env + DriveDreamer‑2 training (~30‑40 min to start)
   make logs         # follow progress in CloudWatch
   ```
4. **Clean up**

   ```bash
   make destroy      # nuke everything when done
   ```

---

## ⏱ Time‑line

| Stage                    | ETA                   |
| ------------------------ | --------------------- |
| Terraform apply          | 3‑5 min               |
| `setup.sh` (drivers/env) | 5‑10 min              |
| Data sync + preprocess   | 15‑20 min             |
| **Training start**       | **\~30‑40 min total** |

---

## 🔧 Make Targets

| Target         | What it does                               |
| -------------- | ------------------------------------------ |
| `make init`    | `terraform init`                           |
| `make apply`   | Provision all AWS resources                |
| `make sync`    | Upload `scripts/` to S3 bucket             |
| `make setup`   | Run `setup.sh` on EC2 via SSM              |
| `make train`   | Run `train.sh` (42 h World‑Model training) |
| `make logs`    | Tail CloudWatch training logs              |
| `make destroy` | Full teardown                              |

---

## 📑 Variables (`terraform/variables.tf`)

| Name              | Default          | Comment                        |
| ----------------- | ---------------- | ------------------------------ |
| `region`          | `ap-northeast-1` | AWS region                     |
| `bucket`          | *(required)*     | S3 bucket for scripts & model  |
| `project`         | `DD2`            | Tag prefix                     |
| `key_name`        | ""               | SSH key (empty = SSH disabled) |
| `instance_type`   | `g6.xlarge`      | GPU instance                   |
| `instance_volume` | `200`            | Root EBS GB                    |

---

## 🔐 Credentials

* **AWS** – export `AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY` or use a named profile.
* **Kaggle** – set env `KAGGLE_JSON="{\"username\":\"…\",\"key\":\"…\"}"` before `make train` *or* pre‑upload PandaSet to S3.

---

## 📝 License

MIT License – see `LICENSE` file.

## 🤝 Contributing

PRs & issues welcome! Open an issue to discuss major changes first.

## 🙏 Acknowledgements

* [DriveDreamer‑2](https://github.com/f1yfisher/DriveDreamer2)
* AWS Deep Learning AMI
* PandaSet Core‑40
