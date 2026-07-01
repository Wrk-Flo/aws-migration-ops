#!/bin/bash
# Template for OpenClaw service environment on AWS  
# DO NOT commit this file to git
# Apply with: scp -i key.pem openclaw-env-template.sh ubuntu@IP:~/.openclaw.env

export OPENCLAW_SERVICE_NAME="openclaw-prod-aws"
export OPENCLAW_LOG_LEVEL="info"
export OPENCLAW_DATA_PATH="/data/openclaw"
export OPENCLAW_STATE_PATH="/data/openclaw/.openclaw"
export OPENCLAW_TRADING_ENABLED="false"  # Keep disabled during staging
export OPENCLAW_SENTINEL_ENABLED="false"  # Keep disabled during staging
export OPENCLAW_API_PORT="8081"
export OPENCLAW_ADMIN_KEY="[SET_FROM_VAULT]"
