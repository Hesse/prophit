#!/usr/bin/env bash
# prophit/lib/data.sh
# Fetch live market data for a given ticker.
# Usage: ./data.sh <TICKER> [macro_keyword]
# Outputs a formatted Data Brief to stdout.
# Exits 0 on success, 1 on failure (with error message).

set -euo pipefail

TICKER="${1:-}"
MACRO_KEYWORD="${2:-}"

if [[ -z "$TICKER" ]]; then
  echo "Usage: data.sh <TICKER> [macro_keyword]" >&2
  exit 1
fi

TICKER_UPPER=$(echo "$TICKER" | tr '[:lower:]' '[:upper:]')
FOUND=()
NOT_FOUND=()

# ── Helpers ──────────────────────────────────────────────────────────────────

check_cmd() { command -v "$1" &>/dev/null; }

fetch_url() {
  if check_cmd curl; then
    curl -sL --max-time 10 -A "Mozilla/5.0" "$1"
  elif check_cmd wget; then
    wget -qO- --timeout=10 "$1"
  else
    echo ""
  fi
}

# ── Yahoo Finance scrape ──────────────────────────────────────────────────────

fetch_yahoo() {
  local url="https://finance.yahoo.com/quote/${TICKER_UPPER}/"
  local html
  html=$(fetch_url "$url")

  if [[ -z "$html" ]]; then
    NOT_FOUND+=("price" "52w range" "P/E")
    return
  fi

  # Current price
  PRICE=$(echo "$html" | grep -oP '"regularMarketPrice":\{"raw":\K[0-9.]+' | head -1)
  [[ -n "$PRICE" ]] && FOUND+=("price") || NOT_FOUND+=("price")

  # 52-week range
  W52_LOW=$(echo "$html"  | grep -oP '"fiftyTwoWeekLow":\{"raw":\K[0-9.]+' | head -1)
  W52_HIGH=$(echo "$html" | grep -oP '"fiftyTwoWeekHigh":\{"raw":\K[0-9.]+' | head -1)
  [[ -n "$W52_LOW" && -n "$W52_HIGH" ]] && FOUND+=("52w range") || NOT_FOUND+=("52w range")

  # P/E
  PE=$(echo "$html" | grep -oP '"trailingPE":\{"raw":\K[0-9.]+' | head -1)
  FWD_PE=$(echo "$html" | grep -oP '"forwardPE":\{"raw":\K[0-9.]+' | head -1)
  [[ -n "$PE" ]] && FOUND+=("P/E") || NOT_FOUND+=("P/E")
  [[ -n "$FWD_PE" ]] && FOUND+=("Fwd P/E") || NOT_FOUND+=("Fwd P/E")

  # % from 52w high
  PCT_FROM_HIGH=""
  if [[ -n "$PRICE" && -n "$W52_HIGH" ]]; then
    PCT_FROM_HIGH=$(awk "BEGIN {printf \"%.1f\", (($PRICE - $W52_HIGH) / $W52_HIGH) * 100}")
  fi

  # Export
  PRICE_OUT="${PRICE:-N/A}"
  W52_OUT="${W52_LOW:-?}–${W52_HIGH:-?}"
  PE_OUT="${PE:-N/A}"
  FWD_PE_OUT="${FWD_PE:-N/A}"
  PCT_HIGH_OUT="${PCT_FROM_HIGH:+${PCT_FROM_HIGH}% from 52w high}"
}

# ── News headlines (Yahoo Finance RSS) ───────────────────────────────────────

fetch_news() {
  local rss_url="https://finance.yahoo.com/rss/headline?s=${TICKER_UPPER}"
  local rss
  rss=$(fetch_url "$rss_url")

  if [[ -z "$rss" ]]; then
    NOT_FOUND+=("recent news")
    NEWS_OUT="Could not retrieve"
    return
  fi

  # Extract up to 3 titles
  mapfile -t TITLES < <(echo "$rss" | grep -oP '(?<=<title>)[^<]+' | grep -v "Yahoo Finance" | head -3)

  if [[ ${#TITLES[@]} -eq 0 ]]; then
    NOT_FOUND+=("recent news")
    NEWS_OUT="None found"
  else
    FOUND+=("recent news")
    NEWS_OUT=$(printf "  • %s\n" "${TITLES[@]}")
  fi
}

# ── FRED macro data (optional) ────────────────────────────────────────────────
# Requires FRED_API_KEY in environment or ~/.prophit/config
# Falls back gracefully if not available.

fetch_macro() {
  [[ -z "$MACRO_KEYWORD" ]] && return

  local config_file="$HOME/.prophit/config"
  local fred_key="${FRED_API_KEY:-}"

  if [[ -z "$fred_key" && -f "$config_file" ]]; then
    fred_key=$(grep -oP '(?<=fred_api_key=)\S+' "$config_file" || true)
  fi

  if [[ -z "$fred_key" ]]; then
    NOT_FOUND+=("macro/FRED data (no API key — set FRED_API_KEY or add fred_api_key= to ~/.prophit/config)")
    MACRO_OUT=""
    return
  fi

  # Map common keywords to FRED series IDs
  declare -A SERIES_MAP=(
    ["gdp"]="GDP"
    ["inflation"]="CPIAUCSL"
    ["cpi"]="CPIAUCSL"
    ["rates"]="FEDFUNDS"
    ["fed"]="FEDFUNDS"
    ["unemployment"]="UNRATE"
    ["10y"]="DGS10"
    ["yield"]="DGS10"
    ["dollar"]="DTWEXBGS"
    ["dxy"]="DTWEXBGS"
  )

  local keyword_lower
  keyword_lower=$(echo "$MACRO_KEYWORD" | tr '[:upper:]' '[:lower:]')
  local series_id="${SERIES_MAP[$keyword_lower]:-}"

  if [[ -z "$series_id" ]]; then
    NOT_FOUND+=("macro/$MACRO_KEYWORD (no known FRED series mapping)")
    MACRO_OUT=""
    return
  fi

  local fred_url="https://api.stlouisfed.org/fred/series/observations?series_id=${series_id}&api_key=${fred_key}&sort_order=desc&limit=1&file_type=json"
  local response
  response=$(fetch_url "$fred_url")

  local value
  value=$(echo "$response" | grep -oP '"value":"\K[^"]+' | head -1)

  if [[ -n "$value" && "$value" != "." ]]; then
    FOUND+=("macro: $MACRO_KEYWORD ($series_id)")
    MACRO_OUT="  ${MACRO_KEYWORD^^} (${series_id}): ${value}"
  else
    NOT_FOUND+=("macro: $MACRO_KEYWORD")
    MACRO_OUT=""
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

# Initialize output vars
PRICE_OUT="N/A"; W52_OUT="N/A"; PE_OUT="N/A"; FWD_PE_OUT="N/A"
PCT_HIGH_OUT=""; NEWS_OUT="N/A"; MACRO_OUT=""

fetch_yahoo
fetch_news
fetch_macro

# ── Output ───────────────────────────────────────────────────────────────────

echo ""
echo "── Data Brief ──────────────────────────────────────────────"
echo "Ticker : ${TICKER_UPPER}"
echo "Price  : \$${PRICE_OUT}  |  52w: ${W52_OUT}  ${PCT_HIGH_OUT}"
echo "P/E    : ${PE_OUT}  |  Fwd P/E: ${FWD_PE_OUT}"
echo ""
echo "Recent headlines:"
echo "${NEWS_OUT}"
[[ -n "$MACRO_OUT" ]] && echo "" && echo "Macro:" && echo "$MACRO_OUT"
echo ""
echo "Source : Yahoo Finance / FRED (scraped — verify independently)"

if [[ ${#NOT_FOUND[@]} -gt 0 ]]; then
  echo "⚠ Could not retrieve: $(IFS=', '; echo "${NOT_FOUND[*]}")"
fi

echo "────────────────────────────────────────────────────────────"
echo ""
