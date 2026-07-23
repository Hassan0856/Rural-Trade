# AI Village Resource Exchange Network

**A rural circular economy platform connecting villagers who have idle resources with those who need them — powered by AI matching, voice input in local languages, and offline-first sync.**

Built for the **Social Impact / Sustainability** track.

---

## The Problem

In villages, expensive resources sit underused every day:
- Tractors remain idle for days at a time.
- Farm equipment is borrowed informally, with no record of who has what.
- Water pumps, generators, and tools are hard to find when actually needed.
- Excess crops and leftover materials go to waste.

There is no simple way for villagers to know who has what and who needs what.

## The Solution

AI Village Resource Exchange Network lets villagers:
- **List** equipment, tools, or produce to rent, lend, sell, or exchange.
- **Speak** listings using voice commands in local languages — no literacy barrier.
- **Get matched** with nearby users through AI-powered recommendations.
- **See demand forecasts** — e.g. "Farmers nearby may need a water pump next week due to expected dry weather."
- **Use the app with poor internet**, since data syncs automatically once a connection is available.
- **Trust who they're trading with**, via a verification badge and review system built on trade history.
- **Report issues** through a built-in complaint flow if a trade goes wrong.

---

## Core Features

| Feature | Description |
|---|---|
| Resource listings | Create, browse, and search equipment/tool/produce listings by category and distance |
| Voice input | Speak a listing instead of typing, in English, Hindi, or Telugu, via on-device speech recognition |
| AI matching | Gemini-powered recommendations explaining why a listing fits a nearby need |
| Demand forecasting | Weather-driven alerts (e.g. dry-spell water pump demand) generated in natural language |
| Offline-first sync | Local storage with automatic sync when connectivity returns |
| Verification badges | Trust indicator (Verified / New trader / Flagged) based on review and complaint history |
| Reviews | Star ratings and comments left after a completed trade |
| Complaint box | Report issues (damaged, stolen, no-show) tied to a specific trade |
| Impact stats | Aggregate view of listings shared, requests fulfilled, and estimated idle-hours saved |

---

## Tech Stack

- **Frontend:** Flutter (Android-first, offline-capable), built with Windsurf (Cascade agent)
- **Backend:** Supabase (Postgres, Auth, Storage, Realtime, Row-Level Security)
- **Offline sync:** drift / sqflite + connectivity_plus
- **AI matching & forecasting:** Google Gemini API (free tier), Groq as fallback
- **Voice input:** Flutter `speech_to_text` (on-device Android speech recognition — supports Indian languages, no API cost)
- **Weather data:** OpenWeatherMap (free tier)
- **State management:** Riverpod
- **Navigation:** GoRouter

---

## Team

| Role | Owns |
|---|---|
| Frontend / App Lead | Browse screen, Resource Detail screen, verification badge display |
| Backend / Data Lead | Supabase schema, Auth, Row-Level Security, reviews & complaints tables |
| AI / Integration Lead | Voice input, Gemini matching, weather-driven demand forecasting, AI trust summary |
| Product / Demo Lead | Onboarding, My Trades screen, reviews & complaints UI, seed data, impact stats |
| Design / Frontend Support | Theming, empty/loading states, badge styling |

---

## Getting Started

### Prerequisites
- Flutter SDK installed
- A Supabase account and project
- API keys for Gemini and OpenWeatherMap (both have free tiers)

### Setup

```bash
git clone <repo-url>
cd village_exchange
flutter pub get
```

Create a `.env` file in the project root (already git-ignored) with:

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
GEMINI_API_KEY=
OPENWEATHER_API_KEY=
```

### Supabase configuration
1. Run the schema migration files in `supabase/migrations/` against your project (creates `users`, `listings`, `requests`, `reviews`, and `complaints` tables with RLS enabled).
2. Enable **Phone** as an Auth provider: Authentication → Providers → Phone.
3. For demo purposes, add a **test phone number** with a fixed OTP under Authentication → Providers → Phone → Test OTPs, so login works reliably without a live SMS provider.

### Run the app

```bash
flutter run
```

---

## Project Structure

```
lib/
├── models/       # Resource, User, Listing, Request, Review, Complaint
├── providers/     # Riverpod state providers
├── screens/       # One file per screen (auth, listings, profile, etc.)
├── services/      # supabase_service.dart, ai_service.dart, weather_service.dart, sync_service.dart
├── theme/         # App-wide design system
└── widgets/       # Reusable components
```

---

## How the AI Layer Works

- **Matching:** listing text, category, and location are sent to Gemini, which returns a ranked explanation of why a listing fits a nearby request. A `pgvector`-based embedding fallback is available if latency is a concern.
- **Voice:** treated purely as an alternate input method — transcribed text flows through the same pipeline as typed listings, so no separate voice backend is needed.
- **Demand forecasting:** OpenWeatherMap data plus simple rule-based logic (e.g. no rain forecast + nearby crop listings needing irrigation) is passed to Gemini to generate a natural-language alert.
- **Trust summary:** a user's rating history and complaint count are summarized by Gemini into a one-line trust description shown alongside their verification badge.

---

## Impact

This project targets the **Social Impact / Sustainability** track by reducing idle resource time and material waste in rural communities, while lowering the barrier to participation through voice-first, offline-first design suited to low-connectivity, mixed-literacy environments.

---

## Future Improvements

- Multi-lingual UI beyond voice input
- SMS/USSD fallback for users without smartphones
- Community moderation tools for the complaint system
- Richer demand forecasting using historical exchange data, not just weather
