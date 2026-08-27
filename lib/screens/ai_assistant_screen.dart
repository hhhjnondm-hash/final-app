import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_models.dart';
import '../services/ai_assistant_service.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';

class AiAssistantScreen extends StatefulWidget {
  final AiContextAttachment? initialContext;

  const AiAssistantScreen({
    super.key,
    this.initialContext,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final AiAssistantService _aiService = AiAssistantService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  AiContextAttachment? _activeContext;
  bool _showSidebarOnMobile = false;

  @override
  void initState() {
    super.initState();
    _activeContext = widget.initialContext;
    if (_activeContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleQuickPrompt('اشرح لي معاني وهدايات ${_activeContext!.title}');
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    final ctx = _activeContext;
    setState(() {
      _activeContext = null;
    });

    _aiService.sendMessage(
      query: query,
      contextAttachment: ctx,
    );
    _scrollToBottom();
  }

  void _handleQuickPrompt(String prompt) {
    _aiService.sendMessage(
      query: prompt,
      contextAttachment: _activeContext,
    );
    setState(() {
      _activeContext = null;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      appBar: _buildAppBar(context, isDesktop),
      drawer: isDesktop ? null : _buildMobileDrawer(context),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // Desktop Sidebar
            if (isDesktop) _buildDesktopSidebar(),

            // Main Chat Area
            Expanded(
              child: Column(
                children: [
                  // Active Context Banner (if coming from Quran/Hadith)
                  if (_activeContext != null) _buildContextChip(),

                  // Messages Area or Welcome State
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _aiService,
                      builder: (context, _) {
                        final conv = _aiService.activeConversation;
                        final messages = conv?.messages ?? [];

                        if (messages.isEmpty && !_aiService.isThinking) {
                          return _buildWelcomeState();
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: messages.length + (_aiService.isThinking ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length && _aiService.isThinking) {
                              return _buildThinkingIndicator();
                            }
                            final msg = messages[index];
                            return msg.role == AiMessageRole.user
                                ? _buildUserMessage(msg)
                                : _buildAiResponseCard(msg);
                          },
                        );
                      },
                    ),
                  ),

                  // Religious Safety Disclaimer
                  _buildSafetyDisclaimer(),

                  // Bottom Glass Message Input
                  _buildBottomInputArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: DesignSystem.textWhite, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: DesignSystem.goldGradient,
              shape: BoxShape.circle,
              boxShadow: DesignSystem.goldGlow,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: DesignSystem.bgDarkest, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المساعد الذكي',
                style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'إجابات موثوقة من أمهات المصادر الإسلامية',
                style: TextStyle(color: DesignSystem.goldLight, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_outlined, color: DesignSystem.goldLight),
          tooltip: 'محادثة جديدة',
          onPressed: () {
            _aiService.createNewConversation();
            setState(() => _activeContext = null);
          },
        ),
        if (!isDesktop)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.history_rounded, color: DesignSystem.textWhite),
              tooltip: 'المحادثات السابقة',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.9),
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.gold,
                foregroundColor: DesignSystem.bgDarkest,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('محادثة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                _aiService.createNewConversation();
                setState(() => _activeContext = null);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'المحادثات الأخيرة',
              style: TextStyle(color: DesignSystem.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _aiService,
              builder: (context, _) {
                final convs = _aiService.conversations;
                final activeId = _aiService.activeConversation?.id;

                return ListView.builder(
                  itemCount: convs.length,
                  itemBuilder: (context, index) {
                    final conv = convs[index];
                    final isSelected = conv.id == activeId;

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: DesignSystem.gold.withValues(alpha: 0.12),
                      leading: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: isSelected ? DesignSystem.goldLight : DesignSystem.textMuted,
                        size: 18,
                      ),
                      title: Text(
                        conv.title,
                        style: TextStyle(
                          color: isSelected ? DesignSystem.goldLight : DesignSystem.textWhite,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                        onPressed: () => _aiService.deleteConversation(conv.id),
                      ),
                      onTap: () => _aiService.selectConversation(conv.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: DesignSystem.bgDarkest,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: DesignSystem.goldLight),
                  const SizedBox(width: 10),
                  const Text(
                    'سجل المحادثات',
                    style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: DesignSystem.textWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListenableBuilder(
                listenable: _aiService,
                builder: (context, _) {
                  final convs = _aiService.conversations;
                  final activeId = _aiService.activeConversation?.id;

                  return ListView.builder(
                    itemCount: convs.length,
                    itemBuilder: (context, index) {
                      final conv = convs[index];
                      final isSelected = conv.id == activeId;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: DesignSystem.gold.withValues(alpha: 0.15),
                        leading: const Icon(Icons.chat_bubble_outline_rounded, color: DesignSystem.goldLight),
                        title: Text(
                          conv.title,
                          style: TextStyle(
                            color: isSelected ? DesignSystem.goldLight : DesignSystem.textWhite,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          onPressed: () => _aiService.deleteConversation(conv.id),
                        ),
                        onTap: () {
                          _aiService.selectConversation(conv.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextChip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102A45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF315BEA).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFF536DFF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeContext!.title,
                  style: const TextStyle(color: DesignSystem.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  _activeContext!.content,
                  style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: DesignSystem.textMuted, size: 18),
            onPressed: () => setState(() => _activeContext = null),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    final quickPrompts = [
      {'icon': Icons.menu_book_rounded, 'title': 'تفسير آية قرآنية', 'query': 'ما تفسير آية الكرسي وأبرز دلالاتها؟'},
      {'icon': Icons.auto_stories_rounded, 'title': 'شرح حديث نبوي', 'query': 'اشرح لي حديث: إنما الأعمال بالنيات.'},
      {'icon': Icons.mosque_rounded, 'title': 'أحكام الصلاة', 'query': 'ما هي شروط صحة وأركان الصلاة المفروضة؟'},
      {'icon': Icons.volunteer_activism_rounded, 'title': 'أدعية مستجابة', 'query': 'ما هي جوامع الأدعية النبوية لتفريج الكروب؟'},
      {'icon': Icons.fingerprint_rounded, 'title': 'أذكار الصباح والمساء', 'query': 'ما فضل المداومة على أذكار الصباح والمساء؟'},
      {'icon': Icons.psychology_alt_rounded, 'title': 'سؤال فقهي عام', 'query': 'ما حكم صلاة الاستخارة وكيفية أدائها؟'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Luxury AI Avatar Disc
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  DesignSystem.gold.withValues(alpha: 0.35),
                  const Color(0xFF040E1E),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: DesignSystem.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.gold.withValues(alpha: 0.2),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: DesignSystem.goldLight, size: 40),
          ),
          const SizedBox(height: 18),
          const Text(
            'السلام عليكم ورحمة الله وبركاته 👋',
            style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'أنا رفيقك الذكي للعلوم الشرعية، كيف يمكنني مساعدتك اليوم؟',
            style: TextStyle(color: DesignSystem.goldLight, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Suggestion Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 90,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: quickPrompts.length,
            itemBuilder: (context, idx) {
              final p = quickPrompts[idx];
              return InkWell(
                onTap: () => _handleQuickPrompt(p['query'] as String),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignSystem.bgCard.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DesignSystem.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(p['icon'] as IconData, color: DesignSystem.goldLight, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p['title'] as String,
                          style: const TextStyle(
                            color: DesignSystem.textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(AiMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF172554)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  topRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
                ],
              ),
              child: Text(
                msg.content,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResponseCard(AiMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DesignSystem.bgCard.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: DesignSystem.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: DesignSystem.goldLight, size: 12),
                            SizedBox(width: 4),
                            Text('الإجابة الموثقة', style: TextStyle(color: DesignSystem.goldLight, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Main Text Content
                  Text(
                    msg.content,
                    style: const TextStyle(
                      color: DesignSystem.textWhite,
                      fontSize: 14,
                      height: 1.7,
                      fontFamily: 'Amiri',
                    ),
                  ),

                  // Verified Sources Card
                  if (msg.sources.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF040E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Color(0xFF36B982), size: 14),
                              SizedBox(width: 6),
                              Text('المصادر المعتمدة:', style: TextStyle(color: Color(0xFF36B982), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...msg.sources.map((s) => Text('• ${s.title}: ${s.reference}', style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11))),
                        ],
                      ),
                    ),
                  ],

                  // Follow Up Chips
                  if (msg.followUpQuestions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: msg.followUpQuestions.map((q) {
                        return InkWell(
                          onTap: () => _handleQuickPrompt(q),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF102A45),
                              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                              border: Border.all(color: const Color(0xFF315BEA).withValues(alpha: 0.4)),
                            ),
                            child: Text(q, style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Actions Row (Copy, Save, Share)
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(msg.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: DesignSystem.goldLight, size: 18),
                        tooltip: 'حفظ الإجابة',
                        onPressed: () => _aiService.toggleSaveMessage(msg.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: DesignSystem.textMuted, size: 18),
                        tooltip: 'نسخ الإجابة',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: msg.content));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الإجابة')));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: DesignSystem.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: DesignSystem.bgDarkest, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: DesignSystem.bgCard.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(color: DesignSystem.gold, strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('المساعد يبحث في المصادر المعتمدة...', style: TextStyle(color: DesignSystem.goldLight, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: const Text(
        'المساعد الذكي أداة مساعدة ولا يُغني عن سؤال أهل العلم الثقات في الفتاوى والمسائل الشرعية.',
        style: TextStyle(color: Colors.white38, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: DesignSystem.bgDarkest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.25)),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: DesignSystem.textWhite, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'اكتب سؤالك الشرعي هنا...',
                    hintStyle: TextStyle(color: DesignSystem.textMuted, fontSize: 13),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: DesignSystem.goldGradient,
                shape: BoxShape.circle,
                boxShadow: DesignSystem.goldGlow,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: DesignSystem.bgDarkest, size: 20),
                onPressed: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
