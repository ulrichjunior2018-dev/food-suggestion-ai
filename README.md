# Food Suggestion AI

Onboards a user through a 4-step preference questionnaire (dietary
restriction, favorite cuisines, mood/craving, budget & time), then calls
Groq's free LLM API to generate 3 personalized food suggestions with an
explanation of why each one fits — and keeps the conversation open from
there.

## Features

- **Guided onboarding** — 4-step questionnaire with an animated step
  indicator, feeding a single `UserPreferences` object.
- **AI suggestions** — 3 dishes per request, returned as structured JSON
  so parsing is deterministic rather than scraped from free text.
- **One-tap refinement** — "spicier" / "cheaper" / "something different"
  continue the *same* conversation, so the model adjusts its previous
  answer instead of re-rolling three random new dishes.
- **Conversational assistant** — a full chat screen for anything the
  questionnaire can't express ("what can I do with rice and eggs?",
  "how do I make this dairy-free?"). The assistant replies in prose and
  attaches real dish cards inline when it is actually recommending
  something, using the same card component as the results screen.
- **Real dish photography, resolved by a cascade** — TheMealDB first (an
  actual photograph of that named dish), Pexels stock second, designed
  gradient third. Degrades from *correct* to *plausible* to *designed*,
  never to broken.
- **Qualitative nutrition + goal fit** — each dish carries honest
  descriptors ("protein-rich", "light") and a line on how it serves the
  user's stated goal. Deliberately never numeric — see below.
- **Optional deep profile** — allergies, spice tolerance, cooking
  confidence, time, health goal, household size. Kept off the critical
  path so a first-time user still reaches a suggestion in under a minute.
- **Learns from behaviour** — saved dishes are the positive signal,
  dishes skipped when asking for a refinement are the negative one. Both
  fold into a compact block injected into every prompt. A "What we've
  learned" screen shows exactly what it holds, with a button to clear it.
- **Saved dishes** — bookmark any suggestion; persisted locally and
  restored on next launch.
- **Dietary safety** — restrictions and allergies are enforced by a
  dedicated safety clause injected into every system prompt, not left to
  the wording of a single prompt.
- **Bilingual English / French** — one tap in the header switches the
  entire interface, and the AI is instructed to answer in the same
  language, so dish names and explanations come back in French too rather
  than leaving French chrome around English content.
- **Resilience** — explicit loading, timeout, and error states with retry.
  A slow connection surfaces a human message, never an endless spinner.

## Architecture

```
lib/
├── l10n/            S — every user-facing string, EN + FR
├── models/          UserPreferences, UserProfile, FoodSuggestion, ChatMessage
├── screens/         Onboarding, Suggestions, Chat, Favorites
├── services/        GroqService (AI transport), FavoritesService,
│                   ProfileService (profile + learning),
│                   DishImageService (photo cascade)
├── theme/           AppTheme + AppColors + per-cuisine visual mapping
└── widgets/         SuggestionCard, PreferenceChip, StepProgress,
                     PressableScale, AnimatedEntrance, LoadingState,
                     TypingIndicator, premiumRoute
```

Design decisions worth calling out:

- **One transport, three modes.** `GroqService` exposes `getSuggestions`,
  `refine`, and `chat`, but they all funnel through a single private
  `_rawCompletion` that owns auth, timeout, token budget and HTTP error
  mapping — so those concerns can't drift apart across three call sites.
- **Conversation history is passed back in.** Refinement and chat both
  work by appending to the prior message array, which is what makes them
  contextual rather than stateless one-shot queries.
- **`max_tokens: 2048`, deliberately.** `gpt-oss-20b` is a reasoning
  model that spends part of its completion budget thinking before it
  emits the JSON body. A tight cap truncates it mid-thought and yields
  invalid JSON — found the hard way with a 700-token cap that broke live
  requests.
- **One card component, two surfaces.** `SuggestionCard` is shared by the
  results screen and the chat, rather than a second near-copy that drifts.
- **Storage is defensive.** A device that refuses local storage (private
  browsing, cleared site data) degrades to "favorites don't persist",
  never to a crash on launch.
- **Photos are decoration, not payload.** Every failure path in
  `DishImageService` returns null and the card renders its gradient. The
  dish is the product; a missing photo must never produce a broken frame
  or block a suggestion from appearing.
- **Negative results are cached too.** The Pexels free tier allows 200
  requests/hour and the same dish renders across three screens, so a
  miss is remembered rather than retried on every rebuild.
- **The model returns two names per dish.** `name` is what the user reads
  ("Spicy Tomato Bruschetta"); `canonicalName` is the short, widely-known
  form ("Bruschetta") used purely for image and recipe lookup. Without
  that split, photo search is guessing — this is the single change that
  made pictures actually match the food.
- **Nutrition is qualitative on purpose.** A language model estimating
  calories or macros is guessing, and people make health decisions on
  numbers. The prompt forbids numeric output. Real figures require a real
  nutrition database, and that is a roadmap item rather than a shortcut.
- **Localization without codegen.** For two languages, ARB files plus
  `gen_l10n` buy type-safe keys at the cost of a build step re-run on
  every string change. Named getters on one class give the same
  compile-time safety — a typo is a compile error, not a blank label —
  with no build step. At four or five languages, or with translators
  involved, ARB becomes correct and this file is a mechanical port away.
- **Learning is implicit and visible.** Nobody rates dishes in a food
  app, so the negative signal is taken from asking for a refinement —
  whatever was on screen wasn't it. And because silent profiling is
  unnerving, the Insights screen shows everything held and offers to
  erase it.

## Run it (fastest path: web, no emulator needed)

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Get a free Groq API key: https://console.groq.com → API Keys → Create
3. From this folder, generate the platform scaffolding first (this project
   ships with only `lib/` and `pubspec.yaml` — `flutter create .` adds the
   android/ios/web/etc. folders around them without touching existing
   code):

```bash
flutter create .
flutter pub get

# Generate the app icon and launch screen (once, or after changing them)
dart run flutter_launcher_icons
dart run flutter_native_splash:create

flutter run -d chrome \
  --dart-define=GROQ_API_KEY=your_groq_key \
  --dart-define=PEXELS_API_KEY=your_pexels_key
```

`PEXELS_API_KEY` is optional — omit it and every card renders its
gradient fallback instead of a photograph. Get one free (instant, 200
req/hour) at https://www.pexels.com/api/.

### Running on the iOS Simulator

```bash
open -a Simulator
flutter devices                 # confirm the simulator is listed
flutter run -d iphone \
  --dart-define=GROQ_API_KEY=your_groq_key \
  --dart-define=PEXELS_API_KEY=your_pexels_key
```

The API key is never hardcoded in source — it's injected at run time via
`String.fromEnvironment`, so it never ends up in git history.

## Known pre-launch gap

`--dart-define` injects the API keys **at build time**, which means they
are compiled into the shipped bundle. That is fine for a demo and wrong
for a public launch: anyone can extract them from the built web JS and
spend the quota. A real launch needs a thin backend proxy holding both
keys server-side, with the client calling that instead of Groq and Pexels
directly. This is a deliberate, known limitation rather than an oversight.

## Roadmap

- Backend key proxy (see above — the actual blocker to launching)
- A real nutrition API for numeric macros, replacing the qualitative tags
- Language-independent option values: profile and onboarding selections
  are currently stored as the displayed string, so switching language
  after making a selection leaves those chips unselected until re-picked
- Offline cache of the last suggestion set
- Share a dish to WhatsApp
