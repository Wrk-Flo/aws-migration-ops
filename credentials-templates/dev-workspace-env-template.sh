#!/bin/bash
# Template for Dev Workspace environment on AWS
# DO NOT commit this file to git
# Apply with: scp -i key.pem dev-workspace-env-template.sh ubuntu@IP:~/.dev-workspace.env

export DEV_WORKSPACE_SERVICE_NAME="dev-workspace-aws"
export DEV_WORKSPACE_LOG_LEVEL="debug"
export DEV_WORKSPACE_PORT="8082"
export DEV_WORKSPACE_ADMIN_USERS="[SET_FROM_VAULT]"
export DEV_WORKSPACE_DATABASE_URL="[SET_FROM_VAULT]"
