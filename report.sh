#!/usr/bin/env bash
# prophit/lib/report.sh
# Write a prophit session report to disk.
# Usage: source lib/report.sh && prophit_write_report <content_file> <ticker> <direction>

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

prophit_write_report() {
  local content_file="$1"
  local ticker="${2:-UNKNOWN}"
  local direction="${3:-unknown}"
  local report_dir

  report_dir=$(prophit_get_report_dir)

  local date_str
  date_str=$(date +%Y-%m-%d)

  local ticker_lower direction_lower
  ticker_lower=$(echo "$ticker" | tr '[:upper:]' '[:lower:]')
  direction_lower=$(echo "$direction" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  local filename="${date_str}-${ticker_lower}-${direction_lower}.md"
  local filepath="${report_dir}/${filename}"

  cp "$content_file" "$filepath"

  echo ""
  echo "── Report saved ─────────────────────────────────────────────"
  echo "  $filepath"
  echo "────────────────────────────────────────────────────────────"
  echo ""
}
