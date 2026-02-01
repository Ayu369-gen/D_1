# Day 1 Data Spine MVP - Quick Start

## What's Included

This is a complete implementation of the Day 1 Data Spine MVP for a financial data pipeline.

**Package contents:** `day1-data-spine-mvp.tar.gz`

## Quick Start

### 1. Extract the archive:
```bash
tar xzf day1-data-spine-mvp.tar.gz
cd day1-data-spine-mvp
```

### 2. Install dependencies:
```bash
pip install -r requirements.txt
```

### 3. Run the pipeline:
```bash
# Option A: Run demo script (easiest)
./run_day1_demo.sh

# Option B: Run commands individually
python -m app.jobs.ingest_news --date 2026-01-31
python -m app.jobs.fetch_prices --start 2024-01-01 --end 2024-01-10
python -m app.jobs.build_snapshot --date 2026-01-31
```

### 4. View outputs:
```bash
# SQLite database with articles
ls -lh data/news.db

# Parquet file with prices
ls -lh data/prices.parquet

# Daily snapshot JSON
cat data/snapshots/2026-01-31.json
```

## What It Does

This pipeline:
1. **Ingests news** from RSS feeds with deduplication
2. **Fetches daily prices** (OHLCV) for configured tickers
3. **Builds snapshots** for observability and downstream analysis

## Key Features

- ✅ **Idempotent**: Safe to run multiple times (deduplication prevents duplicates)
- ✅ **Resilient**: Individual feed failures don't crash the whole pipeline
- ✅ **Observable**: Structured JSON logging and run metadata tracking
- ✅ **Tested**: 14 automated tests covering core functionality

## Configuration

Edit `app/config/settings.yaml` to:
- Add/remove RSS feeds
- Change ticker symbols
- Adjust storage paths

## Files Overview

```
app/
├── config/settings.yaml    # Configuration
├── core/                   # Database, config, logging utilities
├── ingest/                 # RSS fetching, normalization, deduplication
├── market/                 # Price fetching from yfinance
└── jobs/                   # Three main CLI jobs

tests/                      # 14 automated tests
data/
├── news.db                 # SQLite database (created on first run)
├── prices.parquet          # Price data (created by fetch_prices)
└── snapshots/              # Daily snapshot JSONs

README.md                   # Full documentation
VERIFICATION.md            # Acceptance criteria verification
```

## Testing

Run the test suite:
```bash
pytest tests/ -v
```

Expected: 14 tests passing
- 5 URL canonicalization tests
- 3 content hash tests  
- 2 deduplication integration tests
- 4 schema validation tests

## Troubleshooting

**No articles ingested?**
- Check RSS feed URLs in settings.yaml
- Verify internet connection
- Check logs for feed-specific errors

**Price fetch fails?**
- yfinance API can be unreliable; try historical dates
- Check ticker symbols are valid
- Review error logs

**Database issues?**
- Delete data/news.db and re-run (database auto-creates)

## Next Steps

This Day 1 implementation provides the foundation for:
- Sentiment scoring (Day 2+)
- Entity linking (Day 2+)
- Trading signals (Day 2+)
- Intraday data (Day 2+)

## Support Documents

- **README.md**: Complete documentation with all details
- **VERIFICATION.md**: Verification of all acceptance criteria
- **run_day1_demo.sh**: Automated demonstration script

---

Built according to exact specifications in Day 1 Epic ticket D1-EPIC-001.
All acceptance criteria verified and met.
