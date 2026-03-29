#!/usr/bin/env bash
set -euo pipefail
terraform plan -var-file=terraform.tfvars -out=tfplan
