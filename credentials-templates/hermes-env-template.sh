#!/bin/bash
# Template for Hermes service environment on AWS
# DO NOT commit this file to git
# Apply with: scp -i key.pem hermes-env-template.sh ubuntu@IP:~/.hermes.env
# Then source it in systemd service

export HERMES_SERVICE_NAME="hermes-prod-aws"
export HERMES_LOG_LEVEL="info"
export HERMES_TELEGRAM_TOKEN="[SET_FROM_VAULT]"
export HERMES_TELEGRAM_CHAT_ID="[SET_FROM_VAULT]"
export HERMES_TELEGRAM_WEBHOOK_URL="[SET_FROM_VAULT]"
export HERMES_WEBHOOK_PORT="8080"
export HERMES_CONFIG_PATH="/home/ubuntu/.hermes/config.yaml"
export HERMES_STATE_PATH="/home/ubuntu/.hermes/gateway_state.json"
export HERMES_DATABASE_URL="[SET_FROM_VAULT]"
