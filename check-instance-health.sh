#!/bin/bash
# Health check script for AWS staging instances
# Deploy to each instance and run regularly: ./check-instance-health.sh

set -e

INSTANCE_NAME="${HOSTNAME:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
STATE_DIR="/home/ubuntu/.health"

mkdir -p "$STATE_DIR"

# Gather system health
{
  echo "=== $INSTANCE_NAME Health Check @ $TIMESTAMP ==="
  echo "Uptime: $(uptime)"
  echo ""
  echo "Disk Usage:"
  df -h / | tail -n 1 | awk '{printf "  Root: %s used, %s available (%s utilization)\n", $3, $4, $5}'
  echo ""
  echo "Memory:"
  free -h | grep Mem | awk '{printf "  Total: %s, Used: %s (%.1f%%)\n", $2, $3, ($3/$2)*100}'
  echo ""
  echo "Load:"
  uptime | grep -o 'load average.*' | sed 's/^/  /'
  echo ""
  
  # Check repositories exist
  echo "Repositories:"
  for repo_path in /home/ubuntu/*; do
    if [ -d "$repo_path/.git" ]; then
      repo_name=$(basename "$repo_path")
      branch=$(cd "$repo_path" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
      commit=$(cd "$repo_path" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
      echo "  $repo_name: $branch @ $commit"
    fi
  done
  echo ""
  
  # Check for service units
  echo "Systemd User Units (not loaded):"
  if [ -d ~/.config/systemd/user ]; then
    ls -1 ~/.config/systemd/user/*.service 2>/dev/null | xargs -I {} basename {} || echo "  (none)"
  else
    echo "  (no systemd-user directory)"
  fi
  echo ""
  
  # Check Docker daemon
  echo "Docker:"
  docker --version || echo "  Docker not available"
  docker ps 2>/dev/null | wc -l | xargs echo "  Running containers:"
  echo ""
  
  # Check Node
  echo "Node.js:"
  node --version || echo "  Node not available"
  echo ""
  
  # Check for any service processes (should be empty during staging)
  echo "Running Wrk.Flo processes:"
  ps aux | grep -E "hermes|openclaw|workspace|eden" | grep -v grep | wc -l | xargs echo "  Count:"
  
} > "$STATE_DIR/health-check.txt"

# Print and return
cat "$STATE_DIR/health-check.txt"

# Also write a JSON for tooling
{
  echo "{"
  echo "  \"timestamp\": \"$TIMESTAMP\","
  echo "  \"hostname\": \"$INSTANCE_NAME\","
  echo "  \"uptime\": \"$(uptime -p 2>/dev/null || echo 'unknown')\","
  echo "  \"disk_usage_percent\": $(df / | tail -n 1 | awk '{print $5}' | tr -d '%'),"
  echo "  \"memory_used_percent\": $(free | grep Mem | awk '{printf \"%.0f\", ($3/$2)*100}'),"
  echo "  \"services_running\": $(ps aux | grep -E 'hermes|openclaw|workspace|eden' | grep -v grep | wc -l)"
  echo "}"
} > "$STATE_DIR/health-check.json"
