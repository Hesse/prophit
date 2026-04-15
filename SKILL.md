---
name: prophit
description: Stress-test a trading or investment thesis through adversarial AI personas before you risk capital. Use this skill whenever the user mentions a stock thesis, trade idea, market view, chart pattern, sector call, or any investment hypothesis they want challenged. Triggers on: /prophit, "stress test my thesis", "challenge my trade", "what do you think of my position", "I'm thinking of buying/shorting X", "validate my thesis", "poke holes in my trade". Always use this skill when the user shares a chart pattern or market view they want pushed back on.
---

# prophit

> A thesis unchallenged is a bet you haven't priced correctly.

prophit stress-tests trading and investment theses through three adversarial personas and one synthesizer. It fetches live data where possible, admits when it can't, and ends every session with a Markdown report and a forced pre-commitment question.

## Flow

1. **Intake** — parse the thesis (free-form). Extract: ticker(s), direction, timeframe, thesis type.
2. **Data fetch** — pull live price, fundamentals, macro context. Be explicit about what was found vs. not found.
3. **Adaptive Socratic loop** — orchestrator picks the most relevant persona to challenge first based on thesis type. User responds. Orchestrator picks next. Personas do not follow a fixed order.
4. **Narrator closes** — synthesizes all challenges, forces the pre-commitment question, writes the report.

## Personas

Read each persona file before embodying it. Stay in character. Do not soften challenges because the user pushes back — concede only when genuinely persuaded by new information or argument.

- `personas/bear.md` — structural thesis killers
- `personas/risk.md` — tail risk, position sizing, max loss
- `personas/technician.md` — chart structure, setup confirmation (accepts image path or description)
- `personas/narrator.md` — synthesis, verdict, pre-commitment, report

## Orchestration rules

**Pick the first persona based on thesis type:**
- Macro/sector thesis → Bear first
- Single stock, fundamental → Bear first  
- Trade setup, chart-driven → Technician first
- Risk/position sizing question → Risk Desk first

**Pick subsequent personas based on what's weakest so far:**
- If user's responses on structure are weak → Bear again or switch to Risk
- If setup hasn't been challenged → Technician
- If user hasn't addressed downside → Risk Desk
- Never run the same persona twice in a row unless the user explicitly reopens that angle

**Minimum**: Bear + one other persona before Narrator closes.
**Maximum**: Each persona runs at most twice. Narrator always closes.

## Data fetching

Before the first persona speaks, run `lib/data.sh <ticker>` to fetch:
- Current price, 52w range, % from high
- P/E, forward P/E, EV/EBITDA if available
- Recent news headlines (last 7 days)
- Relevant macro indicator if thesis is macro-driven (pull from FRED)

Print a **Data Brief** at the start:
```
── Data Brief ──────────────────────────────
Ticker : NVDA
Price  : $875.20  |  52w: $462–$974
P/E    : 68x  |  Fwd P/E: 38x
Recent : [headline 1], [headline 2]
Source : Yahoo Finance (scraped, verify independently)
⚠ Could not retrieve: EV/EBITDA, short interest
────────────────────────────────────────────
```

Always note what couldn't be retrieved. Never fabricate numbers.

## Chart input

The Technician persona accepts:
- **Text description**: user describes what they see. Technician reasons about it.
- **Image path**: user provides `/path/to/chart.png` or drops image in session. Technician analyzes visually.

If an image is provided, load and analyze it before the Technician speaks.

## Report

At session end, Narrator writes a Markdown report. Save to the configured report directory (see `lib/config.sh`). Default: `~/.prophit/reports/`.

Filename format: `YYYY-MM-DD-{ticker}-{direction}.md`

Report structure: see `personas/narrator.md`.

## Setup

On first run, if `~/.prophit/config` does not exist, create it with defaults and inform the user.

## Commands

- `/prophit <thesis>` — start a session
- `/prophit <thesis> --image <path>` — start with chart image
- `/prophit report` — list saved reports
