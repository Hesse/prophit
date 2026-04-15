#!/usr/bin/env bash
# prophit/lib/config.sh
# Read and initialize prophit configuration.
# Source this file: source lib/config.sh

CONFIG_FILE="$HOME/.prophit/config"
DEFAULT_REPORT_DIR="$HOME/.prophit/reports"

prophit_init_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<EOF
# prophit configuration
# Generated on $(date +%Y-%m-%d)

# Directory where session reports are saved
report_dir=$DEFAULT_REPORT_DIR

# Optional: FRED API key for macro data (free at fred.stlouisfed.org)
# fred_api_key=your_key_here
EOF
    mkdir -p "$DEFAULT_REPORT_DIR"
    echo "prophit: created config at $CONFIG_FILE"
    echo "prophit: reports will be saved to $DEFAULT_REPORT_DIR"
    echo ""
  fi
}

prophit_get_report_dir() {
  local dir
  dir=$(grep -oP '(?<=report_dir=)\S+' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_REPORT_DIR")
  # Expand ~ manually
  dir="${dir/#\~/$HOME}"
  mkdir -p "$dir"
  echo "$dir"
}

prophit_list_reports() {
  local report_dir
  report_dir=$(prophit_get_report_dir)

  if [[ ! -d "$report_dir" ]] || [[ -z "$(ls -A "$report_dir" 2>/dev/null)" ]]; then
    echo "No reports found in $report_dir"
    return
  fi

  echo "── prophit reports ─────────────────────────────────────────"
  ls -lt "$report_dir"/*.md 2>/dev/null | awk '{print $6, $7, $8, $9}' | \
    sed "s|$report_dir/||"
  echo "────────────────────────────────────────────────────────────"
}
