# Product Roadmap

**Positioning:** an AI food *decision* assistant. It solves one problem
extremely well — *"I'm hungry and I don't know what to eat"* — and answers
in seconds, with confidence, not with a list of search results.

**Market:** US / DMV first. Google Places coverage is dense there, hours
and ratings are reliable, and delivery integrations exist. The tradeoff
is competing beside Yelp, Google Maps and DoorDash — none of which
*decide for you*, which is the wedge.

**North star:** Successful Food Decisions per Weekly Active User. A
decision counts when the user saves, likes, requests directions, opens
the restaurant, starts the recipe, or marks the meal eaten.

---

## Where the product actually is

Working today: 4-step onboarding, AI suggestions with structured output,
conversational refinement, a food assistant chat with inline dish cards,
saved dishes, an optional deep profile, implicit learning from saves and
skips, bilingual EN/FR, dark mode, real dish photography with graceful
fallback.

Honest gap: **it tells you what to eat but not how to make it or where to
get it.** Both halves of the product thesis are missing. Everything
below is sequenced against closing that.

---

## Phase 1 — Production foundation *(current)*

Not user-visible. Everything downstream depends on it.

- Backend service (FastAPI + PostgreSQL), `.env.example`, no committed secrets
- Auth: guest, email, Google, Apple — guest must reach first value without signup
- AI gateway: provider-agnostic, per-user budget, usage metering, cache
- Move Groq and Pexels behind the backend — closes SEC-1
- Domain layer: recommendation pipeline with hard filters and configurable weights
- Server-side allergy filtering, with tests
- Structured logging, crash reporting, analytics foundation
- Flutter test suite + GitHub Actions CI
- Reconcile the stale GitHub repo with the working tree

**Exit:** no secret in the client; allergy filtering proven by test; CI
green on every push.

## Phase 2 — The decision product

- **Decide For Me** — one tap, one confident answer. The differentiator.
- Home redesigned around *"What are we eating?"* with quick-intent chips
- Real restaurant discovery behind a swappable provider interface
- Result card: dish, restaurant, match %, rating, distance, price, open now
- Directions, save, like, dislike, never-suggest
- **Recipes** — TheMealDB already returns ingredients and instructions and
  we currently discard them. Highest value-to-effort item in the product.
- Feedback loop feeding the ranking

**Exit:** a first-time user reaches a useful decision in under 10 seconds.

## Phase 3 — Intelligence

Behavioural learning server-side, time-of-day personalization, tuned
weights, budget intelligence, explanations grounded in real signals.

## Phase 4 — Cooking

Pantry, cook-vs-order comparison, missing-ingredient logic, grocery list.

## Phase 5 — Social

Group decisions with invite links, overlap-based compromise ranking,
date-night mode.

## Phase 6 — Monetization

Free tier keeps the core decision experience. Pro (~$4.99/mo) adds
unlimited AI, pantry intelligence, meal planning, budget tracking.
Family (~$8.99/mo) adds shared profiles and lists. **The first-value
experience is never paywalled.**

---

## Unit economics — the question nobody has asked

| Cost | Today | At 10,000 MAU |
|---|---|---|
| LLM | free tier | ~2 calls/session, unmodeled — **needs sizing** |
| Pexels images | free, 20k/mo | ceiling at ~3,300 sessions/mo — **breaks first** |
| Pexels hero video | 1 request + ~2–5MB per launch | shares the same 20k/mo ceiling; the bandwidth is the real cost, not the quota |
| Places | not integrated | per-request billing, needs a card on file |
| Hosting | none | modest, real |

Three levers, in order of impact: a **server-side cache** (identical
requests currently pay twice), **cheap models for simple tasks**, and
**per-user budgets**. All three require the Phase 1 gateway, which is
another reason it comes first.

---

## Full data model *(target)*

```
users · profiles · food_preferences · allergies · dietary_preferences
favorite_foods · favorite_restaurants · recommendation_sessions
recommendations · recommendation_feedback · meal_history · saved_items
restaurants_cache · recipes · pantry_items
groups · group_members · group_preferences · subscriptions
```

Phase 1 builds the first eight. The rest exist as schema intent so
today's decisions do not block tomorrow's features.

---

## Credentials required from the owner

Architecture, config and integration code can be written without these;
they block deployment, not development.

| Needed for | Credential | Cost |
|---|---|---|
| Restaurant discovery | Google Places API key + billing | pay per request |
| Backend hosting | Railway / Fly / Render account | ~$5–20/mo |
| Database | Supabase or managed Postgres | free tier viable |
| Crash reporting | Sentry DSN | free tier viable |
| iOS release | Apple Developer Program | $99/yr |
| Android release | Play Console | $25 once |

---

## Explicitly not building yet

Restaurant B2B portal, sponsored placement, delivery integrations,
photo-based pantry recognition, nutrition API. Each is defensible later
and none is defensible before there is evidence of use.

## Principles

1. AI interprets and explains. It never invents facts, scores, or safety.
2. The user never sees an invented dish presented as a real menu item.
3. Allergies are a filter, never a ranking weight.
4. Unavailable data is labelled unavailable, never filled in plausibly.
5. Sponsored content is labelled. Ranking is never sold.
6. One excellent decision beats fifty search results.
