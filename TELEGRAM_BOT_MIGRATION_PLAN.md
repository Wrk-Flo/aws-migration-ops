# Telegram Bot Migration Plan: Azure VM → AWS Lightsail Cutover

**Date Prepared:** 2026-07-01  
**Author:** Copilot CLI  
**Status:** Design (Ready for Owner Review)  
**Constraint:** Single Telegram poller—duplicate consumers break the bot.

---

## Executive Summary

This plan migrates the Hermes Telegram gateway from stopped Azure VM (`hermes-prod-vm`) to active AWS Lightsail (`hermes-prod-aws: 3.147.82.221`). The operation involves:

1. **DNS routing** via Cloudflare tunnel (eden.wrkflo.biz)
2. **Webhook URL migration** on Telegram Bot API
3. **Credential injection** (bot token + webhook secret)
4. **24-hour soak period** before decommissioning Azure resources

**Critical Safety Gate:** Mac and Azure VMs are already locked out of Telegram polling (via LaunchAgent disablement in June 2026). Only AWS Hermes will poll.

---

## Current State (Verified 2026-07-01)

### Source: Azure VM (hermes-prod-vm)
- **Status:** Stopped (billing warning: VMStoppedToWarnSubscription)
- **Hermes Service:** `hermes-gateway.service` (not running while VM stopped)
- **Polling Mode:** Was using Telegram `getUpdates` long-polling
- **Mac Dependency:** `ai.hermes.gateway` LaunchAgent disabled since 2026-06-28
- **OS1 Bridge:** `com.os1.telegram-approval-bridge` and `com.os1.autopilot.watchdog` also disabled

### Target: AWS Lightsail (hermes-prod-aws)
- **Status:** Running
- **IP Address:** 3.147.82.221
- **RAM/Disk:** 7.6 GB / 154 GB
- **Hermes Repo:** Synced (needs credential injection)
- **Service:** `hermes-gateway.service` needs to be enabled and started
- **Polling Mode:** Will use webhook when configured

### DNS/Tunnel (eden.wrkflo.biz)
- **Provider:** Cloudflare tunnel
- **Current Route:** Likely points to Hetzner or previous VM endpoint
- **Target Route:** Will point to AWS Lightsail instance (3.147.82.221)
- **Status:** Already mentioned in pasteboard as "CUTOVER PHASE" candidate

### Mac Hermes (localhost)
- **Status:** LaunchAgent `ai.hermes.gateway` disabled/stopped
- **Polling:** NOT polling (critical)
- **SSH Access:** Ready for remote VM operations

---

## Local Configuration Review

### ~/.hermes/config.yaml (Mac)
**Findings:**
- Telegram section exists (line 468–472): `reactions: false`, no webhook URL configured
- Display platform includes `telegram: {streaming: true}` (line 302)
- TTS/STT providers configured but no Telegram-specific gateway config
- No local Cloudflare tunnel configuration (gateway runs on VM, not Mac)

**Status:** Mac config does NOT enable Telegram polling or webhook—this is correct for the current state.

### hermes-agent Repo: Telegram Documentation
**Key References:**
- `/website/docs/user-guide/messaging/telegram.md` — full setup guide
- **Webhook Mode** (lines 155+):
  - Requires `TELEGRAM_WEBHOOK_URL` env var
  - Requires `TELEGRAM_WEBHOOK_SECRET` (32-byte hex, generated via `openssl rand -hex 32`)
  - Optional `TELEGRAM_WEBHOOK_PORT` (default 8443)
  - Gateway log confirms: `[telegram] Connected to Telegram (webhook mode)`

- **Long Polling Mode** (default when no webhook URL):
  - Requires `TELEGRAM_BOT_TOKEN` only
  - Gateway uses Telegram `getUpdates` method
  - Runs continuously; can be resource-intensive

**Credential Security:**
- Bot token must NEVER be printed in logs or transcripts
- Webhook secret is equally sensitive
- Both should be stored in `~/.hermes/.env`, not `config.yaml`

---

## Cutover Sequence (Phase 1–4)

### Phase 1: Pre-Cutover Validation (Timing: T-2 hours)

**Goal:** Ensure AWS target is ready and Azure source is locked.

**Steps:**
1. **Azure VM Verification:**
   - Confirm `hermes-prod-vm` is stopped (no service running)
   - Confirm Mac LaunchAgent `ai.hermes.gateway` is disabled and unloaded
   - Confirm OS1 bridge/autopilot LaunchAgents are disabled
   - **Why:** Guarantees zero duplicate Telegram consumers in old locations

2. **AWS Instance Verification:**
   - SSH to `hermes-prod-aws` (3.147.82.221)
   - Verify `hermes-gateway.service` is NOT yet started
   - Check that `/home/moses/.hermes/config.yaml` exists and is valid
   - Verify disk space: `df -h /home/moses/`
   - Check system load: `uptime` (should be low)
   - **Health Check Command:**
     ```bash
     ssh hermes-prod-aws -c "systemctl status hermes-gateway || echo 'Service not yet started (expected)'"
     ```

3. **Cloudflare Tunnel Verification:**
   - Check current route for `eden.wrkflo.biz` via DNS:
     ```bash
     dig eden.wrkflo.biz CNAME +short
     curl -I https://eden.wrkflo.biz/ 2>&1 | head -5
     ```
   - Document current target (likely Hetzner IP or old endpoint)
   - Verify Cloudflare API token is available (for tunnel repoint)

4. **Telegram Bot Token & Secret Audit:**
   - Confirm bot token is set in `~/.hermes/.env` on AWS (do NOT print value)
   - Generate NEW webhook secret for AWS:
     ```bash
     TELEGRAM_WEBHOOK_SECRET=$(openssl rand -hex 32)
     echo "Webhook secret generated (not printed here)"
     ```
   - Store secret securely on AWS

**Owner Approval Gate:** ✋ Owner must verify Azure is locked before proceeding.

---

### Phase 2: Webhook Infrastructure Setup (Timing: T-1.5 hours)

**Goal:** Prepare AWS to receive Telegram webhook calls.

**Steps:**
1. **Configure AWS Hermes for Webhook Mode:**
   - SSH to `hermes-prod-aws`
   - Edit `~/.hermes/.env`:
     ```bash
     TELEGRAM_BOT_TOKEN=[bot-token-set]
     TELEGRAM_WEBHOOK_SECRET=[generated-secret]
     TELEGRAM_WEBHOOK_URL=https://eden.wrkflo.biz/telegram
     TELEGRAM_WEBHOOK_PORT=8443
     ```
   - Verify no syntax errors: `source ~/.hermes/.env && echo "OK"`

2. **Set Telegram Webhook URL via Bot API:**
   - This CANNOT be undone automatically—requires direct Telegram API call
   - Script provided below (Section: "Telegram Bot API Webhook Update Script")
   - **Command:**
     ```bash
     python3 update_telegram_webhook.py \
       --token "[bot-token]" \
       --webhook-url "https://eden.wrkflo.biz/telegram" \
       --secret "[webhook-secret]"
     ```
   - **Output:** Telegram responds with `{ok: true}` or an error
   - **Critical:** If this fails, Telegram continues using old endpoint (long polling resumes fallback)

3. **Test Webhook Server Startup (Dry Run):**
   - SSH to AWS, start gateway in foreground (short timeout):
     ```bash
     timeout 30s /home/moses/.local/bin/hermes-gateway --config ~/.hermes/config.yaml 2>&1 | \
       tee /tmp/gateway-startup-test.log
     ```
   - Check for errors: `grep -i "error\|fail\|webhook\|telegram" /tmp/gateway-startup-test.log`
   - Look for: `[telegram] Connected to Telegram (webhook mode)` in logs
   - **Expected:** Gateway starts, binds port 8443, reports successful Telegram connection
   - **Fallback:** If webhook fails, gateway still runs other platforms (safe to proceed)

4. **Network/Firewall Verification:**
   - Confirm AWS security group allows inbound HTTPS (443) from Cloudflare IPs
   - Confirm AWS instance has public IP or route to internet (for Telegram callback)
   - Test egress to Telegram API:
     ```bash
     curl -I https://api.telegram.org/ 2>&1 | head -5
     ```
   - Expected: HTTP 301 or similar (not connection timeout)

**Approval Gate:** ✋ Dry-run must complete without webhook errors.

---

### Phase 3: DNS & Tunnel Cutover (Timing: T-0.5 hours)

**Goal:** Route `eden.wrkflo.biz` to AWS, enabling Telegram to find the new webhook endpoint.

**Steps:**
1. **Cloudflare Tunnel Repoint:**
   - Use Cloudflare API or dashboard to update tunnel target:
     - Old target: `[previous-endpoint]` (e.g., Hetzner IP or DNS CNAME)
     - New target: `3.147.82.221` (AWS Lightsail IP)
   - Command (requires `CLOUDFLARE_API_TOKEN`):
     ```bash
     curl -X PUT "https://api.cloudflare.com/client/v4/accounts/[account-id]/tunnels/[tunnel-id]/config" \
       -H "Authorization: Bearer [api-token]" \
       -H "Content-Type: application/json" \
       -d '{
         "config": {
           "ingress": [
             {"hostname": "eden.wrkflo.biz", "service": "http://3.147.82.221:8080"}
           ]
         }
       }' | jq .
     ```
   - Verify response: `"success": true`

2. **DNS Propagation Wait:**
   - Query `eden.wrkflo.biz` from multiple locations to confirm propagation:
     ```bash
     dig eden.wrkflo.biz +short
     nslookup eden.wrkflo.biz
     ```
   - TTL may be 5–300 seconds; allow up to 5 minutes for full propagation
   - Monitor during this window (do NOT start gateway yet)

3. **Cloudflare HTTPS Verification:**
   - Test HTTPS connectivity to new endpoint:
     ```bash
     curl -I https://eden.wrkflo.biz/ -v 2>&1 | head -20
     ```
   - Expected: HTTP 200 or 502 (gateway not yet running is OK—just testing connectivity)
   - **NOT OK:** Connection timeout, certificate errors, or "origin unreachable"

4. **Telegram Webhook Status Check:**
   - Query Telegram Bot API to see current webhook configuration:
     ```bash
     curl -s "https://api.telegram.org/bot[token]/getWebhookInfo" | jq .
     ```
   - Expected: `"url": "https://eden.wrkflo.biz/telegram"`, `"has_custom_certificate": false`, `"pending_update_count": 0`
   - If old URL still shows: Telegram may still be retrying old endpoint (this is OK—will clear once new gateway starts receiving)

**Approval Gate:** ✋ DNS must resolve to AWS IP before starting gateway.

---

### Phase 4: Gateway Startup & Monitoring (Timing: T+0, T+1h, T+24h)

**Goal:** Start Hermes gateway on AWS, receive first Telegram messages, monitor for 24 hours.

**Steps:**

**T+0 (Cutover Moment):**
1. SSH to `hermes-prod-aws`:
   ```bash
   systemctl start hermes-gateway
   systemctl status hermes-gateway
   ```
2. Tail logs and look for Telegram connection:
   ```bash
   journalctl -u hermes-gateway -f --lines=50 | grep -i "telegram\|webhook\|connected"
   ```
   - Expected within 10 seconds: `[telegram] Connected to Telegram (webhook mode)`
   - If seen: Gateway is ready to receive updates

3. Send a test message to the Telegram bot (from phone or web):
   - Open Telegram, find the bot
   - Send a simple message: "test"
   - Check AWS logs for the webhook POST request:
     ```bash
     journalctl -u hermes-gateway -n 20 | grep -i "webhook\|post\|received"
     ```
   - Expected: Request logged, message processed

**T+1h (First Checkpoint):**
1. **Verify No Azure Activity:**
   - Confirm Azure VM remains stopped: `az vm show --resource-group GS-BTC-RG --name hermes-prod-vm --query provisioningState`
   - Confirm Mac LaunchAgent still disabled: `launchctl list | grep hermes` (should return nothing)

2. **Monitor AWS Gateway Health:**
   ```bash
   ssh hermes-prod-aws -c "/home/moses/.local/bin/hermes-vm-health-check"
   ```
   - Expected output: `ok healthy`
   - Check for: disk space, inodes, memory, load, Telegram polling conflicts, Tailscale IP

3. **Send Additional Test Messages:**
   - Send 3–5 test messages via Telegram over 30 minutes
   - Verify response time is reasonable (< 5s)
   - Check logs for errors or warnings

4. **Verify No Long-Polling Fallback:**
   - Search logs for signs of fallback to long-polling:
     ```bash
     journalctl -u hermes-gateway | grep -i "fallback\|polling\|getUpdates" | tail -5
     ```
   - Expected: No fallback messages (webhook is primary mode)

**T+24h (Soak Validation):**
1. **Collect 24-Hour Statistics:**
   - Message volume: `journalctl -u hermes-gateway --since "24 hours ago" | grep -c "telegram.*message\|webhook.*received"`
   - Error rate: `journalctl -u hermes-gateway --since "24 hours ago" | grep -c "ERROR\|error\|WARN"`
   - Uptime: `systemctl status hermes-gateway | grep Active`

2. **Compare Against Azure (Offline):**
   - Verify Azure VM is still stopped
   - Verify zero duplicate-consumer errors in logs

3. **Gateway Log Health:**
   - No memory leaks: `journalctl -u hermes-gateway --since "24 hours ago" | tail -30 | grep -i "memory\|oom"`
   - No connection drops: `journalctl -u hermes-gateway | grep -c "disconnect"` (should be 0)
   - No certificate errors: `journalctl -u hermes-gateway | grep -c "SSL\|certificate.*error"` (should be 0)

**Owner Approval Gate:** ✋ Only after 24-hour soak passes do we decommission Azure.

---

## Rollback Procedures

### Scenario A: Gateway Fails to Start on AWS (T+0)
**Symptom:** `systemctl start hermes-gateway` hangs or exits with error.

**Steps:**
1. Check for common issues:
   ```bash
   # No config found
   test -f ~/.hermes/config.yaml && echo "Config OK" || echo "MISSING"
   
   # Invalid env vars
   grep "TELEGRAM_WEBHOOK" ~/.hermes/.env
   
   # Port in use
   lsof -i :8443
   ```

2. If env vars are wrong, revert to long-polling (temporary):
   ```bash
   unset TELEGRAM_WEBHOOK_URL TELEGRAM_WEBHOOK_SECRET
   systemctl restart hermes-gateway
   ```
   - Gateway will fall back to `getUpdates` polling (slower but still works)
   - **Continue without webhook—do NOT revert DNS yet**

3. If crashes persist, SSH to Azure and restart the old gateway:
   ```bash
   az vm start --resource-group GS-BTC-RG --name hermes-prod-vm
   # Wait 5 minutes for boot
   az vm run-command invoke --resource-group GS-BTC-RG --name hermes-prod-vm \
     --command-id RunShellScript --scripts "systemctl start hermes-gateway"
   ```
   **Note:** This re-enables the duplicate-consumer risk. **Immediate action required:** coordinate with ops to disable again after AWS is fixed.

4. Once AWS is fixed, restart:
   ```bash
   systemctl restart hermes-gateway
   systemctl status hermes-gateway
   ```

---

### Scenario B: Telegram Webhook Not Receiving Messages (T+1h)
**Symptom:** Test messages sent to bot but not logged by AWS gateway.

**Possible Causes:**
1. **DNS still pointing to old endpoint:**
   ```bash
   dig eden.wrkflo.biz +short
   ```
   - If NOT 3.147.82.221: Wait another 5 minutes for TTL to expire, then re-query

2. **Cloudflare tunnel misconfigured:**
   - Test connectivity to AWS directly (bypass DNS):
     ```bash
     curl -k -I https://3.147.82.221:8443/
     ```
   - If hangs or times out: AWS security group is blocking 8443. **Fix inbound rule.**

3. **Telegram webhook URL not updated:**
   ```bash
   curl -s "https://api.telegram.org/bot[token]/getWebhookInfo" | jq .
   ```
   - If still shows old URL: Run webhook update script again
   - If shows new URL but "last_error_message" is recent: Check AWS gateway logs for exceptions

4. **AWS gateway not listening:**
   ```bash
   ssh hermes-prod-aws -c "netstat -tlnp | grep 8443"
   ```
   - If no listener: Gateway crashed. Check logs:
     ```bash
     journalctl -u hermes-gateway -n 50
     ```

**Recovery:** Fix the root cause, then send a test message to verify.

---

### Scenario C: Duplicate Consumer Errors (T+6h)
**Symptom:** Logs show "conflicting Telegram pollers" or duplicate message processing.

**Possible Causes:**
1. **Mac LaunchAgent re-enabled accidentally:**
   ```bash
   launchctl list | grep hermes
   ```
   - If listed: Disable it:
     ```bash
     launchctl unload ~/Library/LaunchAgents/ai.hermes.gateway.plist
     ```

2. **Azure VM accidentally started:**
   ```bash
   az vm show --resource-group GS-BTC-RG --name hermes-prod-vm --query powerState
   ```
   - If PowerState is "VM running": Stop immediately:
     ```bash
     az vm stop --resource-group GS-BTC-RG --name hermes-prod-vm
     ```

3. **OS1 bridge auto-restarted:**
   ```bash
   launchctl list | grep os1
   ```
   - If `com.os1.telegram-approval-bridge` is listed: Unload it:
     ```bash
     launchctl unload ~/Library/LaunchAgents/com.os1.telegram-approval-bridge.plist
     ```

**Recovery:** Disable the duplicate poller, then monitor logs for 1 hour to confirm no more conflicts.

---

### Scenario D: Full Rollback to Azure (Emergency)
**When:** If AWS experiences unrecoverable failure after 24-hour soak and business impact is too high to continue.

**Steps:**
1. **Disable AWS Gateway:**
   ```bash
   ssh hermes-prod-aws -c "systemctl stop hermes-gateway"
   ```

2. **Revert Telegram Webhook:**
   ```bash
   python3 update_telegram_webhook.py \
     --token "[bot-token]" \
     --webhook-url "" \
     --secret ""
   ```
   - Empty webhook URL reverts to long-polling

3. **Revert Cloudflare Tunnel:**
   - Point `eden.wrkflo.biz` back to old endpoint (Hetzner IP or previous DNS)
   - Allow 5 minutes for DNS propagation

4. **Restart Azure Hermes:**
   ```bash
   az vm start --resource-group GS-BTC-RG --name hermes-prod-vm
   # Wait 5 minutes
   ssh hermes-prod-vm -c "systemctl start hermes-gateway"
   ```

5. **Re-Enable Mac LaunchAgent (If Needed):**
   - Only if Azure is truly permanent fallback:
     ```bash
     launchctl load ~/Library/LaunchAgents/ai.hermes.gateway.plist.disabled-20260628T031200Z
     ```
   - **But:** This re-introduces duplicate consumer risk. **Recommended:** keep only Azure running, leave Mac disabled.

---

## Health Check Procedures

### Daily Check (Run Every Morning)
```bash
# AWS Gateway Status
ssh hermes-prod-aws -c "systemctl status hermes-gateway | head -5"

# Recent Errors
ssh hermes-prod-aws -c "journalctl -u hermes-gateway --since '24 hours ago' | grep -i error | tail -5"

# Message Volume
ssh hermes-prod-aws -c "journalctl -u hermes-gateway --since '24 hours ago' | grep -c 'telegram.*received'"

# Disk Space
ssh hermes-prod-aws -c "df -h /home/moses/ | tail -2"

# Confirm Azure Still Stopped
az vm show --resource-group GS-BTC-RG --name hermes-prod-vm --query powerState
```

### Weekly Deep Check
```bash
# Full System Health
ssh hermes-prod-aws -c "/home/moses/.local/bin/hermes-vm-health-check"

# Memory/CPU Trends
ssh hermes-prod-aws -c "head -30 /home/moses/.local/state/hermes-watchdog/latest-report.txt"

# DNS Resolution
dig eden.wrkflo.biz +short
curl -I https://eden.wrkflo.biz/ 2>&1 | head -3

# Telegram Webhook Info
curl -s "https://api.telegram.org/bot[token]/getWebhookInfo" | jq '.result | {url, has_custom_certificate, pending_update_count, last_error_date}'
```

### Emergency Diagnostic
```bash
# Full gateway logs (last 200 lines)
ssh hermes-prod-aws -c "journalctl -u hermes-gateway -n 200"

# Check for all known pollers
ps aux | grep -i telegram
launchctl list | grep -i hermes

# Network connectivity
curl -v https://api.telegram.org/bot[token]/getMe 2>&1 | head -20
```

---

## Config Templates

### AWS ~/.hermes/.env (Webhook Mode)
```bash
# Telegram Bot Credentials
TELEGRAM_BOT_TOKEN=set

# Webhook Configuration (CUTOVER)
TELEGRAM_WEBHOOK_URL=https://eden.wrkflo.biz/telegram
TELEGRAM_WEBHOOK_SECRET=set  # Generated: openssl rand -hex 32
TELEGRAM_WEBHOOK_PORT=8443

# Safety: Explicitly disable other pollers
TELEGRAM_POLLING_ENABLED=false
```

### AWS ~/.hermes/config.yaml (Telegram Section)
```yaml
telegram:
  # These settings are imported from .env at startup
  # No need to duplicate here; the gateway reads env vars first
  
  # Optional: Set home channel for outbound sends
  # allowed_chats: "-1234567890"
  
  # Optional: Proxy (if Telegram API is blocked)
  # proxy_url: "socks5://127.0.0.1:1080"
  
  # Platform-specific display settings
  reactions: false
```

### Telegram Bot API Webhook Update Script
```python
#!/usr/bin/env python3
"""
update_telegram_webhook.py - Update Telegram Bot API webhook endpoint.

Usage:
  python3 update_telegram_webhook.py \
    --token "123456789:ABCdefGHIjklMNOpqrSTUvwxYZ" \
    --webhook-url "https://eden.wrkflo.biz/telegram" \
    --secret "$(openssl rand -hex 32)"
"""

import sys
import requests
import json
import argparse
from typing import Optional

def update_telegram_webhook(
    token: str,
    webhook_url: str,
    secret: Optional[str] = None,
    allowed_updates: Optional[list] = None
) -> dict:
    """
    Update Telegram bot webhook.
    
    Args:
        token: Telegram bot token
        webhook_url: New webhook URL (or empty string to disable)
        secret: Optional secret for webhook validation
        allowed_updates: Specific update types (default: all)
    
    Returns:
        Telegram API response
    """
    api_endpoint = f"https://api.telegram.org/bot{token}/setWebhook"
    
    payload = {"url": webhook_url}
    
    if secret:
        payload["secret_token"] = secret
    
    if allowed_updates:
        payload["allowed_updates"] = allowed_updates
    
    try:
        response = requests.post(api_endpoint, json=payload, timeout=10)
        result = response.json()
        
        if result.get("ok"):
            print("✓ Webhook updated successfully")
            if webhook_url:
                print(f"  URL: {webhook_url}")
                print(f"  Secret: [set, not printed]")
            else:
                print(f"  Webhook disabled (fallback to polling)")
            return result
        else:
            error_msg = result.get("description", "Unknown error")
            print(f"✗ Error: {error_msg}", file=sys.stderr)
            sys.exit(1)
    
    except requests.exceptions.RequestException as e:
        print(f"✗ Request failed: {e}", file=sys.stderr)
        sys.exit(1)

def get_webhook_info(token: str) -> dict:
    """Fetch current webhook configuration from Telegram."""
    api_endpoint = f"https://api.telegram.org/bot{token}/getWebhookInfo"
    
    try:
        response = requests.get(api_endpoint, timeout=10)
        result = response.json()
        
        if result.get("ok"):
            return result.get("result", {})
        else:
            print(f"Error: {result.get('description')}", file=sys.stderr)
            return {}
    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}", file=sys.stderr)
        return {}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Update Telegram bot webhook endpoint"
    )
    parser.add_argument("--token", required=True, help="Telegram bot token")
    parser.add_argument("--webhook-url", required=True, 
                       help="New webhook URL (empty string to disable)")
    parser.add_argument("--secret", help="Webhook secret (optional)")
    parser.add_argument("--get-info", action="store_true",
                       help="Fetch current webhook info without updating")
    
    args = parser.parse_args()
    
    if args.get_info:
        info = get_webhook_info(args.token)
        print(json.dumps(info, indent=2))
    else:
        update_telegram_webhook(
            token=args.token,
            webhook_url=args.webhook_url,
            secret=args.secret
        )
```

---

## DNS/Tunnel Migration Summary

### Current State
- **Domain:** `eden.wrkflo.biz`
- **Provider:** Cloudflare tunnel
- **Current Target:** [Previous endpoint—Hetzner or old DNS]
- **TTL:** [Check via `dig eden.wrkflo.biz SOA`]

### Cutover Action
```bash
# Via Cloudflare API:
# Old target → New target (3.147.82.221)

# Verify propagation:
dig eden.wrkflo.biz +short  # Should resolve to AWS IP

# Test HTTPS:
curl -I https://eden.wrkflo.biz/
```

### Revert Path
```bash
# If rollback needed within 24h:
# Point eden.wrkflo.biz back to old endpoint
# Telegram webhook URL reverts to "" (empty = polling)
# Azure VM is restarted
```

### Decommission (Post-24h Soak)
```bash
# Only after owner approval:
az vm delete --resource-group GS-BTC-RG --name hermes-prod-vm --yes
```

---

## Credential Status Report

| Credential | Location | Status |
|---|---|---|
| Telegram Bot Token | `~/.hermes/.env` (AWS) | **Set** |
| Telegram Webhook Secret | `~/.hermes/.env` (AWS) | **To be generated** |
| Cloudflare API Token | Secure storage (TBD) | **Status unknown—verify before cutover** |
| Azure VM SSH Key | `~/.ssh/id_ed25519` | **Set** |

**None of the above values are printed in this document.** Report only as `set`, `empty`, or `missing`.

---

## Owner Sign-Off

Before proceeding, owner must:

- [ ] Review this plan
- [ ] Verify Azure VM is stopped (no duplicate consumers)
- [ ] Confirm AWS instance is running and accessible
- [ ] Approve Phase 1 (pre-cutover validation)
- [ ] Approve Phase 3 (DNS cutover—no rollback after this point without 30-min delay)
- [ ] Approve Phase 4 gateway startup
- [ ] Commit to 24-hour soak period before Azure decommission
- [ ] Designate on-call monitor for first 24 hours

**Signature:** ___________________  **Date:** ___________________

---

## Appendix A: Why Single Poller Matters

Telegram Bot API enforces a rule: **only one bot can be polling `getUpdates` or receiving webhooks for a given bot token at any time.**

**Previous Incident (June 2026):**
- Mac Hermes gateway (`ai.hermes.gateway`) was polling
- Azure VM Hermes gateway (`hermes-gateway.service`) was ALSO polling
- Result: Duplicate messages, missed updates, API rate-limiting errors

**Remediation:**
- Mac LaunchAgent disabled and moved to `.disabled` status
- OS1 bridge/autopilot also disabled
- Only Azure VM gateway polls (now being migrated to AWS)

**After This Cutover:**
- Only AWS Hermes gateway will poll/webhook
- Mac stays disabled
- Azure VM stays stopped

---

## Appendix B: Monitoring & Observability

### Log Rotation (AWS)
```bash
# Journald auto-rotates; check size:
journalctl --disk-usage

# Tail live:
journalctl -u hermes-gateway -f

# Search errors:
journalctl -u hermes-gateway | grep -i error | tail -20
```

### Alerts to Set Up (Post-Cutover)
- Gateway process exits unexpectedly
- 0 messages received in 6+ hours
- Disk usage > 80%
- Memory usage > 80%
- Telegram webhook shows errors in `last_error_date`

### Metrics to Track
- Message volume (per hour)
- Response time (p50, p95)
- Error rate
- Webhook retry count (from Telegram API info)

---

**End of Plan**
