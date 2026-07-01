#!/bin/bash
# Quick start for next execution session

echo "════════════════════════════════════════════════════════════"
echo "🚀 AWS MIGRATION - QUICK START (Next Session)"
echo "════════════════════════════════════════════════════════════"
echo ""

# Test SSH access
echo "Testing SSH access to all instances..."
ssh hermes-prod-aws "echo '✅ hermes-prod-aws ready'"
ssh dev-workspace-aws "echo '✅ dev-workspace-aws ready'"
ssh openclaw-global-sentinel-aws "echo '✅ openclaw-global-sentinel-aws ready'"

echo ""
echo "All instances accessible! Ready to proceed with:"
echo ""
echo "NEXT STEPS:"
echo "1. Review documentation:"
echo "   cd ~/migration-ops"
echo "   cat PRINT-READY-CHECKLIST.md"
echo ""
echo "2. Execute Phase 1 validation:"
echo "   bash telegram-consumer-monitor.sh"
echo ""
echo "3. Execute Phase 2 (disable Azure, enable AWS):"
echo "   bash telegram-azure-disable.sh"
echo "   bash telegram-aws-enable.sh"
echo ""
echo "4. Execute Phase 3 (webhook & DNS):"
echo "   # See TEAM-EXECUTION-GUIDE.md for manual steps"
echo ""
echo "5. Monitor Phase 4 (24 hours):"
echo "   bash telegram-consumer-monitor.sh --watch"
echo ""
echo "════════════════════════════════════════════════════════════"

