# AWS Migration Operations - START HERE

**Generated**: 2026-07-01 12:22 CDT  
**Status**: ✅ All Planning Complete | Awaiting Decisions & Ops Coordination

---

## 🎯 MISSION

Migrate three critical Wrk.Flo services from stopped Azure VMs to AWS Lightsail:
- **Hermes** (Telegram bot gateway + AI agent)
- **Dev Workspace** (Development environment)
- **OpenClaw** (Trading + Global Sentinel)

**Blocker**: Azure subscription billing warning has stopped all source VMs.

---

## 📊 STATUS SUMMARY

| Component | Status | Notes |
|-----------|--------|-------|
| AWS Instances | ✅ Running | 3x Lightsail ready (7.6GB–15GB RAM) |
| Service Bootstrap | ✅ Complete | All repos synced, dependencies installed |
| Health Checks | ✅ Deployed | Instances reporting baseline health |
| Documentation | ✅ Complete | 4 planning agents delivered 50+ KB reports |
| Data Recovery | 📋 Planned | 3 paths identified (snapshot, blob, rebuild) |
| Secrets | ⏳ Pending | Templates ready, actual credentials not distributed |
| Telegram Cutover | 📋 Planned | 4-phase procedure with rollback paths |
| Production Traffic | ✅ Safe | No DNS changes, no tunnel repoint yet |

---

## 📚 DOCUMENTS IN THIS FOLDER

### Start With These (Executive/Decision Level)

1. **EXECUTIVE-SUMMARY.txt** ⭐ **READ FIRST**
   - Key decisions required (today)
   - Timeline estimate (5–10 hours)
   - Risk assessment
   - Next actions checklist

2. **MIGRATION-DASHBOARD.md**
   - Infrastructure snapshot
   - Team agent status
   - Blockers and next milestones

### Operational Playbooks

3. **TELEGRAM_CUTOVER_CHECKLIST.md** ⭐ **PRINT THIS**
   - Step-by-step cutover procedure
   - 4 approval gates with sign-off spaces
   - Health checks between phases
   - Rollback procedures

4. **TELEGRAM_BOT_MIGRATION_PLAN.md**
   - Complete technical reference (50+ KB)
   - Detailed credential handling
   - Webhook infrastructure setup
   - 24-hour soak period monitoring

5. **README_TELEGRAM_MIGRATION.txt**
   - Navigation guide for Telegram docs
   - Credential status summary
   - What NOT to execute yet

### Data Recovery & Rollback

6. **AGENT-REPORTS-CONSOLIDATED.md**
   - Summary of all 4 planning agents
   - OpenClaw recovery paths ranked by reliability
   - Hermes bootstrap requirements
   - Dev Workspace status

7. **ROLLBACK-PROCEDURES.md**
   - Fast rollback scenarios
   - Credential rollback procedures
   - DNS/Tunnel rollback steps
   - Pre-cutover validation checklist

### Infrastructure & Automation

8. **check-instance-health.sh**
   - Automated health check script
   - Deploy to all instances: `scp -i key.pem ... ubuntu@IP:/tmp/`
   - Generates JSON metrics for monitoring

9. **credentials-templates/**
   - `hermes-env-template.sh` — Placeholder for Hermes secrets
   - `openclaw-env-template.sh` — Placeholder for OpenClaw secrets
   - `dev-workspace-env-template.sh` — Placeholder for Dev Workspace secrets

---

## 🔴 CRITICAL DECISIONS REQUIRED (Today)

### DECISION 1: OpenClaw Data Recovery Path
**Choose One:**
- ⭐⭐⭐⭐⭐ **A) Snapshot Export** → 2–4h, <1 day data loss (Recommended)
- ⭐⭐⭐⭐ **B) Blob Storage Download** → 1–2h, <48h data loss
- ⭐⭐⭐ **C) Git Rebuild** → 30m, ~40 GB loss (fastest)

**Action**: Contact Azure ops OR agree to Path B/C if billing blocked

### DECISION 2: Azure Subscription Billing
**Choose One:**
- **A) Resolve on current subscription** (1–4h Azure support) — Recommended
- **B) Use alternative subscription** for disk recovery
- **C) Accept rebuild** (skip disk recovery entirely)

**Action**: Contact Azure support today

### DECISION 3: Secrets Distribution Method
**Choose One:**
- **A) Vault-based** (secure, scalable) — Recommended
- **B) SSH injection** (manual, requires ops)
- **C) S3 bucket pull** (quick, less secure)

**Action**: Set up secure distribution channel

---

## ⏱️ TIMELINE

```
Now             │ Decisions made
│               │ Azure support contacted
│               ├─ 0–30 min: Review tunnel-migration-plan ✅ (DONE)
│               ├─ 30–120 min: Azure coord + OpenClaw path auth
│               ├─ 120–180 min: Inject secrets, start services
│               ├─ 180–240 min: OpenClaw data recovery (if Path A)
│               ├─ 240–270 min: Telegram bot cutover
│               └─ 270–300+ min: Monitor, validate, decommission
                
Fastest Path (C+C):  ~2 hours
Recommended Path (A+A): ~6 hours
With Data Recovery:  ~10 hours
```

---

## ✅ COMPLETED WORK

- [x] AWS infrastructure provisioned (3 instances, 46 min uptime each)
- [x] Baseline tools installed (Git, Docker, Node.js, Python)
- [x] All repositories cloned and synced to instances
- [x] SSH access verified to all instances
- [x] Health check scripts deployed
- [x] Service dependencies installed (Hermes, Dev Workspace)
- [x] Systemd service files prepared
- [x] Credential templates created (with placeholders)
- [x] Rollback procedures documented
- [x] Data recovery paths identified (Azure snapshots available)
- [x] Telegram cutover procedure designed (4-phase sequence)
- [x] Risk assessment completed
- [x] All documentation consolidated

---

## ⏳ WAITING ON

- [ ] **Decision 1**: OpenClaw recovery path (A/B/C)
- [ ] **Decision 2**: Azure billing resolution
- [ ] **Decision 3**: Secrets distribution method
- [ ] **Action**: Azure support contact
- [ ] **Action**: Secrets vault setup
- [ ] **Action**: Telegram cutover sign-off

---

## 🚨 CRITICAL CONSTRAINTS (Do NOT Violate)

1. **Telegram Bot Single Consumer**
   - Only ONE poller at a time or bot breaks
   - Mitigated by: Explicit enable/disable sequence, monitoring

2. **OpenClaw Persistent State**
   - Cannot start trading without `/data/openclaw/.openclaw`
   - Mitigated by: Data recovery path before service start

3. **No Production Traffic Yet**
   - Instances are staging-only
   - Mitigated by: Health checks + validation before cutover

---

## 📋 NEXT ACTIONS (Immediate)

1. **Read EXECUTIVE-SUMMARY.txt** (5 min)
2. **Make 3 Key Decisions** (listed above)
3. **Contact Azure Support** (billing issue)
4. **Prepare Secrets Distribution** (Vault/S3/SSH channel)
5. **Schedule Decision Meeting** (if team coordination needed)
6. **Approve Telegram Cutover** (when ready)

---

## 📞 AGENT REPORTS

All 4 planning agents completed successfully:

| Agent | Status | Output |
|-------|--------|--------|
| Hermes Bootstrap | ✅ Complete | Service deps + systemd ready |
| Dev Workspace Bootstrap | ✅ Complete | Ready for enablement |
| OpenClaw State Recovery | ✅ Complete | 3 paths ranked (snapshot best) |
| Telegram Bot Migration | ✅ Complete | 4-phase cutover + checklist |

Full consolidated report: **AGENT-REPORTS-CONSOLIDATED.md**

---

## 🎯 WHAT HAPPENS NEXT (After Decisions)

1. **Inject Secrets** → Hermes/OpenClaw/Dev Workspace environments
2. **Start Non-Telegram Services** → Hermes gateway + Dev Workspace (15 min)
3. **Recover OpenClaw Data** → Snapshot export or rebuild (30 min–4h)
4. **Cutover Telegram Bot** → DNS/webhook coordination (30 min)
5. **Monitor 24+ Hours** → Health checks, duplicate consumer watch
6. **Decommission Azure** → After ops approval

---

## 💡 TIPS

- **For Operators**: Print TELEGRAM_CUTOVER_CHECKLIST.md
- **For Leadership**: Read EXECUTIVE-SUMMARY.txt
- **For Developers**: Read AGENT-REPORTS-CONSOLIDATED.md
- **For Runbooks**: Use ROLLBACK-PROCEDURES.md

---

**Prepared by**: GitHub Copilot CLI + Team of Agents  
**Last Updated**: 2026-07-01 12:22 CDT  
**Migration Ops Folder**: `~/.copilot/session-state/migration-ops/`

