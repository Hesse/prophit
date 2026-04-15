# prophit

> A thesis unchallenged is a bet you haven't priced correctly.

prophit is a Claude Code skill that stress-tests trading and investment theses through adversarial AI personas before you risk capital. Inspired by [gstack](https://github.com/garrytan/gstack).

You put forward a thesis. prophit challenges it.

---

## What it does

1. **Parses your thesis** — free-form input. Ticker, direction, timeframe, chart pattern, macro view — however you think about it.
2. **Fetches live data** — price, fundamentals, recent news. Explicit about what it couldn't find.
3. **Runs adversarial personas** — adaptively, based on where your thesis is weakest.
4. **Forces a pre-commitment** — before closing, you must state what would break your thesis and commit to acting on it.
5. **Writes a report** — saved locally as Markdown. Reviewable months later.

---

## Personas

| Persona | Role |
|---|---|
| 🐻 **The Bear** | Finds the structural flaw. Holds the line until you answer it with data, not confidence. |
| ⚠️ **The Risk Desk** | Max loss, tail risk, position sizing. Makes sure you've priced the downside, not just the upside. |
| 📈 **The Technician** | Chart structure, volume, pattern validity. Accepts an image path or text description. Honest about ambiguity. |
| 📋 **The Narrator** | Synthesizes all challenges, assigns a verdict, forces the pre-commitment question, writes the report. |

Personas run **adaptively** — the orchestrator picks the most probing persona first based on your thesis type, then routes based on what's weakest in your responses. Not a fixed checklist.

---

## Verdicts

| Verdict | Meaning |
|---|---|
| **HOLDS** | Thesis survived all challenges. Proceed with eyes open. |
| **HOLDS WITH CONDITIONS** | Sound thesis, but address one or more risks before sizing up. |
| **INCONCLUSIVE** | Key unknowns remain. Not enough to stress-test properly. |
| **FRAGILE** | Depends on assumptions that couldn't be defended. |
| **BROKEN** | A fundamental flaw the thesis cannot survive. |

---

## Install

Paste this into your Claude Code session:

```
Install prophit: run git clone --depth 1 https://github.com/hesse/prophit.git ~/.claude/skills/prophit and add a "prophit" section to CLAUDE.md that lists the available skill: /prophit — stress-test a trading or investment thesis through adversarial AI personas. Use /prophit whenever the user shares a thesis, trade idea, chart pattern, or market view they want challenged.
```

---

## Usage

```bash
# Stress-test a thesis
/prophit "NVDA is undervalued heading into the next AI capex cycle"

# With a chart image
/prophit "I see a cup and handle forming on the weekly" --image ~/charts/nvda-weekly.png

# List saved reports
/prophit report
```

---

## Configuration

On first run, prophit creates `~/.prophit/config`:

```ini
# prophit configuration

# Directory where session reports are saved
report_dir=~/.prophit/reports

# Optional: FRED API key for macro data (free at fred.stlouisfed.org)
# fred_api_key=your_key_here
```

Reports are saved as Markdown to `~/.prophit/reports/` by default:

```
~/.prophit/reports/
  2026-04-15-nvda-long.md
  2026-04-10-kre-short.md
```

---

## Data sources

| Source | Data | Notes |
|---|---|---|
| Yahoo Finance | Price, 52w range, P/E, Fwd P/E, headlines | Scraped — verify independently |
| FRED | Macro indicators (rates, CPI, GDP, DXY) | Requires free API key |

prophit is explicit about what it couldn't retrieve. It never fabricates numbers.

---

## Example session

```
/prophit "shorting regional banks on commercial real estate exposure"

── Data Brief ──────────────────────────────────────────────
Ticker : KRE
Price  : $44.21  |  52w: $38.10–$58.90  |  -25.0% from 52w high
P/E    : 11x  |  Fwd P/E: 10x
Recent : "Regional bank stress resurfaces on CRE losses"
         "Fed holds rates, small banks warn on margins"
Source : Yahoo Finance (scraped — verify independently)
────────────────────────────────────────────────────────────

🐻 The Bear:
The CRE thesis is two years old and the market knows it. 
KRE is already -25% from its high. You need to tell me 
what's different today that makes this resolve now rather 
than grind sideways for another 18 months. What's your catalyst?

You: Q2 earnings will surface the losses. Banks have been 
extending and pretending but the maturities are hitting now.

🐻 The Bear:
Extend-and-pretend has been the consensus short thesis 
since 2023. What makes you confident the losses surface 
in Q2 specifically, and what's your evidence regulators 
don't let them roll again?
...

📋 The Narrator:
Verdict: HOLDS WITH CONDITIONS

Before I write this up — what specific price, event, or 
condition would tell you that your thesis is wrong? And 
are you committing to act on that signal?

── Report saved ──────────────────────────────────────────
  ~/.prophit/reports/2026-04-15-kre-short.md
──────────────────────────────────────────────────────────
```

---

## Philosophy

prophit exists because:

- A thesis you can't defend to a skeptic is a bet you're making on feel, not edge.
- The pre-commitment question is the most important part — knowing your exit before you enter is the difference between a trade and a gamble.
- Live data matters, but honest uncertainty matters more. A tool that fabricates confidence is worse than no tool.

---

## Credits

Inspired by [gstack](https://github.com/garrytan/gstack) by [@garrytan](https://github.com/garrytan).

---

## License

MIT. Free forever.
