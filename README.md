# Cohort Category Z-Score Heatmap

**Purpose:**  
This repo contains a SQL script that normalizes facility spend by category (z-scores), assigns facilities to spend quartiles, and produces a cohort-level heatmap showing which categories are over/under-represented by cohort.

> NOTE: This is a *public-friendly template*. Replace placeholder table and column names with your own dataset prior to running. Do **not** publish sensitive or PHI data.

---

## Files
- `sql/cohort_category_zscore_heatmap.sql` — SQL script (generic, commented).
- `README.md` — This document.

---

## Expected input / schema
The script assumes (generic) tables with the following columns:

**purchase_data**
- `FacilityID` (unique facility identifier)
- `FacilityName`
- `SKU` (item identifier)
- `SpendAmount` (line-level dollar spend)
- `InvoiceDate` (date)
- *Optional:* `DataSource` (if you filter to a specific feed)

**category_reference**
- `SKU`
- `ItemCategory` (string, e.g., "Pharma", "Surgical", "Imaging")

> Adjust names in the SQL to match your own schema.

---

## How it works (high level)
1. Aggregate spend by facility × category.
2. Compute each facility's category share (`spend_pct` = category spend / facility total).
3. Compute category-level mean and std dev across facilities.
4. Compute z-score per facility × category: `(spend_pct - mean) / std`.
5. Assign facilities to quartiles by total spend.
6. Output average z-score per cohort × category for heatmap visualization.

---

## Running the script

### Databricks SQL / Unity Catalog
1. Replace placeholder table names in `sql/cohort_category_zscore_heatmap.sql`.
2. Paste the script into a SQL notebook or the SQL editor and run.
3. Save the result as a table or download as CSV for visualization.

### Other SQL engines
- The SQL is generic ANSI-like; adjust functions if needed (`STDDEV` vs `STDDEV_POP`, `DATE()` syntax, etc.).
- If your engine supports `SAFE_DIVIDE`, you can swap the `CASE` check for that function.

---

## Visualization
- Recommended: pivot the output so categories are rows and cohorts are columns, and use a diverging color scale.
- Power BI: use the output table, set the value to the avg z-score, and apply a custom diverging color palette (e.g., blue-white-orange or red-white-green).
- Interpretation: z > 0 means the cohort spends a larger share on that category vs the system average; z < 0 means less.

---

## Privacy & Security
- Do **not** commit PHI or company-sensitive data to public repos.
- Before publishing, replace any proprietary dataset names and scrub sample data.

---

## Contributing
1. Fork the repo.
2. Edit or improve SQL and README.
3. Open a PR describing changes.

---

## License
This repo is provided as a template. Add a LICENSE file (e.g., MIT) if you want to allow reuse.
