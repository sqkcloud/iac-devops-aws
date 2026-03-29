# AWS OIDC 연결 가이드

## 개요
GitHub Actions가 AWS 장기 access key 없이 OIDC 토큰으로 IAM Role을 Assume 하도록 구성합니다.

핵심 값:
- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

## 순서
1. `bootstrap/oidc` Terraform apply
2. GitHub repo에 `dev`, `stage`, `prod` environments 생성
3. workflow의 role ARN 확인
4. PR / merge / tag / manual dispatch로 배포

## trust policy 핵심
- `token.actions.githubusercontent.com:aud = sts.amazonaws.com`
- `token.actions.githubusercontent.com:sub` 를 repo/branch/tag/environment 기준으로 제한

## 예시 sub
- `repo:ORG/REPO:pull_request`
- `repo:ORG/REPO:ref:refs/heads/main`
- `repo:ORG/REPO:ref:refs/tags/release-*`
- `repo:ORG/REPO:environment:dev`
- `repo:ORG/REPO:environment:stage`
- `repo:ORG/REPO:environment:prod`
