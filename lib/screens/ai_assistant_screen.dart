import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/ai_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final ai = Provider.of<AIProvider>(context, listen: false);
    ai.sendMessage(text);
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = Provider.of<ProfileProvider>(context);
    final ai = Provider.of<AIProvider>(context);

    final userName = profile.fullName.isNotEmpty ? profile.fullName : auth.fullName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────────────
            _buildHeader(userName, profile),
            // ─── Messages ───────────────────────────────────────────────
            Expanded(child: _buildMessageList(ai, userName, profile)),
            // ─── Suggested Prompts ──────────────────────────────────────
            if (ai.messages.isEmpty) _buildSuggestedPrompts(ai, profile),
            // ─── Input Bar ──────────────────────────────────────────────
            _buildInputBar(ai),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(String userName, ProfileProvider profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Animated DevZen Logo as AI Avatar
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleAccent.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset('lib/logo.png', fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DevZen AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userName.isNotEmpty
                      ? 'Your personal developer intelligence'
                      : 'Personalized to your profile & GitHub',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Online indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.greenAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.greenAccent,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Message List ─────────────────────────────────────────────────────────

  Widget _buildMessageList(AIProvider ai, String userName, ProfileProvider profile) {
    if (ai.messages.isEmpty) {
      return _buildWelcome(userName, profile);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: ai.messages.length + (ai.isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == ai.messages.length) {
          return _buildTypingIndicator();
        }
        final msg = ai.messages[i];
        final isUser = msg['role'] == 'user';
        return _buildMessage(msg['content'] ?? '', isUser);
      },
    );
  }

  Widget _buildWelcome(String userName, ProfileProvider profile) {
    final greeting = userName.isNotEmpty ? 'Hey $userName!' : 'Hey there!';
    final projectCount = profile.projects.length;
    final skillCount = profile.skills.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleAccent.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('lib/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            projectCount > 0
                ? "I know about your $projectCount projects, $skillCount skills, and all your GitHub activity."
                : "I'm ready to help you build your developer identity. Upload a resume to get started.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "What can I help you with today?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // DevZen AI avatar in chat
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleAccent.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('lib/logo.png', fit: BoxFit.contain),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AppColors.blueAccent, AppColors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : AppColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.glassBorder, width: 0.5),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            child: ClipOval(
              child: Image.asset('lib/logo.png', fit: BoxFit.contain),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(200),
                const SizedBox(width: 4),
                _dot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.purpleAccent,
          ),
        ),
      ),
      onEnd: () => setState(() {}),
    );
  }

  // ─── Suggested Prompts ────────────────────────────────────────────────────

  Widget _buildSuggestedPrompts(AIProvider ai, ProfileProvider profile) {
    final prompts = _getPersonalizedPrompts(profile);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          return GestureDetector(
            onTap: () {
              _msgCtrl.text = prompts[i];
              _sendMessage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                prompts[i],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getPersonalizedPrompts(ProfileProvider profile) {
    final prompts = <String>[];
    if (profile.projects.isNotEmpty) {
      prompts.add('Explain my ${profile.projects.first.title} project');
    }
    prompts.add('Generate my LinkedIn bio');
    prompts.add('What skills should I add?');
    if (profile.projects.length > 1) {
      prompts.add('Summarize all my projects');
    }
    prompts.add('How can I improve my Zen Score?');
    prompts.add('Generate a README for my top project');
    return prompts;
  }

  // ─── Input Bar ────────────────────────────────────────────────────────────

  Widget _buildInputBar(AIProvider ai) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom > 0 ? 16.0 : 104.0;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ask DevZen AI anything...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: ai.isLoading ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ai.isLoading
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.blueAccent, AppColors.purpleAccent],
                      ),
                color: ai.isLoading ? AppColors.surfaceLight : null,
              ),
              child: Icon(
                ai.isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
