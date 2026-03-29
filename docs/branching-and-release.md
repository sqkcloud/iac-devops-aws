# 브랜치 / 릴리스 전략

## 브랜치
- `main`: 보호 브랜치, 직접 push 금지
- `feature/*`: 일반 작업
- `hotfix/*`: 운영 긴급 수정

## 승격
- PR -> plan(dev/stage/prod)
- merge to main -> dev apply
- release-* tag 또는 workflow_dispatch -> stage apply
- workflow_dispatch + prod environment 승인 -> prod apply

## 권장 보호 규칙
- main에 PR 필수
- status check 필수
- CODEOWNERS 리뷰 필수
- stage/prod environment required reviewers
