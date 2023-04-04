# Infrastructure by Terraform

## Deploy
aws-vault only
```
aws-vault exec jitsudan
terraform init
terraform apply
```
aws-vualt + Docker
```
aws-vault exec jitsudan
docker compose up
docker compose run --rm terraform init
```

## セキュリティチェック
```
Dockle : 
git-secrets : 
Trivy : 
```

## パイプライン
https://qiita.com/okubot55/items/6cb2dccdd00dfb0b3335

### 0. コンテナレジストリとコードリポジトリ作成
```
cd resource/enviroments/dev
terraform apply --target=module.ecr
terraform apply --target=module.codecommit
```

### レジストリへ認証
```
aws-vault exec jitsudan
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
aws ecr --region ap-northeast-1 get-login-password | docker login --username AWS --password-stdin https://${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/
```


## 1 Network
```
terraform apply --target=module.network
```

## 3 ECS
```
terraform apply --target=module.ecs
```

## 2 ALB
```
terraform apply --target=module.alb
```

## 3 Pipeline



## 8 Secret Manager
aws cloudformation deploy \
--stack-name sbctr-secrets \
--template-file secrets.yml \
--capabilities CAPABILITY_NAMED_IAM

## 9 Backend2
aws cloudformation deploy \
--stack-name sbcntr-backend-stack \
--template-file backend2.cf.yml \
--capabilities CAPABILITY_NAMED_IAM

## 10 CodeCommit
git remote -v
git remote set-url origin https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/sbcntr-backend



aws cloudformation deploy \
--stack-name sbcntr-code \
--template-file code.yml \
--capabilities CAPABILITY_NAMED_IAM


## 11 base 共通イメージ
docker image pull golang:1.16.8-alpine3.13

docker image ls --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

aws ecr --region ap-northeast-1 get-login-password | docker login --username AWS --password-stdin https://${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/

docker image tag golan:1.16.8-alpine3.13 ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/sbcntr-base:golang1.16.8-alpine3.13


docker image push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/sbcntr-base:golang1.16.8-alpine3.13

## 12 確認
hello world 修正
踏み台から curl


## 13 Log Router
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

docker image build -t sbcntr-log-router .

aws ecr --region ap-northeast-1 get-login-password | docker login --username AWS --password-stdin https://${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/

docker image tag sbcntr-log-router:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/sbcntr-base:log-router

docker image push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/sbcntr-base:log-router

## 14 ログ保管場所作成
aws cloudformation deploy \
--stack-name sbcntr-log \
--template-file log.yml \
--capabilities CAPABILITY_NAMED_IAM

## 15 backend3
aws cloudformation deploy \
--stack-name sbcntr-backend-stack \
--template-file backend3.cf.yml \
--capabilities CAPABILITY_NAMED_IAM


## 15.5 確認
curl
s3確認


## Bastion
SystemsManagerインスタンスティアをアドバンスドに変更


git clone https://github.com/uma-arai/sbcntr-resources.git

docker image build -t fargate-bastion .

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)


aws ecr --region ap-northeast-1 get-login-password | docker login --username AWS --password-stdin https://${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/


docker image tag fargate-bastion:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/sbcntr-base:bastion

docker image push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/sbcntr-base:bastion

aws cloudformation deploy \
--stack-name sbctr-bastion \
--template-file bastion.yml
