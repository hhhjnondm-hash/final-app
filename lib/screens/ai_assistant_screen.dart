import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_models.dart';
import '../services/ai_assistant_service.dart';

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
  int _selectedBottomNavIndex = 0; // 0: الرئيسية, 1: السجل, 2: المفضلة, 3: الإعدادات

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

  void _openQuestionBrowserModal([String? categoryFilter]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionBrowserSheet(
        aiService: _aiService,
        initialCategory: categoryFilter,
        onSelectQuestion: (qText) {
          Navigator.pop(ctx);
          _handleQuickPrompt(qText);
        },
      ),
    );
  }

  void _openSavedMessagesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SavedMessagesSheet(
        aiService: _aiService,
        onSelectPrompt: (q) {
          Navigator.pop(ctx);
          _handleQuickPrompt(q);
        },
      ),
    );
  }

  void _openHistoryDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HistorySheet(
        aiService: _aiService,
        onSelectConversation: (id) {
          _aiService.selectConversation(id);
          Navigator.pop(ctx);
        },
        onNewConversation: () {
          _aiService.createNewConversation();
          setState(() => _activeContext = null);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SettingsSheet(
        aiService: _aiService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      appBar: _buildAppBar(context),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Active Context Banner (if any)
            if (_activeContext != null) _buildContextChip(),

            // Main View Area
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

            // Bottom Input Bar with mic & gold send button
            _buildBottomInputArea(),

            // Bottom Navigation Bar (الرئيسية، السجل، المفضلة، الإعدادات)
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE8D29A), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'المساعد الذكي',
            style: TextStyle(
              color: Color(0xFFF6F8FA),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 2),
          Text(
            'إجابات موثوقة من المصادر الإسلامية',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
      actions: [
        // Theme moon badge or history
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF162030),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.nights_stay_rounded, color: Color(0xFFE8D29A), size: 16),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFFE8D29A), size: 20),
          tooltip: 'المفضلة والمحفوظات',
          onPressed: _openSavedMessagesModal,
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Color(0xFFE8D29A), size: 22),
          tooltip: 'المحادثات السابقة',
          onPressed: _openHistoryDrawer,
        ),
        IconButton(
          icon: const Icon(Icons.add_rounded, color: Color(0xFFE8D29A), size: 24),
          tooltip: 'محادثة جديدة',
          onPressed: () {
            _aiService.createNewConversation();
            setState(() => _activeContext = null);
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildContextChip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFFE8D29A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeContext!.title,
                  style: const TextStyle(color: Color(0xFFF6F8FA), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                Text(
                  _activeContext!.content,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 16),
            onPressed: () => setState(() => _activeContext = null),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    final categories = [
      {
        'title': 'تفسير آية قرآنية',
        'sub': 'تفسير مبسط وموثوق',
        'icon': Icons.menu_book_rounded,
        'category': 'القرآن والتفسير',
        'query': 'ما تفسير سورة الإخلاص ودلالاتها العظيمة؟',
      },
      {
        'title': 'شرح حديث نبوي',
        'sub': 'مع الشرح والفوائد',
        'icon': Icons.auto_stories_rounded,
        'category': 'الحديث الشريف والسنة',
        'query': 'اشرح لي حديث: «إنما الأعمال بالنيات».',
      },
      {
        'title': 'أحكام الصلاة',
        'sub': 'للعبادات والمعاملات',
        'icon': Icons.mosque_rounded,
        'category': 'الصلاة والعبادات',
        'query': 'ما هي أركان الصلاة الأربعة عشر وشروط صحتها؟',
      },
      {
        'title': 'أدعية مستجابة',
        'sub': 'من القرآن والسنة',
        'icon': Icons.volunteer_activism_rounded,
        'category': 'الأذكار والأدعية',
        'query': 'ما هي جوامع الأدعية النبوية لتفريج الكروب والهموم؟',
      },
      {
        'title': 'أذكار الصباح والمساء',
        'sub': 'من الكتاب والسنة',
        'icon': Icons.fingerprint_rounded,
        'category': 'الأذكار والأدعية',
        'query': 'ما فضل المداومة على أذكار الصباح والمساء؟',
      },
      {
        'title': 'سؤال فقهي عام',
        'sub': 'إجابات من أهل العلم',
        'icon': Icons.help_outline_rounded,
        'category': 'الأخلاق والمعاملات',
        'query': 'ما حكم صلاة الاستخارة وكيفية أدائها الصحيحة؟',
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Top Luxury Arch Illustration with Quran & Lanterns
          _buildHeroMosqueArchHeader(),

          const SizedBox(height: 14),

          // Welcome greeting
          const Text(
            'السلام عليكم ورحمة الله وبركاته 👋',
            style: TextStyle(
              color: Color(0xFFF6F8FA),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'أنا رفيقك الذكي للعلوم الشرعية، كيف يمكنني مساعدتك اليوم؟',
            style: TextStyle(
              color: Color(0xFFE8D29A),
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Horizontal Golden Divider Ornament
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 50, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.4)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.star_rate_rounded, color: Color(0xFFC89B3C), size: 14),
              ),
              Container(width: 50, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.4)),
            ],
          ),

          const SizedBox(height: 18),

          // 2-Column Grid of 6 Luxury Category Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: categories.length,
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              return _buildCategoryGridTile(
                title: cat['title'] as String,
                subtitle: cat['sub'] as String,
                icon: cat['icon'] as IconData,
                category: cat['category'] as String,
                query: cat['query'] as String,
              );
            },
          ),

          const SizedBox(height: 16),

          // Quick Question Bank Explorer Banner
          InkWell(
            onTap: () => _openQuestionBrowserModal(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF101924),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.library_books_rounded, color: Color(0xFFE8D29A), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'تصفح بنك الأسئلة الشرعية (150 سؤال)',
                          style: TextStyle(color: Color(0xFFF6F8FA), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        Text(
                          'اضغط لاستعراض كافة الأقسام والأسئلة الجاهزة',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFFE8D29A), size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeroMosqueArchHeader() {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.35), width: 1.2),
        gradient: const RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.2,
          colors: [
            Color(0xFF261D0F),
            Color(0xFF131A26),
            Color(0xFF070B11),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arch Frame Outline SVG/Path effect
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8D29A).withValues(alpha: 0.15)),
              ),
            ),
          ),

          // Mosque Silhouette & Lanterns Visual Composition
          Positioned(
            top: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.light_mode_rounded, color: const Color(0xFFE8D29A).withValues(alpha: 0.8), size: 26),
                const SizedBox(width: 24),
                const Icon(Icons.nightlight_round, color: Color(0xFFFFD56B), size: 36),
                const SizedBox(width: 24),
                Icon(Icons.light_mode_rounded, color: const Color(0xFFE8D29A).withValues(alpha: 0.8), size: 26),
              ],
            ),
          ),

          // Holy Quran Stand in Center
          Positioned(
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC89B3C), Color(0xFF996515)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF070B11), size: 38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGridTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String category,
    required String query,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleQuickPrompt(query),
        onLongPress: () => _openQuestionBrowserModal(category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF101722),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC89B3C).withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF94A3B8), size: 12),
                  Icon(icon, color: const Color(0xFFE8D29A), size: 24),
                  const SizedBox(width: 12), // Balance symmetry
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF6F8FA),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontFamily: 'Cairo',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserMessage(AiMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8D29A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF070B11), size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141C28),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  topRight: Radius.circular(4),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                msg.content,
                style: const TextStyle(
                  color: Color(0xFFF6F8FA),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResponseCard(AiMessage msg) {
    // Separate main content and hadith citation if present
    final parsed = _parseResponseContent(msg.content);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1621),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Pill "الإجابة الموثقة"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2837),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFFE8D29A), size: 14),
                            SizedBox(width: 5),
                            Text(
                              'الإجابة الموثقة',
                              style: TextStyle(
                                color: Color(0xFFE8D29A),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Main Text Content with clean bullet lines and checkmarks
                  _buildFormattedAnswerBody(parsed.mainBody),

                  // Evidence Box (من الأدلة) if available
                  if (parsed.evidenceText != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F2C),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.menu_book_rounded, color: Color(0xFFE8D29A), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'من الأدلة:',
                                style: TextStyle(
                                  color: Color(0xFFE8D29A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            parsed.evidenceText!,
                            style: const TextStyle(
                              color: Color(0xFFF6F8FA),
                              fontSize: 13,
                              height: 1.6,
                              fontFamily: 'Amiri',
                            ),
                          ),
                          if (msg.sources.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              msg.sources.first.reference,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 16),

                  // Action Row: Copy, Share, Bookmark, Thumbs Up, Thumbs Down
                  Row(
                    children: [
                      // Thumbs up / down
                      IconButton(
                        icon: Icon(
                          msg.isLiked == true ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                          color: msg.isLiked == true ? const Color(0xFFE8D29A) : const Color(0xFF94A3B8),
                          size: 18,
                        ),
                        tooltip: 'إجابة مفيدة',
                        onPressed: () => _aiService.rateMessage(msg.id, true),
                      ),
                      IconButton(
                        icon: Icon(
                          msg.isLiked == false ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined,
                          color: msg.isLiked == false ? Colors.redAccent : const Color(0xFF94A3B8),
                          size: 18,
                        ),
                        tooltip: 'إجابة غير دقيقة',
                        onPressed: () => _aiService.rateMessage(msg.id, false),
                      ),
                      const Spacer(),

                      // Bookmark Save
                      InkWell(
                        onTap: () {
                          _aiService.toggleSaveMessage(msg.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg.isSaved ? 'تمت إزالة الإجابة من المحفوظات' : 'تم حفظ الإجابة في المفضلة'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg.isSaved ? 'محفوظ' : 'حفظ',
                                style: TextStyle(
                                  color: msg.isSaved ? const Color(0xFFE8D29A) : const Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                msg.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: msg.isSaved ? const Color(0xFFE8D29A) : const Color(0xFF94A3B8),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Share
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تجهيز النص للمشاركة ونسخه'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('مشاركة', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo')),
                              SizedBox(width: 4),
                              Icon(Icons.share_outlined, color: Color(0xFF94A3B8), size: 16),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Copy
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الإجابة'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('نسخ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo')),
                              SizedBox(width: 4),
                              Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Suggested follow-up prompt chips (أسئلة مقترحة)
                  if (msg.followUpQuestions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE8D29A), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'أسئلة مقترحة:',
                          style: TextStyle(
                            color: Color(0xFFE8D29A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: msg.followUpQuestions.map((q) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: () => _handleQuickPrompt(q),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141C28),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  q,
                                  style: const TextStyle(
                                    color: Color(0xFFF6F8FA),
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // AI Sparkle Disc Avatar
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF162030),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC89B3C), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFE8D29A), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAnswerBody(String text) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 4);

        if (trimmed.startsWith('•') || trimmed.startsWith('-') || RegExp(r'^\d+\.').hasMatch(trimmed)) {
          final clean = trimmed.replaceAll(RegExp(r'^[•\-\d\.]\s*'), '');
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 6),
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFFC89B3C), size: 14),
                ),
                Expanded(
                  child: Text(
                    clean,
                    style: const TextStyle(
                      color: Color(0xFFF6F8FA),
                      fontSize: 13,
                      height: 1.6,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            trimmed,
            style: const TextStyle(
              color: Color(0xFFF6F8FA),
              fontSize: 13,
              height: 1.6,
              fontFamily: 'Cairo',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1621),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(color: Color(0xFFE8D29A), strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'المساعد يبحث في المصادر المعتمدة...',
                  style: TextStyle(color: Color(0xFFE8D29A), fontSize: 11, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF070B11),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Mic Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141C28),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.mic_rounded, color: Color(0xFFE8D29A), size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ميزة الإدخال الصوتي مفعلة، يمكنك أيضاً الكتابة مباشرة.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Text Input Pill
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF101722),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Color(0xFFF6F8FA), fontSize: 13, fontFamily: 'Cairo'),
                  decoration: const InputDecoration(
                    hintText: 'اكتب سؤالك الشرعي هنا ...',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Cairo'),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Gold Circular Send Button
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66C89B3C),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF070B11), size: 20),
                onPressed: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final navTabs = [
      {'label': 'الرئيسية', 'icon': Icons.home_rounded},
      {'label': 'السجل', 'icon': Icons.access_time_rounded},
      {'label': 'المفضلة', 'icon': Icons.star_border_rounded},
      {'label': 'الإعدادات', 'icon': Icons.settings_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF070B11),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navTabs.length, (i) {
            final isSelected = _selectedBottomNavIndex == i;
            final tab = navTabs[i];
            return InkWell(
              onTap: () {
                setState(() => _selectedBottomNavIndex = i);
                if (i == 1) _openHistoryDrawer();
                if (i == 2) _openSavedMessagesModal();
                if (i == 3) _openSettingsModal();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      color: isSelected ? const Color(0xFFE8D29A) : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFE8D29A) : const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  _ParsedResponse _parseResponseContent(String content) {
    if (content.contains('قال النبي ﷺ:') || content.contains('قال تعالى:') || content.contains('«')) {
      final idx = content.indexOf('قال النبي ﷺ:');
      if (idx != -1) {
        return _ParsedResponse(
          mainBody: content.substring(0, idx).trim(),
          evidenceText: content.substring(idx).trim(),
        );
      }
    }
    return _ParsedResponse(mainBody: content, evidenceText: null);
  }
}

class _ParsedResponse {
  final String mainBody;
  final String? evidenceText;

  _ParsedResponse({required this.mainBody, this.evidenceText});
}

/// Question Explorer Bottom Sheet (150+ Questions Bank)
class _QuestionBrowserSheet extends StatefulWidget {
  final AiAssistantService aiService;
  final String? initialCategory;
  final ValueChanged<String> onSelectQuestion;

  const _QuestionBrowserSheet({
    required this.aiService,
    this.initialCategory,
    required this.onSelectQuestion,
  });

  @override
  State<_QuestionBrowserSheet> createState() => _QuestionBrowserSheetState();
}

class _QuestionBrowserSheetState extends State<_QuestionBrowserSheet> {
  late String _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'الكل';
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['الكل', ...widget.aiService.categories];
    final all = widget.aiService.getQuestionsByCategory(_selectedCategory);
    final filtered = _searchQuery.isEmpty
        ? all
        : all.where((q) {
            final text = '${q['question']} ${q['category']} ${q['answer']}'.toLowerCase();
            return text.contains(_searchQuery.toLowerCase());
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0C1017),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.library_books_rounded, color: Color(0xFFE8D29A)),
                  const SizedBox(width: 10),
                  Text(
                    'بنك الأسئلة الشرعية المعتمدة (${all.length} سؤال)',
                    style: const TextStyle(
                      color: Color(0xFFF6F8FA),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                style: const TextStyle(color: Color(0xFFF6F8FA), fontSize: 13, fontFamily: 'Cairo'),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'ابحث في كافة الأسئلة والفتاوى...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE8D29A), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF141C28),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Category Filter Pills
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSel = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      selectedColor: const Color(0xFFC89B3C),
                      backgroundColor: const Color(0xFF141C28),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFF070B11) : const Color(0xFFF6F8FA),
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontFamily: 'Cairo',
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Questions List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد أسئلة تطابق بحثك',
                        style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final q = filtered[idx];
                        return Card(
                          color: const Color(0xFF101722),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: const Color(0xFFC89B3C).withValues(alpha: 0.2)),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.help_outline_rounded, color: Color(0xFFE8D29A), size: 16),
                            ),
                            title: Text(
                              q['question'] ?? '',
                              style: const TextStyle(
                                color: Color(0xFFF6F8FA),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            subtitle: Text(
                              '${q['category']} • ${q['source'] ?? ''}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Cairo'),
                            ),
                            trailing: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFFE8D29A), size: 12),
                            onTap: () => widget.onSelectQuestion(q['question']),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// History Bottom Sheet
class _HistorySheet extends StatelessWidget {
  final AiAssistantService aiService;
  final ValueChanged<String> onSelectConversation;
  final VoidCallback onNewConversation;

  const _HistorySheet({
    required this.aiService,
    required this.onSelectConversation,
    required this.onNewConversation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0C1017),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: Color(0xFFE8D29A)),
                  const SizedBox(width: 10),
                  const Text(
                    'سجل المحادثات',
                    style: TextStyle(color: Color(0xFFF6F8FA), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC89B3C),
                      foregroundColor: const Color(0xFF070B11),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('محادثة جديدة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    onPressed: onNewConversation,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListenableBuilder(
                listenable: aiService,
                builder: (context, _) {
                  final convs = aiService.conversations;
                  final activeId = aiService.activeConversation?.id;

                  if (convs.isEmpty) {
                    return const Center(
                      child: Text('لا توجد محادثات سابقة', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo')),
                    );
                  }

                  return ListView.builder(
                    itemCount: convs.length,
                    itemBuilder: (context, index) {
                      final conv = convs[index];
                      final isSelected = conv.id == activeId;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                        leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFE8D29A)),
                        title: Text(
                          conv.title,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFE8D29A) : const Color(0xFFF6F8FA),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          onPressed: () => aiService.deleteConversation(conv.id),
                        ),
                        onTap: () => onSelectConversation(conv.id),
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
}

/// Saved / Bookmarked Answers Sheet
class _SavedMessagesSheet extends StatelessWidget {
  final AiAssistantService aiService;
  final ValueChanged<String> onSelectPrompt;

  const _SavedMessagesSheet({
    required this.aiService,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final allSaved = <AiMessage>[];
    for (final conv in aiService.conversations) {
      for (final msg in conv.messages) {
        if (msg.isSaved) allSaved.add(msg);
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0C1017),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_rounded, color: Color(0xFFE8D29A)),
                  const SizedBox(width: 10),
                  Text(
                    'الإجابات المحفوظة (${allSaved.length})',
                    style: const TextStyle(color: Color(0xFFF6F8FA), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: allSaved.isEmpty
                  ? const Center(
                      child: Text(
                        'لم تقم بحفظ أي إجابة بعد.\nاضغط على أيقونة الحفظ بجوار أي إجابة لإضافتها هنا.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allSaved.length,
                      itemBuilder: (context, idx) {
                        final msg = allSaved[idx];
                        return Card(
                          color: const Color(0xFF101722),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.content,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFFF6F8FA), fontSize: 12, height: 1.5, fontFamily: 'Cairo'),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFE8D29A)),
                                      label: const Text('نسخ', style: TextStyle(color: Color(0xFFE8D29A), fontSize: 11, fontFamily: 'Cairo')),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: msg.content));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الإجابة')));
                                      },
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                      label: const Text('إزالة', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: 'Cairo')),
                                      onPressed: () => aiService.toggleSaveMessage(msg.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings Sheet
class _SettingsSheet extends StatelessWidget {
  final AiAssistantService aiService;

  const _SettingsSheet({required this.aiService});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1017),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'إعدادات المساعد الذكي',
              style: TextStyle(color: Color(0xFFF6F8FA), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.verified_user_rounded, color: Color(0xFFE8D29A)),
              title: const Text('المصادر المعتمدة', style: TextStyle(color: Color(0xFFF6F8FA), fontSize: 13, fontFamily: 'Cairo')),
              subtitle: const Text('القرآن الكريم، صحيح البخاري ومسلم، أمهات كتب الفقه المعتمدة', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo')),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              title: const Text('مسح كافة المحادثات', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'Cairo')),
              onTap: () {
                for (final conv in List.of(aiService.conversations)) {
                  aiService.deleteConversation(conv.id);
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

