#!/usr/bin/env bash
set -euo pipefail
terraform init -backend-config=backend.hcl
