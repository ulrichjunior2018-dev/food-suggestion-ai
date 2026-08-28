import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/chat_message.dart';
import '../models/user_preferences.dart';
import '../services/favorites_service.dart';
import '../services/groq_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/typing_indicator.dart';

/// Prompts offered before the first exchange, so the user is never
/// staring at an empty box wondering what this thing can do.

/// Free-form conversation with the food assistant. Where the onboarding
/// flow answers "give me three dishes", this answers everything after
/// that — substitutions, prep time, "what can I do with what's in my
/// fridge" — and can still return real dish cards inline when the answer
/// is a recommendation rather than an explanation.
class ChatScreen extends StatefulWidget {
  /// Onboarding answers, when the user reached chat through the
  /// questionnaire. Seeds the conversation so the assistant already
  /// knows their diet and budget instead of re-asking.
  final UserPreferences? preferences;

  const ChatScreen({super.key, this.preferences});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _groq = GroqService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];

  late List<Map<String, String>> _history;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _history = GroqService.newChatHistory(preferences: widget.preferences);
    _messages.add(ChatMessage(text: S.chatGreeting, isUser: false));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _sending) return;

    _input.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final result = await _groq.chat(_history, text);
      if (!mounted) return;
      setState(() {
        _history = result.history;
        _messages.add(
          ChatMessage(
            text: result.reply,
            isUser: false,
            suggestions: result.suggestions,
          ),
        );
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(text: e.toString(), isUser: false, isError: true),
        );
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.chatTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: TypingIndicator(),
                      ),
                    );
                  }
                  return _ChatBubble(message: _messages[index]);
                },
              ),
            ),
            if (_messages.length == 1 && !_sending) _StarterRow(onTap: _send),
            _Composer(
              controller: _input,
              enabled: !_sending,
              onSend: () => _send(_input.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick-start prompts, shown only before the first real exchange. Gives
/// the user something to press instead of a blank box — the single most
/// common reason a chat feature goes untouched.
class _StarterRow extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _StarterRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: S.starterPrompts
            .map(
              (s) => PressableScale(
                child: OutlinedButton(
                  onPressed: () => onTap(s),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    side: BorderSide(
                      color: AppColors.charcoal.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(s, style: const TextStyle(fontSize: 13)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 86),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: S.chatHint,
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.tan, width: 1.4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppColors.terracotta,
                    width: 1.6,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.tan, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PressableScale(
            child: Material(
              color: enabled
                  ? AppColors.terracotta
                  : AppColors.terracotta.withValues(alpha: 0.4),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enabled ? onSend : null,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.text.isNotEmpty)
            Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.terracotta
                        : message.isError
                            ? AppColors.errorRed.withValues(alpha: 0.08)
                            : AppColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: isUser
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.shadow.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? Colors.white
                          : message.isError
                              ? AppColors.errorRed
                              : AppColors.charcoal,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          if (message.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ValueListenableBuilder(
                valueListenable: FavoritesService.instance.favorites,
                builder: (context, _, __) {
                  return Column(
                    children: [
                      for (var i = 0; i < message.suggestions.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimatedEntrance(
                            delay: Duration(milliseconds: i * 110),
                            child: SuggestionCard(
                              suggestion: message.suggestions[i],
                              isFavorite: FavoritesService.instance
                                  .isFavorite(message.suggestions[i]),
                              onToggleFavorite: () => FavoritesService.instance
                                  .toggle(message.suggestions[i]),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
