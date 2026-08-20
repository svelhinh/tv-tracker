# TV Tracker — Agent Context

Flutter technical prototype exploring TV Time data migration, TMDB matching and lightweight episode tracking.

The repository may be public, but the project is still a prototype rather than a finished application.

## Current scope

- Flutter mobile
- Riverpod
- TV Time export import and parsing
- TMDB integration and show matching
- Lightweight local persistence and caching
- Tests around import, matching, metrics and persistence
- No authentication
- No backend
- No local database unless a future task explicitly requires one
- Functional UI; visual polish is secondary to the technical core

## Code rules

- Keep the code simple, readable and easy to change.
- Keep the architecture lightweight and feature-oriented.
- Do not over-engineer or add features outside the requested scope.
- Keep Riverpod providers simple and close to their features.
- Treat TMDB as an existing integration; keep its configuration isolated and never commit API keys.
- Prefer small, explicit files and abstractions over generic indirection.
- Keep or extend tests when changing core import, matching or persistence behaviour.
- Explain important technical decisions and meaningful changes.
