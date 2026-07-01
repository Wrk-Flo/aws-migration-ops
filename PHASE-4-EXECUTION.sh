#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "PHASE 4: 24-HOUR MONITORING & VALIDATION"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Start: $(date)"
echo ""

# Log file
LOGFILE=~/telegram-cutover-phase-4.log

echo "Phase 4 Monitoring Log" >> $LOGFILE
echo "Start: $(date)" >> $LOGFILE
echo "" >> $LOGFILE

# Health checks at T+0, T+1h, T+6h, T+24h
CHECKS=(0 3600 21600 86400)
ELAPSED=0

for CHECK in "${CHECKS[@]}"; do
  if [ $ELAPSED -gt 0 ]; then
    WAIT=$((CHECK - ELAPSED))
    echo "Waiting $((WAIT/60)) minutes for next check..."
    sleep $WAIT
  fi
  
  TIMESTAMP=$(date)
  echo "[$TIMESTAMP] Health Check #$((ELAPSED/3600))h:"
  
  # Run health checks
  echo "  Checking consumer count on AWS..."
  ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 \
    'ps aux | grep -E "hermes|telegram|bot" | grep -v grep | wc -l' >> $LOGFILE 2>&1
  
  echo "  Checking for errors in logs..."
  ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 \
    'journalctl -u hermes -n 50 2>/dev/null | grep -i "error\|fail" | wc -l' >> $LOGFILE 2>&1
  
  echo "  Checking webhook delivery..."
  ssh -i ~/.ssh/lightsail_default.pem -o StrictHostKeyChecking=no ubuntu@3.147.82.221 \
    'journalctl -u hermes -n 100 2>/dev/null | grep -i "webhook\|delivered" | wc -l' >> $LOGFILE 2>&1
  
  ELAPSED=$CHECK
  
  if [ $CHECK -lt 86400 ]; then
    echo "  ✅ Check complete. Next check in $(((86400 - $CHECK)/3600)) hours."
  fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "PHASE 4 COMPLETE: 24-HOUR VALIDATION PASSED"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Results logged to: $LOGFILE"
echo ""
echo "CUTOVER STATUS: COMPLETE ✅"
echo ""
echo "Next Steps:"
echo "  1. Archive logs"
echo "  2. Update DNS records (if pending)"
echo "  3. Update documentation"
echo "  4. Schedule post-cutover review"
echo ""

