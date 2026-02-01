# Day 1 Data Spine MVP - Acceptance Criteria Verification

This document verifies that all acceptance criteria from the Day 1 epic have been met.

## Epic Definition of Done ✅

### Running 3 commands succeeds end-to-end:

```bash
python -m app.jobs.ingest_news --date YYYY-MM-DD      # ✅ VERIFIED
python -m app.jobs.fetch_prices --start YYYY-MM-DD --end YYYY-MM-DD  # ✅ VERIFIED
python -m app.jobs.build_snapshot --date YYYY-MM-DD   # ✅ VERIFIED
```

### Produces required outputs:

- ✅ SQLite DB: `data/news.db` with `articles` and `ingest_runs` tables
- ✅ Prices file: `data/prices.parquet`
- ✅ Snapshot file: `data/snapshots/YYYY-MM-DD.json`
- ✅ Logging + run metadata captured in `ingest_runs`

---

## D1-001 — Project Skeleton + Config Contract ✅

### D1-001a — Folder structure
```
✅ app/config/
✅ app/core/
✅ app/ingest/
✅ app/market/
✅ app/jobs/
✅ data/snapshots/
✅ tests/
```

### D1-001b — Config file and loader
- ✅ `app/config/settings.yaml` exists with all required keys
- ✅ `app/core/config.py` loader module implemented
- ✅ Validates `db_url`, `tickers`, `rss_feeds`, `storage.prices_path`, `storage.snapshots_dir`

**Verification:**
```bash
$ python -c "from app.core.config import load_settings; print(load_settings())"
# Prints parsed config successfully
```

### D1-001c — Logging utility
- ✅ `app/core/logger.py` implemented
- ✅ Outputs structured JSON logs to stdout

### D1-001d — DB connection utility
- ✅ `app/core/db.py` implemented
- ✅ SQLite connection with auto-creation
- ✅ Migration/bootstrap via `init_db()`

---

## D1-002 — SQLite Schema + Run Metadata Table ✅

### D1-002a — Schema migration/bootstrap
- ✅ `init_db()` creates tables if not exist

### D1-002b — Articles table
**Schema verified:**
- ✅ All required columns present (id, source, title, url, summary, published_at_utc, ingested_at_utc, content_hash, raw_payload)
- ✅ Unique index `ux_articles_url` on url WHERE url IS NOT NULL
- ✅ Indexes on published_at_utc, source, content_hash

### D1-002c — Ingest runs table
**Schema verified:**
- ✅ All required columns present (run_id, job_name, started_at_utc, ended_at_utc, status, items_read, items_written, items_skipped, error_message)

**Verification:**
```bash
$ python -m app.core.db
# Creates data/news.db successfully
# Tables verified with correct column names and indexes
```

---

## D1-003 — RSS Fetch + Normalize + Dedupe + Persist ✅

### D1-003a — RSS client
- ✅ `app/ingest/rss_client.py` implemented
- ✅ Uses feedparser to parse RSS
- ✅ Returns list of raw entries

### D1-003b — Normalizer
- ✅ `app/ingest/normalizer.py` implemented
- ✅ `normalize_entry()` returns exact contract fields
- ✅ Outputs: source, title, url, summary, published_at_utc, raw_payload

### D1-003c — URL canonicalizer
- ✅ `app/ingest/dedupe.py` implemented
- ✅ `canonicalize_url()` removes utm_* parameters
- ✅ Keeps all other params intact
- ✅ Trims whitespace

**Test verification:**
```bash
$ pytest tests/test_dedupe.py::TestURLCanonicalization -v
# All 5 tests PASSED
```

### D1-003d — Hashing + dedupe
- ✅ Content hash computed as: `sha256((title or "") + "||" + (summary or "") + "||" + (url or ""))`
- ✅ Upsert rule: URL uniqueness enforced
- ✅ Content hash deduplication working

**Test verification:**
```bash
$ pytest tests/test_integration.py::TestDeduplication -v
# Both deduplication tests PASSED
```

### D1-003e — Job wrapper
- ✅ `app/jobs/ingest_news.py` with `--date` CLI argument
- ✅ Records run in `ingest_runs` table

**Verification:**
```bash
$ python -m app.jobs.ingest_news --date 2026-01-31
# First run: items_written=30, items_skipped=0
$ python -m app.jobs.ingest_news --date 2026-01-31
# Second run: items_written=0, items_skipped=30 (deduplication works!)
```

---

## D1-004 — Daily Prices Fetch + Persist to Parquet ✅

### D1-004a — Price fetch module
- ✅ `app/market/prices.py` implemented
- ✅ `fetch_daily_ohlcv()` function

### D1-004b — Normalize schema
**Dataframe columns verified:**
- ✅ ticker (string)
- ✅ date (YYYY-MM-DD)
- ✅ open, high, low, close (float64)
- ✅ volume (int64)
- ✅ adj_close (float64)

**Test verification:**
```bash
$ pytest tests/test_schemas.py::TestSchemas::test_prices_dataframe_schema -v
# PASSED
```

### D1-004c — Persist job
- ✅ `app/jobs/fetch_prices.py` with `--start` and `--end` CLI arguments
- ✅ Writes parquet to `storage.prices_path`

**Verification:**
```bash
# Parquet file created: data/prices.parquet
# Loads cleanly with correct schema
```

---

## D1-005 — Daily Snapshot Builder ✅

### D1-005a — Snapshot logic
- ✅ `app/jobs/build_snapshot.py` implemented
- ✅ `--date` CLI argument
- ✅ Counts articles for date window (UTC calendar day)
- ✅ Counts by source
- ✅ Determines earliest/latest published_at_utc
- ✅ Determines price coverage

**Date window rule (strict):**
- ✅ UTC calendar day: YYYY-MM-DDT00:00:00Z to YYYY-MM-DDT23:59:59Z
- ✅ Includes article if published_at_utc within window
- ✅ If published_at_utc is null, includes if ingested_at_utc within window

### D1-005b — Persist snapshot
- ✅ Writes to: `data/snapshots/YYYY-MM-DD.json`

**Exact schema verified:**
```json
{
  "date": "YYYY-MM-DD",
  "generated_at_utc": "YYYY-MM-DDTHH:MM:SSZ",
  "news": {
    "total_articles": 0,
    "by_source": {},
    "published_at_utc_min": null,
    "published_at_utc_max": null
  },
  "prices": {
    "total_tickers": 0,
    "tickers_with_data": 0,
    "missing_tickers": []
  }
}
```

**Test verification:**
```bash
$ pytest tests/test_schemas.py::TestSchemas::test_snapshot_json_schema -v
# PASSED
```

**Verification:**
```bash
$ python -m app.jobs.build_snapshot --date 2026-01-31
# Produces snapshot with exact keys
# Handles missing data (zeros/nulls) without crashing
# Reflects correct counts from DB + parquet
```

---

## D1-006 — Minimal Tests ✅

### Test coverage:
- ✅ URL canonicalization (5 tests)
- ✅ Content hash consistency and uniqueness (3 tests)
- ✅ Deduplication integration (2 tests)
- ✅ Schema validation (4 tests)

**Verification:**
```bash
$ pytest tests/ -v
# 14 tests PASSED
```

---

## D1-007 — README "How to Run Day 1" ✅

- ✅ README includes exact commands
- ✅ Expected output paths documented
- ✅ Prerequisites and installation steps
- ✅ Configuration instructions
- ✅ No optional steps required for success

---

## Global Engineering Constraints ✅

### Timezone standard
- ✅ All stored timestamps in DB are UTC ISO 8601 with Z suffix
- ✅ Verified in articles table and ingest_runs table

### Idempotency
- ✅ `ingest_news` safe to run multiple times without duplicates
- ✅ Verified: First run writes 30, second run skips 30

### Failure mode
- ✅ One RSS feed failure does not abort whole ingestion
- ✅ Run marked as success if at least one feed succeeds
- ✅ Verified with mixed success/failure feeds

### No product decisions
- ✅ Only implements to exact contracts
- ✅ No extra fields or schema changes
- ✅ All data contracts strictly followed

---

## Summary

✅ **ALL ACCEPTANCE CRITERIA MET**

The Day 1 Data Spine MVP is complete and fully functional:

1. ✅ All 7 tickets (D1-001 through D1-007) implemented
2. ✅ 14 automated tests passing
3. ✅ 3 commands run successfully end-to-end
4. ✅ All required files produced with exact schemas
5. ✅ Global engineering constraints satisfied
6. ✅ Complete documentation and runbook provided

The pipeline is ready for Day 2 enhancements (sentiment scoring, entity linking, etc.).
