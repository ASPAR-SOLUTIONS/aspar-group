import os
from pyairtable import Table

AIRTABLE_API_KEY = os.getenv('AIRTABLE_API_KEY')
AIRTABLE_BASE_ID = os.getenv('AIRTABLE_BASE_ID')
AIRTABLE_TABLE_NAME = os.getenv('AIRTABLE_TABLE_NAME', 'Table 1')

if not AIRTABLE_API_KEY or not AIRTABLE_BASE_ID:
    raise SystemExit("Please set AIRTABLE_API_KEY and AIRTABLE_BASE_ID environment variables")

table = Table(AIRTABLE_API_KEY, AIRTABLE_BASE_ID, AIRTABLE_TABLE_NAME)

# Fetch the first 5 records and print them
for record in table.all(max_records=5):
    print(record['fields'])
