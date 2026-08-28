# Architecture

**Status:** Phase 0 audit — as-built, plus the target architecture.
**Audited:** 28 Dart files, ~4,570 lines, zero tests.

> This audits the code currently on the developer machine, **not** the
> GitHub repository, which is several revisions stale. Reconciling the two
> is the first task in Phase 1.

---

## 1. As-built

```
Flutter client (the entire product)
├── l10n/        S — 74 bilingual string entries, EN/FR
├── models/      UserPreferences, UserProfile, FoodSuggestion, ChatMessage
├── screens/     HomeShell (tabs) → Welcome, Onboarding, Suggestions,
│                Chat, Favorites, Profile, Insights
├── services/    GroqService, DishImageService, FavoritesService,
│                ProfileService
├── theme/       AppTheme (light/dark), AppColors, CuisineVisual
└── widgets/     SuggestionCard, HeroVideo, PreferenceChip, StepProgress,
                 PressableScale, AnimatedEntrance, AmbientBackground,
                 LoadingState, TypingIndicator, premiumRoute
```

There is **no backend**. The Flutter client calls Groq, TheMealDB and
Pexels directly. All persistence is `shared_preferences` on-device.

### Data flow today

```
Onboarding → UserPreferences ─┐
ProfileService (stated + learned) ─┼→ GroqService → Groq API → JSON
                                   │                    ↓
                       SuggestionCard ← DishImageService → TheMealDB → Pexels
```

### What is genuinely good

- **Structured LLM output.** `response_format: json_object` with a typed
  parse, not string-scraping. Failures raise a typed exception.
- **One transport, three modes.** `getSuggestions`, `refine` and `chat`
  all funnel through `_rawCompletion`, so auth, timeout, token budget and
  HTTP error mapping live in exactly one place.
- **Conversation history is passed forward,** which is what makes refine
  and chat contextual rather than stateless re-rolls.
- **Layered image resolution** (recipe DB → stock → designed fallback)
  that degrades from correct to plausible to designed, never to broken.
- **Dietary safety is a single shared prompt clause** injected into every
  system prompt rather than duplicated per-prompt.
- **Design system is real.** One card component serves three screens; one
  press wrapper gives the whole app spring physics and haptics.
- **Fail-soft storage.** Every `SharedPreferences` call is guarded; a
  device that refuses storage degrades, it does not crash.

### Technical debt, ranked by severity

| # | Issue | Severity | Evidence |
|---|---|---|---|
| 1 | API keys compiled into the client bundle | **Critical** | `String.fromEnvironment` in `groq_service.dart:56`, `dish_image_service.dart:42` |
| 2 | Zero tests | **Critical** | no `test/` directory |
| 3 | Prompt injection reachable from chat | **High** | raw user text at `groq_service.dart:234` |
| 4 | Network calls issued from widgets | High | `chat_screen`, `suggestion_screen`, `suggestion_card` |
| 5 | No CI | High | no `.github/workflows` |
| 6 | No crash reporting or analytics | High | — |
| 7 | Global mutable theme state (`AppColors.isDark`) | Medium | documented tradeoff in `app_theme.dart` |
| 8 | Settings changes require a keyed remount | Medium | `main.dart` — statics are invisible to Flutter's rebuild |
| 9 | 13 silent `catch (_)` blocks | Medium | no logging; failures are invisible in production |
| 10 | No image disk cache | Medium | `Image.network` re-downloads on scroll |
| 10b | Hero video is refetched per launch | Medium | `hero_video_service.dart` caches per process only |
| 10c | Home decodes video whenever the tab is mounted | Medium | `IndexedStack` keeps it alive across tab switches; should pause when not visible |
| 11 | No retry/backoff | Medium | one blip → error screen |
| 12 | Largest widget file is 430 lines | Low | `suggestion_card.dart` |

### State management

Static singletons exposing `ValueNotifier`s, plus `setState` in screens
(18 call sites). This is **appropriate at 28 files** and will hurt past
roughly fifteen screens or the moment two features need the same async
state. It is not urgent; it is directional.

---

## 2. Target architecture

```
Flutter client
  presentation/   widgets + screens (no business logic, no HTTP)
  application/    Riverpod providers, view models
  domain/         entities, recommendation engine, scoring policy
  data/           repositories, DTOs, provider interfaces
        ↓ HTTPS, user JWT only
Backend API  (FastAPI + PostgreSQL)
  auth · rate limiting · validation · logging
  recommendation service   ← deterministic, testable, no LLM
  AI gateway               ← provider-agnostic, cost-metered, cached
  provider adapters        ← LLM · restaurants · nutrition
        ↓ server-held secrets
Groq / OpenAI · Places · nutrition APIs
```

### Why FastAPI over Node

Not a strong preference, and either would work. FastAPI wins narrowly
here because the recommendation engine is scoring and filtering logic
where Python's readability pays off, Pydantic gives request validation
and typed DTOs in one declaration, and the developer already runs Python
automation tooling. **If the team is stronger in TypeScript, use Node —
this decision is not load-bearing** and the provider abstraction makes it
replaceable.

### The recommendation pipeline

The LLM must not choose the answer. It interprets and explains; ranking
is deterministic, inspectable and unit-testable.

```
1. HARD FILTER    allergies, diet, budget ceiling, distance, open now
                  → a candidate that fails here can never be surfaced
2. CANDIDATE GEN  restaurants + dishes + recipes from real providers
3. SCORE          weighted, configurable, server-side
4. EXPLAIN        LLM writes "why this fits" for the already-chosen winner
```

Scoring weights live in server config, never in UI code:

| Factor | Weight |
|---|---|
| Preference match | 30% |
| Craving / mood | 20% |
| Budget fit | 15% |
| Distance | 10% |
| Restaurant quality | 10% |
| Historical behaviour | 10% |
| Novelty | 5% |

The displayed "92% match" comes from this calculation. **An LLM must
never invent that number** — a fabricated confidence score is worse than
no score, because users trust it.

### Allergy handling is a safety boundary, not a ranking input

Allergies are applied at step 1 as an absolute exclusion, server-side,
before the LLM sees anything. They are never a scoring weight, and the
model is never trusted to enforce them. The UI must state that users
verify allergens with the restaurant; we never claim a meal is safe.

---

## 3. Database (Phase 1 subset)

Full schema in `PRODUCT_ROADMAP.md`. Phase 1 needs only:

```
users              id, auth_provider, created_at
profiles           user_id, display_name, locale, theme
food_preferences   user_id, cuisines[], dislikes[], budget, spice, goal
allergies          user_id, allergen, severity     -- separate table, on purpose
recommendation_sessions  id, user_id, context, created_at
recommendations    session_id, dish, restaurant_id?, score, payload
feedback           recommendation_id, action, rating, created_at
ai_usage           user_id, provider, model, tokens, cost_estimate, feature
```

`allergies` is deliberately its own table rather than a column on
preferences: different lifecycle, different sensitivity, different audit
requirements, and it must be queryable independently of taste data.

---

## 4. What Phase 1 explicitly does not build

Restaurant discovery, menus, groups, date night, pantry, subscriptions,
the restaurant B2B portal. Each is architecturally provided for —
provider interfaces and schema — and none is implemented until the
foundation is proven and there is evidence anyone wants it.
