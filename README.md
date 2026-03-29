# Terraform Ops Repo Complete

운영 최적화 구조의 Terraform 저장소 예시입니다.

포함 내용:
- `bootstrap/oidc`: GitHub Actions OIDC provider + dev/stage/prod IAM role 생성
- `modules/`: network, security, compute, database, alb
- `live/`: dev, stage, prod 환경별 root module
- `.github/workflows/`: PR plan, dev apply, stage apply, prod apply
- `docs/`: AWS OIDC 연결 및 브랜치 전략 문서
- `.vscode/`: VS Code 설정
- `scripts/`: 로컬 실행 스크립트

## 권장 브랜치 전략
- `main`: 보호 브랜치
- `feature/*`: 기능 작업
- `hotfix/*`: 긴급 수정
- `release-*` 태그: stage 배포 트리거

## 환경 승격 정책
- PR 생성: dev / stage / prod plan 실행
- main merge: dev 자동 apply
- release tag 또는 workflow_dispatch: stage apply
- workflow_dispatch + GitHub environment 승인: prod apply

## 1. 먼저 bootstrap/oidc 배포
```bash
cd bootstrap/oidc
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

apply 후 output으로 나온 role ARN을 GitHub Actions workflow의 `aws_role_arn`에 넣거나, 이미 예시 role 이름을 그대로 쓰면 됩니다.

## 2. GitHub Environments 생성
GitHub repository settings에서 아래 environments를 생성합니다.
- `dev`
- `stage`
- `prod`

권장:
- stage: reviewer 1명 이상
- prod: reviewer 1명 이상 + self-review 방지

## 3. live 환경 실행
예: dev
```bash
cd live/dev/app
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

## 주의
- `create_alb = true` 이면 두 번째 public subnet이 필요합니다.
- `create_rds = true` 이면 두 번째 data subnet이 필요합니다.
- 실제 운영에서는 role 권한을 `*` 대신 리소스/태그 기준으로 더 좁히는 것이 좋습니다.
