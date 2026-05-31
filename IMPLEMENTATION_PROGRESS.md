# Expense Tracker Enhancement Progress

## Completed

- Added a safe Excel import flow from Settings with backup guidance, workbook validation, duplicate detection, row review, and merge-style import that preserves existing data by default.
- Improved SMS parsing and categorization for salary-style credit messages, including NEFT/deposit/private-limited employer patterns.
- Expanded default categories with Investment, Home, Education, Travel, Insurance, and Subscriptions while preserving old category IDs.
- Added transaction search across amount, category, description/raw text, type, payment method, and displayed date.
- Updated transaction editing to allow switching between Expense and Income with compatible category handling.
- Added an optional amount calculator in the manual transaction form.
- Redesigned the Home tab with balance snapshot, monthly income/expense, savings, top category, and concise activity insight.
- Redesigned Analytics with premium compact cards, scrollable category details, daily/weekly/monthly/yearly trend switching, and richer insights.
- Added a separate Stats Dashboard page with summary cards, bars, pie chart, monthly comparison, and useful spending insights.
- Added Settings font switching with Inter, Lato, and Creepster horror font options, persisted locally across restarts.
- Tuned new layouts toward compact modern mobile use for Galaxy S24-sized screens.

## Pending Items

- Full device QA on a physical Samsung Galaxy S24 or matching emulator.
- Import testing with real bank/export spreadsheets beyond the app-generated Excel format.
- Optional future support for user-selected duplicate replacement; the current implementation safely skips duplicates unless service-level override is used.

## Known Limitations

- Excel import expects a readable transaction sheet with at least Date, Type, and Amount columns. It supports common aliases but not arbitrary bank statement layouts.
- Category mapping during import uses existing category names; unknown categories are mapped to Other with a warning.
- The calculator supports basic arithmetic without parentheses.
- Font selection uses Google Fonts package fonts and depends on the package's normal font loading behavior.

## Next Steps

- Add more import fixtures and widget tests for the review flow.
- Add advanced duplicate resolution UI for replace vs merge decisions.
- Add budget deviation analytics once budget targets are consistently available in the analytics layer.
