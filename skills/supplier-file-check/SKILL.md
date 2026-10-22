---
name: supplier-file-check
description: Check a supplier CSV or Excel file before it is loaded into a table. Use when someone asks to validate or review a supplier file, or before one is loaded. Not for files already in a table.
---

# Steps

1. List the columns and compare them with the expected list. Report missing or extra columns.
2. Check that every date column parses in one format. Report rows that don't.
3. Check the key columns for blanks and duplicates. Report counts.
4. Do not change or load the file. Return a short pass / fail summary first, then the details.

If the expected columns are unknown, ask for them. Don't guess.
