# Next.js + ECS Fargate

## Development
### ローカル開発
Build
```
docker build -t nextjs-docker .
docker run -p 3000:3000 nextjs-docker
```
実行
```
docker compose up -d
```
確認
```
docker compose ps
docker exec -it nextjs-docker-next-1 sh
```
シャットダウン
```
docker compose down
```


### レジストリへイメージ登録
```
cd nextjs-docker
aws-vault exec jitsudan
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
GIT_COMMIT_ID=$(git log --format="%H" -n 1)
docker image build -t nextjs-docker:"${GIT_COMMIT_ID}" .
docker image tag nextjs-docker:"${GIT_COMMIT_ID}" ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/next-docker:"${GIT_COMMIT_ID}"
docker image push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/next-docker:"${GIT_COMMIT_ID}"
```

### CodeCommit へ push (GRC)し、ECR/ECSへデプロイ
GRCインストール
```
pip install git-remote-codecommit

```

clone
```
aws-vault exec jitsudan
git clone codecommit::ap-northeast-1://next-docker
```

push
```
aws-vault exec jitsudan
git push
```

最初だけ登録
```
git add .
git commit -m "first commit"
git remote add codecommit https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/next-docker
git branch -M main
git push --set-upstream codecommit main
```

