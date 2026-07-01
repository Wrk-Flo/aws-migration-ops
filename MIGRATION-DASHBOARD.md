# Wrk.Flo AWS Migration Dashboard

**Status**: 2026-07-01 12:12 CDT | Staging Phase | No Production Traffic Moved

## Infrastructure Snapshot

### Azure Source (STOPPED - Billing Warning)
| Service | Status | Issue | Recovery Path |
|---------|--------|-------|----------------|
| hermes-prod-vm | ⛔ Stopped | VMStoppedToWarnSubscription | Restart if billing cleared |
| dev-workspace-prod-vm | ⛔ Stopped | VMStoppedToWarnSubscription | Restart if billing cleared |
| openclaw-prod-vm | ⛔ Stopped | VMStoppedToWarnSubscription | Restore disk + restart |

### AWS Staging (LIVE - Ready for Bootstrap)
| Instance | IP | OS | RAM | Disk | Repos | Status |
|----------|----|----|-----|------|-------|--------|
| hermes-prod-aws | 3.147.82.221 | Ubuntu 24.04 | 7.6G | 154G | ✓ hermes-agent | SSH ✓ |
| dev-workspace-aws | 18.191.186.167 | Ubuntu 24.04 | 3.7G | 77G | ✓ dev-workspace | SSH ✓ |
| openclaw-global-sentinel-aws | 3.144.224.57 | Ubuntu 24.04 | 15G | 309G | ✓ openclaw-prod, global-sentinel | SSH ✓ |

### AWS Production (RUNNING - Existing)
| Service | IP | Port | Status |
|---------|----|----|--------|
| eden-voice-shell | 3.133.115.102 | 5188 | ✓ Running |
| wrkflo-orchestrator | 3.137.161.113 | 8100 | ✓ Running |

## Team Agent Status

| Agent | Task | Status | ETA |
|-------|------|--------|-----|
| hermes-bootstrap | Service bootstrap | 🔄 Running | 2-3 min |
| dev-workspace-bootstrap | Service bootstrap | ✓ Complete | ✓ Ready |
| openclaw-state-recovery | State recovery plan | 🔄 Running | 2-3 min |
| tunnel-migration-plan | DNS/tunnel design | 🔄 Running | 2-3 min |

## Local Preparation Complete ✓

- [x] SSH keys secured
- [x] Health check scripts deployed
- [x] Credential templates created (marked with placeholders)
- [x] Rollback procedures documented
- [x] Migration status tracking (SQL database)
- [x] All instances verified SSH-accessible
- [x] Systemd unit directories prepared

## Blockers

1. **Azure Billing** (Critical)
   - All source VMs stopped by Azure subscription warning
   - Cannot access Azure disks while VMs stopped
   - Workaround: Use local repo clones + GitHub for recovery

2. **Telegram Bot Cutover** (Blocking)
   - Cannot start Hermes Telegram poller on AWS while Azure VM also stopped
   - Duplicate consumers will break the bot
   - Requires: (a) Azure subscription cleared, OR (b) Explicit polling coordination

3. **OpenClaw Persistent State** (Data Risk)
   - `/data/openclaw/.openclaw` on Azure disk (inaccessible)
   - Need to recover before starting OpenClaw services
   - Options: Disk snapshot/export, or GitHub-based reconstruction

4. **Secrets Distribution** (Pre-cutover)
   - Credential templates created, but actual secrets not yet distributed
   - Must inject via secure channel (Vault, secure shell, one-time URLs)

## Next Actions

- [ ] Review agent reports when ready
- [ ] Confirm OpenClaw data recovery path
- [ ] Plan credentials distribution (secure channel)
- [ ] Coordinate Azure billing clearance with ops
- [ ] Design Telegram bot cutover procedure (no duplicate pollers)
- [ ] Execute health checks on prepared services
- [ ] Run end-to-end cutover test (staging)
- [ ] Obtain approval for production cutover

## Timeline Estimate (From Now)

- **0-30 min**: Agent reports ready, blockers clarified
- **30-120 min**: Credential injection, data recovery if feasible
- **120-180 min**: Service bootstrap and health checks
- **180+ min**: Cutover coordination with ops (billing, DNS, credentials)

