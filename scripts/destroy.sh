#!/usr/bin/env bash
set -euo pipefail
terraform destroy -var-file=terraform.tfvars
