# Telegram Bot Cutover Checklist

**Cutover Date:** ________________  
**Owner:** ________________  
**On-Call Monitor:** ________________  

---

## Pre-Cutover Validation (T-2h)

- [ ] Verify Azure VM stopped: `az vm show ... --query powerState` → `deallocated`
- [ ] Verify Mac LaunchAgent disabled: `launchctl list | grep hermes` → no output
- [ ] Verify OS1 bridge disabled: `launchctl list | grep os1` → no output
- [ ] AWS SSH access working: `ssh hermes-prod-aws -c "uname -a"`
- [ ] AWS disk space OK: `ssh hermes-prod-aws -c "df -h /home/moses/" | grep "/" | tail -1` → > 50% free
- [ ] AWS system load low: `ssh hermes-prod-aws -c "uptime"` → < 2.0
- [ ] Current DNS target documented: `dig eden.wrkflo.biz +short` → ________________
- [ ] Cloudflare API token available (not printed)
- [ ] Telegram bot token confirmed set in AWS `~/.hermes/.env`

**Owner Sign-Off:** ________________  Date: ________________

---

## Webhook Infrastructure Setup (T-1.5h)

- [ ] SSH to AWS, generate webhook secret: `openssl rand -hex 32`
- [ ] Add to `~/.hermes/.env`:
  ```
  TELEGRAM_WEBHOOK_SECRET=[generated-secret]
  TELEGRAM_WEBHOOK_URL=https://eden.wrkflo.biz/telegram
  TELEGRAM_WEBHOOK_PORT=8443
  ```
- [ ] Verify env load: `ssh hermes-prod-aws -c "source ~/.hermes/.env && echo OK"`
- [ ] Dry-run gateway startup: `timeout 30s ... hermes-gateway ... 2>&1 | tee /tmp/test.log`
- [ ] Check for webhook success: `grep "Connected to Telegram (webhook mode)" /tmp/test.log`
- [ ] Test egress to Telegram: `ssh hermes-prod-aws -c "curl -I https://api.telegram.org/"`
- [ ] Verify AWS security group allows port 8443 inbound (or 443 via Cloudflare)
- [ ] Dry-run passed (no errors in logs)

**Status:** ✓ Ready to proceed  /  ⚠ Issue: ________________

---

## DNS & Tunnel Cutover (T-0.5h)

- [ ] Document old DNS target (for rollback): ________________
- [ ] Update Cloudflare tunnel: old endpoint → `3.147.82.221` (AWS IP)
- [ ] Verify Cloudflare API returned `"success": true`
- [ ] Wait for DNS propagation: `dig eden.wrkflo.biz +short` → `3.147.82.221`
- [ ] Poll every 30 seconds for up to 5 minutes (TTL may vary)
- [ ] Test HTTPS to new endpoint: `curl -I https://eden.wrkflo.biz/`
- [ ] Expected response: HTTP 200, 502, or similar (not timeout/unreachable)
- [ ] Check Telegram webhook info (before gateway start):
  ```
  curl -s "https://api.telegram.org/bot[token]/getWebhookInfo" | jq .
  ```
- [ ] DNS confirmed pointing to AWS

**Time of DNS Cutover:** ________________  (UTC)

---

## Gateway Startup & Initial Monitoring (T+0)

- [ ] SSH to AWS: `systemctl start hermes-gateway`
- [ ] Check status: `systemctl status hermes-gateway | head -10`
- [ ] Tail logs: `journalctl -u hermes-gateway -f --lines=50`
- [ ] Look for: `[telegram] Connected to Telegram (webhook mode)` within 10 seconds
- [ ] Send test message via Telegram bot (from phone/web)
- [ ] Check logs for webhook POST: `grep -i "webhook.*post\|received" /var/log/...`
- [ ] Response received and logged ✓
- [ ] No duplicate-consumer errors in logs ✓

**Gateway Start Time:** ________________  (UTC)

---

## 1-Hour Checkpoint (T+1h)

- [ ] Verify Azure still stopped: `az vm show ... --query powerState`
- [ ] Run AWS health check: `ssh hermes-prod-aws -c "/home/moses/.local/bin/hermes-vm-health-check"`
- [ ] Health check result: ________________ (expected: "ok healthy")
- [ ] Send 3–5 additional test messages over 30 min
- [ ] All responses logged and received ✓
- [ ] No long-polling fallback in logs: `grep -i "fallback\|getUpdates" ...` → no results
- [ ] No webhook errors: `grep -i "webhook.*error" ...` → no results
- [ ] Message count: ________________ (expected: ≥ 3)

**Status:** ✓ Nominal  /  ⚠ Anomaly: ________________

---

## 6-Hour Check (T+6h)

- [ ] Verify no duplicate consumer errors in logs
- [ ] Check Mac LaunchAgent still disabled: `launchctl list | grep hermes` → no output
- [ ] Confirm Azure VM still stopped
- [ ] Message volume continuing: ________________ messages in last 1 hour
- [ ] No SSL/certificate errors: `grep -i "ssl\|certificate.*error" ...` → no results
- [ ] No memory leaks: tail last 50 log lines, check for `OOM` or `memory.*error` → none
- [ ] Disk space still OK: ≥ 50% free

**Status:** ✓ Nominal  /  ⚠ Anomaly: ________________

---

## 24-Hour Soak Completion (T+24h)

- [ ] **No interruptions** during 24-hour window ✓
- [ ] Total message count (24h): ________________
- [ ] Error count (24h): `journalctl -u hermes-gateway --since "24 hours ago" | grep -c ERROR` → ________________
- [ ] Uptime: `systemctl status hermes-gateway | grep Active` → ________________ (expected: running)
- [ ] No disconnect events: `grep -c "disconnect" ...` → ________________ (expected: 0)
- [ ] Azure remains stopped and unchanged
- [ ] Mac LaunchAgent remains disabled
- [ ] DNS still resolves to AWS: `dig eden.wrkflo.biz +short` → `3.147.82.221`
- [ ] Telegram webhook info shows no recent errors:
  ```
  curl -s "https://api.telegram.org/bot[token]/getWebhookInfo" | jq '.result.last_error_date'
  ```
  → ________________ (expected: null or very old timestamp)

**Soak Status:** ✓ PASS  /  ⚠ FAIL (Issue: ________________)

---

## Post-Soak Decommission Decision (T+24h+)

### If Soak PASSED:

- [ ] Owner approves decommission of Azure resources
- [ ] Stop Azure VM: `az vm stop --resource-group GS-BTC-RG --name hermes-prod-vm`
- [ ] Document Azure resource IDs (for audit trail): ________________
- [ ] Optional: Delete Azure VM (if not needed for other services): `az vm delete ...`
- [ ] Update operational docs to remove Azure references
- [ ] Set recurring health check reminder (daily, weekly)

### If Soak FAILED:

- [ ] Document failure root cause: ________________
- [ ] Execute rollback procedure (see main plan, "Rollback Procedures")
- [ ] Re-enable Azure gateway: `az vm start ...`
- [ ] Revert Telegram webhook: `python3 update_telegram_webhook.py --webhook-url ""`
- [ ] Revert DNS: `eden.wrkflo.biz` → old endpoint
- [ ] Schedule postmortem and retry window (≥ 7 days)

**Final Decision:** ✓ Decommission  /  ⚠ Rollback  Date: ________________

---

## Post-Cutover Ongoing Monitoring

### Daily (First 7 Days)
- [ ] Gateway status: `systemctl status hermes-gateway | grep Active`
- [ ] Recent errors: `journalctl -u hermes-gateway --since "24 hours ago" | grep -i error | wc -l`
- [ ] Disk usage: `df -h /home/moses/ | tail -1`

### Weekly (Ongoing)
- [ ] Full health check: `ssh hermes-prod-aws -c "/home/moses/.local/bin/hermes-vm-health-check"`
- [ ] Message volume trend: compare to previous week
- [ ] Zero duplicate consumers: no logs mentioning "conflicting.*poller" or similar

### Emergency Hotline
- **Contact:** ________________
- **Escalation:** ________________

---

**Cutover Completed:** ________________  (UTC)  
**Validated By:** ________________  
**Business Approved:** ________________
