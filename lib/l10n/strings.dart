import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { en, fr }

/// Every user-facing string in the app, in both languages.
///
/// Deliberately a plain Dart class rather than ARB files plus `gen_l10n`.
/// For two languages and a single developer, codegen buys type-safe keys
/// at the cost of an extra build step that has to be re-run on every
/// string change — and a missing key still only surfaces at runtime.
/// Named getters give the same compile-time safety with no build step:
/// a typo is a compilation error, not a blank label in front of a user.
/// At four or five languages, or with translators involved, ARB becomes
/// the right call and this file is a mechanical port away from it.
class S {
  S._();

  static const String _storageKey = 'app_language_v1';

  static final ValueNotifier<AppLanguage> language =
      ValueNotifier<AppLanguage>(AppLanguage.en);

  static bool get isFr => language.value == AppLanguage.fr;

  static String _t(String en, String fr) => isFr ? fr : en;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == 'fr') language.value = AppLanguage.fr;
    } catch (_) {
      // Storage unavailable — default to English for this session.
    }
  }

  static Future<void> setLanguage(AppLanguage next) async {
    language.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, next == AppLanguage.fr ? 'fr' : 'en');
    } catch (_) {
      // Non-fatal: the choice holds for this session.
    }
  }

  /// Instruction appended to every system prompt so the AI answers in the
  /// same language as the interface. Localizing the chrome but leaving the
  /// dishes in English would be worse than not localizing at all.
  static String get aiLanguageInstruction => isFr
      ? '\n\nIMPORTANT: Reply entirely in French. Dish names, descriptions, '
          'reasons and all conversational text must be in French. Keep the '
          'JSON keys themselves in English exactly as specified.'
      : '';

  // ---------------------------------------------------------------- app
  static String get appTitle => 'Food Suggestion AI';
  static String get saved => _t('Saved', 'Favoris');
  static String get savedCount => _t('Saved', 'Favoris');
  static String get learned => _t('Learned', 'Appris');
  static String get profile => _t('Profile', 'Profil');

  // ------------------------------------------------------------ welcome
  static String get welcomeHeadline => _t('What should\nI eat?', 'Que dois-je\nmanger ?');
  static String get welcomeBody => _t(
        'Answer a few quick questions and get personalized food suggestions '
            'powered by AI — matched to your diet, mood, and budget. Not happy '
            'with the picks? Refine them, or just ask the assistant directly.',
        'Répondez à quelques questions et recevez des suggestions de repas '
            'personnalisées par IA — adaptées à votre régime, votre humeur et '
            'votre budget. Pas convaincu ? Affinez les propositions, ou posez '
            'directement votre question à l\'assistant.',
      );
  static String get getStarted => _t('Get Started', 'Commencer');
  static String get justAsk => _t('Just ask the assistant', 'Parler à l\'assistant');

  // --------------------------------------------------------- onboarding
  static String get onboardingTitle =>
      _t('Tell us what you\'re craving', 'Dites-nous ce qui vous tente');
  static String get back => _t('Back', 'Retour');
  static String get next => _t('Next', 'Suivant');
  static String get getMySuggestions =>
      _t('Get My Suggestions', 'Voir mes suggestions');

  static List<String> get steps => [
        _t('Dietary needs', 'Régime alimentaire'),
        _t('Favorite cuisines', 'Cuisines préférées'),
        _t('What are you craving?', 'De quoi avez-vous envie ?'),
        _t('Budget & time', 'Budget et temps'),
      ];

  static List<String> get stepSubtitles => [
        _t('Any foods we should avoid?', 'Des aliments à éviter ?'),
        _t('Pick as many as you like', 'Choisissez-en autant que vous voulez'),
        _t('What kind of meal do you want right now?',
            'Quel type de repas vous ferait plaisir maintenant ?'),
        _t('How much time or money do you want to spend?',
            'Combien de temps ou d\'argent voulez-vous y consacrer ?'),
      ];

  static List<String> get dietaryOptions => [
        _t('No restrictions', 'Aucune restriction'),
        _t('Vegetarian', 'Végétarien'),
        _t('Vegan', 'Végétalien'),
        _t('Halal', 'Halal'),
        _t('Gluten-Free', 'Sans gluten'),
        _t('Dairy-Free', 'Sans lactose'),
      ];

  static List<String> get cuisineOptions => [
        _t('Any', 'Peu importe'),
        _t('Italian', 'Italienne'),
        _t('Asian', 'Asiatique'),
        _t('Mexican', 'Mexicaine'),
        _t('American', 'Américaine'),
        _t('African', 'Africaine'),
        _t('Mediterranean', 'Méditerranéenne'),
        _t('Indian', 'Indienne'),
      ];

  static List<String> get moodOptions => [
        _t('Comfort food', 'Réconfortant'),
        _t('Light & fresh', 'Léger et frais'),
        _t('Spicy', 'Épicé'),
        _t('Sweet', 'Sucré'),
        _t('Something new', 'Quelque chose de nouveau'),
      ];

  static List<String> get budgetOptions => [
        _t('Quick & cheap', 'Rapide et économique'),
        _t('Moderate', 'Modéré'),
        _t('Willing to splurge', 'Prêt à me faire plaisir'),
      ];

  // -------------------------------------------------------- suggestions
  static String get suggestionsTitle => _t('Your suggestions', 'Vos suggestions');
  static String get noSuggestions => _t(
        'No suggestions came back — try again.',
        'Aucune suggestion reçue — réessayez.',
      );
  static String get wantSomethingElse =>
      _t('Want something else?', 'Envie d\'autre chose ?');
  static String get spicier => _t('Spicier', 'Plus épicé');
  static String get cheaper => _t('Cheaper', 'Moins cher');
  static String get somethingDifferent =>
      _t('Something different', 'Autre chose');
  static String refinedBanner(String request) => _t(
        'Refined to be more $request, based on your last picks',
        'Affiné pour être plus « $request », d\'après vos dernières suggestions',
      );
  static String get askFollowUp =>
      _t('Ask a follow-up question', 'Poser une question de suivi');
  static String get startOver =>
      _t('Start over with fresh ideas', 'Recommencer avec de nouvelles idées');
  static String get tryAgain => _t('Try again', 'Réessayer');

  // --------------------------------------------------------------- chat
  static String get chatTitle => _t('Food assistant', 'Assistant culinaire');
  static String get chatGreeting => _t(
        "Hey — I'm your food assistant. Ask me what to eat, what to do with "
            "what's in your kitchen, or how to adapt a dish to your diet.",
        'Bonjour — je suis votre assistant culinaire. Demandez-moi quoi manger, '
            'quoi faire avec ce que vous avez en cuisine, ou comment adapter un '
            'plat à votre régime.',
      );
  static String get chatHint =>
      _t('Ask about anything food...', 'Posez votre question culinaire...');
  static List<String> get starterPrompts => [
        _t('What can I cook in 15 minutes?', 'Que puis-je cuisiner en 15 minutes ?'),
        _t('I have rice and eggs — ideas?', 'J\'ai du riz et des œufs — des idées ?'),
        _t('Something filling but not heavy', 'Quelque chose de nourrissant mais léger'),
      ];
  static String get didNotCatch => _t(
        'Sorry — I did not catch that. Try again?',
        'Désolé — je n\'ai pas compris. Réessayez ?',
      );

  // ---------------------------------------------------------- favorites
  static String get savedDishes => _t('Saved dishes', 'Plats enregistrés');
  static String get nothingSaved =>
      _t('Nothing saved yet', 'Rien d\'enregistré pour l\'instant');
  static String get nothingSavedBody => _t(
        'Tap the bookmark on any dish to keep it here for later.',
        'Touchez le signet sur un plat pour le retrouver ici plus tard.',
      );

  // --------------------------------------------------------------- card
  static String get saveThisDish => _t('Save this dish', 'Enregistrer ce plat');
  static String get savedTooltip => _t('Saved', 'Enregistré');
  static String get copyDish =>
      _t('Copy dish to clipboard', 'Copier le plat');
  static String copiedToClipboard(String name) => _t(
        'Copied "$name" to your clipboard',
        '« $name » copié dans le presse-papiers',
      );

  // ------------------------------------------------------------ loading
  static List<String> get loadingPhrases => [
        _t('Simmering some ideas...', 'Mijotage de quelques idées...'),
        _t('Tasting a few flavors...', 'Dégustation de quelques saveurs...'),
        _t('Weighing your cravings...', 'Analyse de vos envies...'),
        _t('Plating your picks...', 'Dressage de vos plats...'),
      ];

  // ------------------------------------------------------------ profile
  static String get profileTitle => _t('Your profile', 'Votre profil');
  static String get profileIntro => _t(
        'Everything here is optional. The more you tell us, the sharper the '
            'suggestions get — and it stays on this device.',
        'Tout est facultatif ici. Plus vous nous en dites, plus les suggestions '
            'sont précises — et tout reste sur cet appareil.',
      );
  static String get allergies => _t('Allergies', 'Allergies');
  static String get allergiesSub => _t(
        'Free text — be as specific as you need',
        'Texte libre — soyez aussi précis que nécessaire',
      );
  static String get allergiesHint =>
      _t('e.g. peanuts, shellfish', 'ex. arachides, fruits de mer');
  static String get spiceTolerance =>
      _t('Spice tolerance', 'Tolérance au piment');
  static String get cookingConfidence =>
      _t('How confident are you cooking?', 'À quel point cuisinez-vous ?');
  static String get timeUsually =>
      _t('Time you usually have', 'Temps dont vous disposez');
  static String get eatingFor =>
      _t('What are you eating for?', 'Quel est votre objectif ?');
  static String get eatingForSub => _t(
        'Used to explain how each dish serves your goal',
        'Sert à expliquer comment chaque plat soutient votre objectif',
      );
  static String get cookingFor => _t('Cooking for', 'Vous cuisinez pour');
  static String get saveProfile => _t('Save profile', 'Enregistrer le profil');
  static String get profileSaved => _t(
        'Profile saved — suggestions will use this',
        'Profil enregistré — les suggestions en tiendront compte',
      );

  static List<String> get spiceOptions => [
        _t('Mild', 'Doux'),
        _t('Medium', 'Moyen'),
        _t('Hot', 'Piquant'),
        _t('Very hot', 'Très piquant'),
      ];
  static List<String> get skillOptions => [
        _t('Beginner', 'Débutant'),
        _t('Comfortable', 'À l\'aise'),
        _t('Confident', 'Expérimenté'),
      ];
  static List<String> get timeOptions => [
        _t('Under 15 min', 'Moins de 15 min'),
        _t('15–30 min', '15–30 min'),
        _t('30–60 min', '30–60 min'),
        _t('No rush', 'Pas pressé'),
      ];
  static List<String> get goalOptions => [
        _t('Just eat well', 'Simplement bien manger'),
        _t('Lose weight', 'Perdre du poids'),
        _t('Build muscle', 'Prendre du muscle'),
        _t('More energy', 'Plus d\'énergie'),
        _t('Eat on a budget', 'Manger à petit prix'),
      ];
  static List<String> get householdOptions => [
        _t('Just me', 'Moi seulement'),
        _t('Two of us', 'Nous deux'),
        _t('3–4', '3–4'),
        _t('5+', '5+'),
      ];

  // ----------------------------------------------------------- insights
  static String get insightsTitle => _t('What we\'ve learned', 'Ce que nous avons appris');
  static String get insightsIntro => _t(
        'Everything below stays on this device and is folded into each '
            'request so suggestions get closer to you over time.',
        'Tout ce qui suit reste sur cet appareil et est intégré à chaque '
            'requête pour que les suggestions vous correspondent de mieux en mieux.',
      );
  static String get nothingLearned =>
      _t('Nothing learned yet', 'Rien d\'appris pour l\'instant');
  static String get nothingLearnedBody => _t(
        'Save a few dishes, skip a few others, or fill in your profile — '
            'this is where it all shows up.',
        'Enregistrez quelques plats, passez-en d\'autres, ou remplissez votre '
            'profil — tout apparaîtra ici.',
      );
  static String get youToldUs => _t('You told us', 'Ce que vous nous avez dit');
  static String get cuisinesYouLike =>
      _t('Cuisines you gravitate to', 'Cuisines qui vous attirent');
  static String get dishesYouKept => _t('Dishes you kept', 'Plats que vous avez gardés');
  static String get dishesYouSkipped =>
      _t('Dishes you moved past', 'Plats que vous avez passés');
  static String get goal => _t('Goal', 'Objectif');
  static String get cookingConfidenceShort =>
      _t('Cooking confidence', 'Niveau en cuisine');
  static String get timeAvailable => _t('Time available', 'Temps disponible');
  static String savedDishCount(int n) => _t(
        '$n saved dish${n == 1 ? '' : 'es'}',
        '$n plat${n == 1 ? '' : 's'} enregistré${n == 1 ? '' : 's'}',
      );
  static String savedTotal(int n) => _t('$n saved', '$n enregistré${n == 1 ? '' : 's'}');
  static String get recentlySkipped => _t('Recently skipped', 'Récemment passés');
  static String get clearLearned => _t(
        'Clear what was learned from my skips',
        'Effacer ce qui a été appris de mes refus',
      );

  // ------------------------------------------------------------- errors
  static String get noApiKey => _t(
        'No API key configured. Run the app with:\n'
            'flutter run -d chrome --dart-define=GROQ_API_KEY=your_key_here',
        'Aucune clé API configurée. Lancez l\'application avec :\n'
            'flutter run -d chrome --dart-define=GROQ_API_KEY=votre_cle',
      );
  static String get timedOut => _t(
        'That took too long — your connection might be slow right now. Try again?',
        'Cela a pris trop de temps — votre connexion est peut-être lente. Réessayer ?',
      );
  static String couldNotReach(String detail) => _t(
        'Could not reach Groq — check your connection: $detail',
        'Impossible de joindre Groq — vérifiez votre connexion : $detail',
      );
}
