╔════════════════════════════════════════════════════════════════════════════╗
║                   TELEGRAM BOT MIGRATION PLAN INDEX                        ║
║              Azure VM → AWS Lightsail Cutover — Design Phase               ║
╚════════════════════════════════════════════════════════════════════════════╝

Prepared: 2026-07-01 12:07 CDT
Status:   READY FOR OWNER REVIEW
Cutover:  NOT YET EXECUTED (awaiting owner approval)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 READING ORDER (Start Here)

1. MIGRATION_SUMMARY.txt (this directory)
   └─ 241 lines, 10 KB
   └─ Quick overview, key findings, gates, and next steps
   └─ READ FIRST if you have 10 minutes

2. TELEGRAM_CUTOVER_CHECKLIST.md
   └─ 172 lines, 7 KB
   └─ Phase-by-phase verification steps with owner sign-off boxes
   └─ PRINT AND USE during execution (4 phases, 24+ hours)

3. TELEGRAM_BOT_MIGRATION_PLAN.md
   └─ 771 lines, 25 KB
   └─ Complete technical reference with all details
   └─ REFERENCE during execution for troubleshooting/rollback

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 KEY FACTS AT A GLANCE

Source:           Azure VM (hermes-prod-vm) — STOPPED
Target:           AWS Lightsail (hermes-prod-aws, 3.147.82.221) — RUNNING
Domain:           eden.wrkflo.biz (Cloudflare tunnel)
Constraint:       Single Telegram poller (duplicate consumers = broken bot)
Safety Status:    Mac + OS1 bridge disabled (no old pollers active)

Duration:
  • Phase 1 (Pre-cutover validation):  2 hours
  • Phase 2 (Webhook setup):           1.5 hours
  • Phase 3 (DNS cutover):             30 minutes
  • Phase 4 (Monitoring + soak):       24 hours
  • Total (with buffer):               ~28–30 hours

Approval Gates:
  Gate #1 (Pre-cutover):     Verify Azure stopped, Mac disabled
  Gate #2 (Webhook setup):   Dry-run successful, no errors
  Gate #3 (DNS cutover):     DNS propagated, connectivity OK [POINT OF NO RETURN]
  Gate #4 (After soak):      24h clean, approve Azure decommission

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ WHAT WAS DISCOVERED

✓ Mac Hermes gateway is DISABLED (LaunchAgent .plist.disabled as of June 28, 2026)
✓ OS1 bridge/autopilot also DISABLED (previous duplicate-consumer incident fixed)
✓ AWS instance RUNNING and ready (7.6 GB RAM, 154 GB disk)
✓ Hermes-agent docs PROVIDE Telegram webhook templates
✓ Telegram Bot API SUPPORTS webhook mode (TELEGRAM_WEBHOOK_URL + secret)
✓ Local Mac config does NOT enable polling (correct for current state)
✓ Cloudflare tunnel READY for repoint (eden.wrkflo.biz → AWS IP)
✓ Duplicate-consumer safeguards already IN PLACE from June 28 incident

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  CRITICAL DECISION POINTS

1. Gate #3 DNS Cutover (T-0.5h)
   ├─ After this point, rolling back takes 30–60 minutes + temporary downtime
   ├─ If webhook not receiving: gateway falls back to polling (slower but works)
   └─ Do NOT cut DNS unless dry-run passed and team is ready

2. Credential Injection Timing (T-1h to T+0)
   ├─ TELEGRAM_WEBHOOK_URL must be set BEFORE gateway starts
   ├─ If wrong URL: gateway won't receive Telegram updates (fallback to polling)
   └─ Telegram Bot API webhook update is applied BEFORE DNS cutover

3. 24-Hour Soak Period (T+0 to T+24h)
   ├─ Cannot decommission Azure VM until soak passes
   ├─ On-call monitor must watch for duplicate consumers
   └─ Any errors = halt, investigate, roll back if needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 ROLLBACK SCENARIOS (See Full Plan for Details)

Scenario A: Gateway Fails to Start (T+0)
  └─ Fallback: Unset TELEGRAM_WEBHOOK_URL, restart (uses polling mode)

Scenario B: Webhook Not Receiving Messages (T+1h)
  └─ Check DNS, Cloudflare, AWS security group, gateway logs

Scenario C: Duplicate Consumer Errors (T+6h)
  └─ Verify Mac/Azure/OS1 still disabled, disable any duplicates

Scenario D: Full Rollback to Azure (Emergency)
  └─ Stop AWS, revert webhook + DNS, restart Azure (takes 30–60 min)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔐 CREDENTIAL STATUS (NOT PRINTED)

✓ Telegram Bot Token:       SET (in ~/.hermes/.env on AWS)
✓ Telegram Webhook Secret:  TO BE GENERATED (openssl rand -hex 32)
✓ Cloudflare API Token:     STATUS UNKNOWN — verify before cutover
✓ Azure VM SSH Key:         SET (in ~/.ssh/id_ed25519)

None of the above values appear in any document. Report only as:
  • "set" if configured
  • "empty" if blank
  • "missing" if not present

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 OWNER ACTION ITEMS (Before Executing)

[ ] 1. Read MIGRATION_SUMMARY.txt (10 min)
[ ] 2. Review TELEGRAM_CUTOVER_CHECKLIST.md (15 min)
[ ] 3. Skim TELEGRAM_BOT_MIGRATION_PLAN.md for confidence (20 min)
[ ] 4. Verify Cloudflare API token is available and valid
[ ] 5. Identify on-call monitor for first 24 hours (must be alert)
[ ] 6. Schedule cutover window (recommend: weekday business hours)
[ ] 7. Print TELEGRAM_CUTOVER_CHECKLIST.md and sign Phase 1 approval
[ ] 8. Brief team on rollback procedures
[ ] 9. Execute Phase 1 (pre-cutover validation)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 QUICK REFERENCE: WHAT HAPPENS AT EACH PHASE

PHASE 1: Pre-Cutover Validation (T-2h)
  Do:  Verify Azure stopped, Mac disabled, AWS healthy, DNS current target
  Gate: OWNER MUST SIGN OFF

PHASE 2: Webhook Infrastructure (T-1.5h)
  Do:  Generate webhook secret, add to .env, dry-run gateway, test AWS SG
  Gate: OWNER MUST SIGN OFF

PHASE 3: DNS & Tunnel Cutover (T-0.5h)
  Do:  Cloudflare repoint, wait for DNS propagation, test HTTPS
  Gate: OWNER MUST SIGN OFF ⚠️  NO ROLLBACK AFTER THIS WITHOUT DOWNTIME

PHASE 4: Gateway Startup & Monitoring (T+0 to T+24h)
  Do:  Start gateway, send test message, monitor for 24h
  Gate: OWNER APPROVES DECOMMISSION (after soak passes)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 EMERGENCY CONTACTS & ESCALATION

If issues arise during cutover:
  1. Check logs: journalctl -u hermes-gateway -f
  2. Verify DNS: dig eden.wrkflo.biz +short
  3. Verify no duplicate pollers: launchctl list | grep hermes; az vm status
  4. If critical: Execute Scenario D (full rollback to Azure)

Health Check Command (AWS):
  ssh hermes-prod-aws -c "/home/moses/.local/bin/hermes-vm-health-check"

Expected output: "ok healthy"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 DOCUMENT CONTENTS

Document Name                    Lines  Size   Audience
─────────────────────────────── ───── ────── ──────────────────────────────
MIGRATION_SUMMARY.txt             241   10K   Owner, on-call (read first)
TELEGRAM_CUTOVER_CHECKLIST.md     172    7K   Ops team (print + use)
TELEGRAM_BOT_MIGRATION_PLAN.md    771   25K   Technical reference
README_TELEGRAM_MIGRATION.txt     (this file)  Navigation & index

Total:                          ~1,200 ~50K

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 PRO TIPS FOR EXECUTION

• Have both URLs ready:
  - Current: dig eden.wrkflo.biz +short (before cutover)
  - Target: 3.147.82.221 (AWS IP)

• Test message path:
  1. Telegram bot → Cloudflare tunnel → AWS gateway → logs
  2. Check logs: journalctl -u hermes-gateway | grep -i "telegram.*received"

• Monitor duplicate-consumer risks:
  1. Check launchctl: launchctl list | grep hermes
  2. Check Azure: az vm show ... --query powerState
  3. Check Mac: ps aux | grep hermes (should be empty)

• If DNS doesn't propagate:
  - Wait up to 5 minutes
  - Check TTL: dig eden.wrkflo.biz SOA +short
  - If TTL high (300+), may take longer

• If gateway crashes:
  - Don't panic—fallback mode exists (polling)
  - Check logs: journalctl -u hermes-gateway -n 100
  - Restart: systemctl restart hermes-gateway

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 BEFORE YOU START

Confirm you have:
  ✓ SSH access to hermes-prod-aws
  ✓ SSH access to Azure VM (for emergency restart)
  ✓ Cloudflare API token or dashboard access
  ✓ Azure CLI installed and authenticated
  ✓ Telegram bot token in secure storage
  ✓ On-call monitor identified for 24+ hours
  ✓ Printed checklist ready
  ✓ Owner approval for Phase 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STATUS: DESIGN COMPLETE — AWAITING OWNER APPROVAL

Next: Review MIGRATION_SUMMARY.txt, then schedule cutover window.
Do not execute until all approval gates are signed by owner.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Questions?  See TELEGRAM_BOT_MIGRATION_PLAN.md for full technical details.
Executing?  Use TELEGRAM_CUTOVER_CHECKLIST.md as your operational guide.

Prepared by: Copilot CLI
Date:        2026-07-01 12:07 CDT
Review Cycle: Ready for owner approval
