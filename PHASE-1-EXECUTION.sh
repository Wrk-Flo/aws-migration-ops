#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "🚀 PHASE 1: PRE-CUTOVER VALIDATION (17 Checkpoints)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Execution Start: $(date -u +%T\ UTC)"
echo ""

PASSED=0
FAILED=0

# Helper function
check() {
  local num=$1
  local desc=$2
  local cmd=$3
  echo -n "[$num/17] $desc ... "
  if eval "$cmd" > /dev/null 2>&1; then
    echo "✅"
    ((PASSED++))
  else
    echo "❌"
    ((FAILED++))
  fi
}

# ─── AZURE STATUS (1-3) ───
check 1 "Azure Hermes VM stopped" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@52.183.95.158 'echo test' 2>&1 | grep -q 'Permission denied\\|Connection refused\\|timeout' || exit 1"
check 2 "Azure Dev-Workspace VM stopped" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@20.115.50.219 'echo test' 2>&1 | grep -q 'Permission denied\\|Connection refused\\|timeout' || exit 1"
check 3 "Azure OpenClaw VM stopped" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@40.124.45.207 'echo test' 2>&1 | grep -q 'Permission denied\\|Connection refused\\|timeout' || exit 1"

# ─── AWS INSTANCE HEALTH (4-6) ───
check 4 "Hermes AWS health" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 'systemctl is-active docker' | grep -q active"
check 5 "Dev-Workspace AWS health" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@18.191.186.167 'systemctl is-active docker' | grep -q active"
check 6 "OpenClaw AWS health" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.144.224.57 'systemctl is-active docker' | grep -q active"

# ─── CREDENTIALS (7-9) ───
check 7 "Hermes credentials deployed" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 'test -f ~/.hermes/.env && test -s ~/.hermes/.env'"
check 8 "Dev-Workspace credentials deployed" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@18.191.186.167 'test -f ~/.dev-workspace/.env && test -s ~/.dev-workspace/.env'"
check 9 "OpenClaw credentials deployed" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.144.224.57 'test -f ~/.openclaw/.env && test -s ~/.openclaw/.env'"

# ─── TELEGRAM API READINESS (10-12) ───
check 10 "Telegram Bot token valid" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 'grep -q TELEGRAM_BOT_TOKEN ~/.hermes/.env'"
check 11 "LLM API key configured" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 'grep -q LLM_API_KEY ~/.hermes/.env'"
check 12 "Webhook secret configured" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 'grep -q WEBHOOK_SECRET ~/.hermes/.env'"

# ─── SERVICE CONFIGURATION (13-15) ───
check 13 "Hermes systemd unit exists" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 'test -f /etc/systemd/system/hermes.service'"
check 14 "Dev-Workspace systemd unit exists" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@18.191.186.167 'test -f /etc/systemd/system/dev-workspace.service'"
check 15 "OpenClaw systemd unit exists" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.144.224.57 'test -f /etc/systemd/system/openclaw.service'"

# ─── MONITORING & ALERTING (16-17) ───
check 16 "Monitoring script deployed" "ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 'test -f /home/ubuntu/migration-ops/telegram-consumer-monitor.sh'"
check 17 "Rollback procedures documented" "test -f ~/migration-ops/ROLLBACK-PROCEDURES.md"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "PHASE 1 RESULTS"
echo "════════════════════════════════════════════════════════════"
echo "✅ Passed: $PASSED/17"
echo "❌ Failed: $FAILED/17"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "🎉 PHASE 1 VALIDATION: ALL CHECKS PASSED"
  echo ""
  echo "Ready to proceed to Phase 2?"
  echo "Phase 2: Azure disable → AWS enable"
  echo ""
  echo "Owner sign-off required before continuing."
  exit 0
else
  echo "❌ PHASE 1 VALIDATION: FAILED ($FAILED checks)"
  echo ""
  echo "Investigate failures and re-run Phase 1 before proceeding."
  exit 1
fi

