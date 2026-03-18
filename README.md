# FounderDashboard

FounderDashboard is a macOS-first SwiftUI dashboard for founders who need one place to watch app revenue, subscription health, imported reports, and store-planning metrics in a native Apple app.

## Current Scope

- `Dashboard`: founder-level snapshot across software revenue and store planning
- `Decked Builder`: proceeds, subscribers, legacy conversion signals, and rebuild milestones
- `LGS Funding`: launch cash targets, scenario planning, and site guidance
- `Imports`: native import flow for App Store Connect CSV and report exports
- `Documents`: optional links to local planning documents
- `Sources`: acknowledgement of bundled sample data and imported reports

## Data Strategy

- Current build uses bundled sample data so the app can compile and preview cleanly in a public repo.
- The next data step is a CSV import flow, followed by optional `App Store Connect API` integration.
- Private planning files and personal exports are intentionally excluded from this repo.

## Far-Future Product Direction

- Keep the near-term app focused on a founder workflow first: software health, cash support, and local game store launch planning.
- Design the data model so it can eventually support multiple stores, multiple apps, and user-configured planning modules.
- A future repackaging path for other `LGS owners` is realistic once the CSV import flow, API sync, and store-planning modules are stable and less founder-specific.

## Source Notes

See [sources_acknowledgements.md](./sources_acknowledgements.md) for the current source list used to seed the public sample.
