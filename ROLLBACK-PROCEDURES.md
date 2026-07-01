# AWS Migration Rollback Procedures

## Status: STAGING PHASE (No production traffic moved yet)

### Fast Rollback (If anything fails before cutover)

**Scenario 1: AWS instance fails before service start**
```bash
# Delete the staging instance
aws lightsail delete-instance --instance-name hermes-prod-aws --region us-east-2
aws lightsail delete-instance --instance-name dev-workspace-aws --region us-east-2
aws lightsail delete-instance --instance-name openclaw-global-sentinel-aws --region us-east-2

# Services remain on Azure (currently stopped, but can be restarted if billing is cleared)
# No traffic has been moved, so no user impact
```

**Scenario 2: Configuration issues discovered during bootstrap**
```bash
# Re-sync repositories and retry bootstrap
# No rollback needed (instances are still in pre-production state)
# Simply re-run bootstrap scripts with corrected configs
```

### Credential Rollback

If credentials were accidentally exposed on instances:
```bash
# Regenerate all tokens/keys (Telegram, API keys, etc.)
# Rotate database credentials
# Audit CloudTrail for unauthorized access
# Force re-authentication on all services
```

### DNS/Tunnel Rollback (If cutover initiated but needs abort)

**Before traffic cutover:**
- Cloudflare tunnel remains pointed at Azure VM (or localhost if VM stopped)
- No DNS changes = no traffic moves to AWS
- Rollback: Do nothing, existing tunnel config is still valid

**If traffic partially cutover:**
```bash
# Repoint Cloudflare tunnel back to Azure IP
cloudflare_ip=$(az vm show -g GS-BTC-RG -n gs-btc-d8s-v5-vm --query publicIps -o tsv)
# Update tunnel config in Cloudflare UI or CLI
```

### Data Recovery Rollback

If OpenClaw state recovery fails:
```bash
# Keep Azure disk snapshots untouched
# Staging instance has cloned repos (no persistent state lost)
# Rebuild from GitHub + local backups if needed
```

## Pre-Cutover Validation Checklist

- [ ] All three instances pass health checks
- [ ] All service dependencies installed and verified
- [ ] Configuration templates created and marked with credential placeholders
- [ ] Rollback procedures documented and tested
- [ ] Backup of Azure disks initiated (if feasible)
- [ ] No production traffic moved yet
- [ ] Local Hermes config preserved and tested
- [ ] Telegram bot still owns poller (Azure VM has sole control)

