# Day 1 Data Spine MVP

A deterministic data pipeline for ingesting RSS news and daily market prices, with observability snapshots.

## Objective

Implement end-to-end data plumbing to support later sentiment scoring and forecasting. This Day 1 implementation focuses on:
- RSS news ingestion with deduplication
- Daily OHLCV price fetching
- Daily snapshot generation for observability

## Prerequisites

- Python 3.8+
- Internet connection for RSS feeds and market data APIs

## Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. The project structure should be:
```
.
├── app/
│   ├── config/
│   │   └── settings.yaml
│   ├── core/
│   │   ├── config.py
│   │   ├── db.py
│   │   └── logger.py
│   ├── ingest/
│   │   ├── dedupe.py
│   │   ├── normalizer.py
│   │   └── rss_client.py
│   ├── market/
│   │   └── prices.py
│   └── jobs/
│       ├── ingest_news.py
│       ├── fetch_prices.py
│       └── build_snapshot.py
├── data/
│   └── snapshots/
├── tests/
└── requirements.txt
```

## Configuration

Edit `app/config/settings.yaml` to configure:

- **db_url**: SQLite database location (default: `sqlite:///data/news.db`)
- **tickers**: List of stock tickers to fetch prices for
- **rss_feeds**: List of RSS feed configurations with name and URL
- **storage**: Paths for prices parquet and snapshots directory

Example:
```yaml
db_url: "sqlite:///data/news.db"
timezone_market: "America/New_York"

tickers:
  - "AAPL"
  - "MSFT"

rss_feeds:
  - name: "Reuters Business"
    url: "https://www.reutersagency.com/feed/?taxonomy=best-topics&post_type=best"
  - name: "BBC Business"
    url: "http://feeds.bbci.co.uk/news/business/rss.xml"

storage:
  prices_path: "data/prices.parquet"
  snapshots_dir: "data/snapshots"
```

## How to Run Day 1

The Day 1 MVP consists of running 3 commands in sequence:

### Step 1: Ingest News

```bash
python -m app.jobs.ingest_news --date 2026-01-30
```

**What it does:**
- Fetches RSS feeds configured in settings.yaml
- Normalizes and deduplicates articles
- Stores articles in SQLite database
- Records run metadata in `ingest_runs` table

**Expected output:**
- Database file: `data/news.db` with populated `articles` and `ingest_runs` tables
- Structured JSON logs to stdout showing per-feed counts

### Step 2: Fetch Prices

```bash
python -m app.jobs.fetch_prices --start 2025-01-01 --end 2026-01-30
```

**What it does:**
- Fetches daily OHLCV data for configured tickers
- Retrieves data from Yahoo Finance (via yfinance)
- Stores normalized price data as parquet

**Expected output:**
- Parquet file: `data/prices.parquet` containing ticker, date, open, high, low, close, volume, adj_close columns
- Structured JSON logs showing fetch progress

### Step 3: Build Snapshot

```bash
python -m app.jobs.build_snapshot --date 2026-01-30
```

**What it does:**
- Counts articles for the specified date (UTC calendar day)
- Aggregates by source and finds published date range
- Checks price coverage for the date
- Generates observability JSON

**Expected output:**
- Snapshot file: `data/snapshots/2026-01-30.json` with exact schema:

```json
{
  "date": "2026-01-30",
  "generated_at_utc": "2026-01-30T12:34:56Z",
  "news": {
    "total_articles": 42,
    "by_source": {
      "Reuters Business": 25,
      "BBC Business": 17
    },
    "published_at_utc_min": "2026-01-30T00:15:00Z",
    "published_at_utc_max": "2026-01-30T23:45:00Z"
  },
  "prices": {
    "total_tickers": 2,
    "tickers_with_data": 2,
    "missing_tickers": []
  }
}
```

## Expected File Outputs

After running all three commands successfully, you should have:

```
data/
├── news.db                    # SQLite database with articles and ingest_runs tables
├── prices.parquet             # Daily OHLCV price data
└── snapshots/
    └── 2026-01-30.json       # Daily snapshot for observability
```

## Running Tests

Run the test suite to verify installation:

```bash
pytest
```

Expected tests:
- URL canonicalization (utm_* parameter removal)
- Deduplication logic
- Schema validation

## Key Features

### Idempotency
- Running `ingest_news` multiple times will not create duplicates
- Deduplication uses both URL uniqueness and content hashing

### Timezone Standard
- All timestamps stored in UTC with ISO 8601 format and Z suffix
- Snapshot date windows use UTC calendar days

### Failure Handling
- Individual feed failures don't abort the whole ingestion
- Run marked as success if at least one feed succeeds
- All errors logged with structured JSON output

### Data Contracts

**Articles table:**
- Stores canonical RSS items with deduplication
- Unique constraint on URL (where not null)
- Content hash for duplicate detection

**Prices parquet:**
- Schema: ticker, date, open, high, low, close, volume, adj_close
- Date format: YYYY-MM-DD string

**Snapshot JSON:**
- Exact keys as shown in example above
- Handles missing data gracefully (zeros and nulls)

## Troubleshooting

**Database already exists:**
- It's safe to run commands multiple times
- Database will be created automatically if missing

**No prices fetched:**
- Check internet connection
- Verify ticker symbols are valid
- Check date range is not in the future
- Logs will show which tickers failed

**No articles ingested:**
- Verify RSS feed URLs are accessible
- Check if articles already exist (deduplication working)
- Review logs for feed-specific errors

## Engineering Constraints

- No optional steps required for success
- All timestamps in UTC with ISO 8601 format
- No product decisions beyond specified contracts
- Deterministic behavior for reproducibility

## Next Steps

This Day 1 implementation provides the foundation for:
- Sentiment scoring (Day 2+)
- Entity linking (Day 2+)
- Historical analogs (Day 2+)
- Trading logic (Day 2+)
- Intraday data support (Day 2+)
