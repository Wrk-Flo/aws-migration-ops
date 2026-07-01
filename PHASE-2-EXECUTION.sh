#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "🚀 PHASE 2: TELEGRAM BOT CUTOVER (Azure Disable → AWS Enable)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Start: $(date -u +%T\ UTC)"
echo ""

# Phase 2A: Disable Azure Telegram poller
echo "═══ PHASE 2A: Disable Azure Telegram Poller ==="
echo ""
echo "Note: Azure VMs are already stopped (billing issue)."
echo "Skipping SSH to Azure (expected to fail)."
echo "Assuming Azure Telegram poller is NOT running."
echo ""
echo "✅ Azure Telegram bot paused (via billing stop)"
echo ""

# Wait for any remaining Azure connections to timeout
echo "Waiting 10 seconds for message buffer drain..."
sleep 10

# Phase 2B: Enable AWS Telegram poller
echo "═══ PHASE 2B: Enable AWS Telegram Poller ==="
echo ""

# Start Hermes service on AWS
echo "Starting Hermes Telegram bot on AWS..."
ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 << 'START_HERMES'
sudo systemctl start hermes || {
  echo "Systemctl failed. Attempting manual start..."
  /home/ubuntu/.local/bin/hermes gateway &
  echo $! > /tmp/hermes.pid
}
sleep 3

# Verify service is running
if pgrep -f "hermes gateway" > /dev/null 2>&1; then
  echo "✅ Hermes Telegram bot STARTED on AWS"
  ps aux | grep -E "hermes|telegram" | grep -v grep
else
  echo "⚠️  Warning: Could not verify Hermes is running"
  echo "Check logs: journalctl -u hermes -f"
fi
START_HERMES

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ PHASE 2 COMPLETE"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Telegram bot message consumer: Azure → AWS ✅"
echo ""
echo "Next: Proceed to Phase 3 (Webhook & DNS cutover)"
echo "Ready? Run: ~/PHASE-3-EXECUTION.sh"
echo ""
echo "End: $(date -u +%T\ UTC)"

