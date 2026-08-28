# Food Suggestion AI

Onboards a user through a 4-step preference questionnaire (dietary
restriction, favorite cuisines, mood/craving, budget & time), then calls
Groq's free LLM API to generate 3 personalized food suggestions with an
explanation of why each one fits.

## Architecture

- `lib/models/` — `UserPreferences` (onboarding answers) and
  `FoodSuggestion` (parsed AI response)
- `lib/screens/` — `OnboardingScreen` (questionnaire), `SuggestionScreen`
  (loading/error/results states)
- `lib/services/groq_service.dart` — calls Groq's OpenAI-compatible chat
  completions endpoint, forces structured JSON output so parsing is
  reliable instead of scraping free text
- `lib/widgets/preference_chip.dart` — shared selectable chip used across
  every onboarding step

## Run it (fastest path: web, no emulator needed)

1. Install Flutter if you don't have it: https://docs.flutter.dev/get-started/install
2. Get a free Groq API key: https://console.groq.com → API Keys → Create
3. From this folder, generate the platform scaffolding first (this project
   ships with only `lib/` and `pubspec.yaml` — `flutter create .` adds the
   android/ios/web/etc. folders around them without touching your existing
   code, since those files already exist):

```bash
flutter create .
flutter pub get
flutter run -d chrome --dart-define=GROQ_API_KEY=your_key_here
```

The API key is never hardcoded in source — it's injected at run time so it
never ends up in git history.

## Push to GitHub

```bash
git init
git add .
git commit -m "Food Suggestion AI - MylesTech bootcamp challenge"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/food-suggestion-ai.git
git push -u origin main
```

Create the empty repo on github.com first (no README/gitignore, this
project already has both), then run the commands above.

## Video demo

Record your screen (QuickTime: File → New Screen Recording, or
Cmd+Shift+5) while you: open the app, go through all 4 onboarding steps,
hit "Get My Suggestions," and show the AI results loading and appearing.
Upload to Google Drive, YouTube (unlisted), or Loom, and submit that link.
