terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  project = var.project
  tags    = { Project = local.project }
}

# --- S3 バケット (scripts & outputs) ---
resource "aws_s3_bucket" "dd2" {
  bucket        = var.bucket
  force_destroy = true
  tags          = local.tags
}

# --- IAM ロール & ポリシー (SSM + S3) ---
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dd2" {
  name               = "${local.project}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.dd2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "s3" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.dd2.arn, "${aws_s3_bucket.dd2.arn}/*"]
  }
}

resource "aws_iam_policy" "s3" {
  name   = "${local.project}-s3"
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.dd2.name
  policy_arn = aws_iam_policy.s3.arn
}

resource "aws_iam_instance_profile" "dd2" {
  name = "${local.project}-profile"
  role = aws_iam_role.dd2.name
}

# --- ネットワーク (default VPC) ---

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 自分の IP を自動取得して SSH を限定 (key_name が空ならポート 22 不許可)
data "http" "my_ip" { url = "https://checkip.amazonaws.com" }

resource "aws_security_group" "dd2" {
  name_prefix = "${local.project}-sg-"
  description = "DD2 allow SSH (optional)"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.key_name == "" ? [] : [1]
    content {
      description = "SSH from my IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
    }
  }

  tags = local.tags
}

# --- 最新 Deep Learning AMI (Ubuntu 22.04 + PyTorch) ---
data "aws_ami" "dlami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Deep Learning OSS Nvidia Driver AMI GPU PyTorch*Ubuntu 22.04*"]
  }
}

# --- EC2 インスタンス (GPU) ---
resource "aws_instance" "dd2" {
  ami                    = data.aws_ami.dlami.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.dd2.name
  subnet_id              = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids = [aws_security_group.dd2.id]
  key_name               = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_size = var.instance_volume
    volume_type = "gp3"
  }

  user_data_base64 = base64encode(templatefile("${path.module}/userdata.tpl", {}))

  tags = merge(local.tags, { Name = "${local.project}-ec2" })
}

# --- scripts/ を S3 へ自動同期 (変更トリガ) ---

resource "null_resource" "sync_scripts" {
  triggers = {
    timestamp = timestamp()  # そのたびに更新させる（または外部でコントロール）
  }

  provisioner "local-exec" {
    command = "aws s3 sync ${path.module}/../scripts s3://${var.bucket}/DD2/scripts --exact-timestamps"
  }

  depends_on = [aws_s3_bucket.dd2, aws_instance.dd2]
}