variable "region"          { default = "ap-northeast-1" }
variable "project"         { default = "DD2" }
variable "bucket"          { description = "S3 bucket for scripts & outputs" }
variable "key_name"        { description = "(optional) SSH key pair name", default = "" }
# variable "instance_type"   { default = "g6.xlarge" } # 学習コスト安
variable "instance_type"   { default = "g4dn.xlarge" } # 環境のdebug時
variable "instance_volume" { default = 200 }