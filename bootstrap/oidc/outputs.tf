output "github_oidc_provider_arn" { value = aws_iam_openid_connect_provider.github.arn }
output "github_actions_dev_role_arn" { value = aws_iam_role.dev.arn }
output "github_actions_stage_role_arn" { value = aws_iam_role.stage.arn }
output "github_actions_prod_role_arn" { value = aws_iam_role.prod.arn }
