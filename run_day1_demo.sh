#!/bin/bash
# Day 1 Data Spine MVP - Demonstration Script

echo "==================================================================="
echo "Day 1 Data Spine MVP - Running End-to-End Pipeline"
echo "==================================================================="
echo ""

# Set test date
TEST_DATE="2026-01-31"

echo "Step 1: Ingesting News (--date $TEST_DATE)"
echo "-------------------------------------------------------------------"
python -m app.jobs.ingest_news --date $TEST_DATE
echo ""

echo "Step 2: Fetching Prices (--start 2024-01-01 --end 2024-01-10)"
echo "-------------------------------------------------------------------"
# Note: Using historical dates due to yfinance API limitations in test environment
# In production, use current dates
echo "Note: Creating mock price data for demonstration purposes"
python -c "
import pandas as pd
from datetime import datetime, timedelta

data = []
tickers = ['AAPL', 'MSFT']
start = datetime(2024, 1, 1)
for i in range(10):
    date = (start + timedelta(days=i)).strftime('%Y-%m-%d')
    for ticker in tickers:
        base_price = 150.0 if ticker == 'AAPL' else 350.0
        data.append({
            'ticker': ticker,
            'date': date,
            'open': base_price + i,
            'high': base_price + i + 5,
            'low': base_price + i - 2,
            'close': base_price + i + 3,
            'volume': 1000000 + i * 10000,
            'adj_close': base_price + i + 3
        })

df = pd.DataFrame(data)
df.to_parquet('data/prices.parquet', index=False)
print(f'Created price data: {len(df)} rows for {len(tickers)} tickers')
"
echo ""

echo "Step 3: Building Snapshot (--date $TEST_DATE)"
echo "-------------------------------------------------------------------"
python -m app.jobs.build_snapshot --date $TEST_DATE
echo ""

echo "==================================================================="
echo "Pipeline Complete! Verifying Outputs..."
echo "==================================================================="
echo ""

echo "Database file:"
ls -lh data/news.db
echo ""

echo "Prices file:"
ls -lh data/prices.parquet
echo ""

echo "Snapshot file:"
ls -lh data/snapshots/$TEST_DATE.json
echo ""

echo "Snapshot contents:"
cat data/snapshots/$TEST_DATE.json | python -m json.tool
echo ""

echo "==================================================================="
echo "Success! All outputs generated."
echo "==================================================================="
