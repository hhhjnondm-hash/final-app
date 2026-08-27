import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_models.dart';

class AiAssistantService extends ChangeNotifier {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal() {
    _loadKnowledgeBase();
    _initDefaultConversation();
  }

  bool _isLoadingKb = true;
  bool _isThinking = false;
  final List<Map<String, dynamic>> _knowledgeBase = [];
  final List<AiConversation> _conversations = [];
  String? _activeConversationId;

  bool get isThinking => _isThinking;
  bool get isLoadingKb => _isLoadingKb;
  List<AiConversation> get conversations => List.unmodifiable(_conversations);

  AiConversation? get activeConversation {
    if (_conversations.isEmpty) return null;
    return _conversations.firstWhere(
      (c) => c.id == _activeConversationId,
      orElse: () => _conversations.first,
    );
  }

  Future<void> _loadKnowledgeBase() async {
    try {
      final raw = await rootBundle.loadString('assets/data/islamic_questions.json');
      final data = json.decode(raw);
      if (data['questions'] is List) {
        _knowledgeBase.clear();
        for (final q in data['questions']) {
          _knowledgeBase.add(Map<String, dynamic>.from(q));
        }
      }
      _isLoadingKb = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading Islamic Questions KB: $e');
      _isLoadingKb = false;
    }
  }

  void _initDefaultConversation() {
    if (_conversations.isEmpty) {
      final newConv = AiConversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        title: 'محادثة جديدة',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [],
      );
      _conversations.insert(0, newConv);
      _activeConversationId = newConv.id;
    }
  }

  void createNewConversation() {
    final newConv = AiConversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      title: 'محادثة جديدة',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );
    _conversations.insert(0, newConv);
    _activeConversationId = newConv.id;
    notifyListeners();
  }

  void selectConversation(String id) {
    _activeConversationId = id;
    notifyListeners();
  }

  void deleteConversation(String id) {
    _conversations.removeWhere((c) => c.id == id);
    if (_conversations.isEmpty) {
      createNewConversation();
    } else {
      _activeConversationId = _conversations.first.id;
    }
    notifyListeners();
  }

  void toggleSaveMessage(String messageId) {
    final conv = activeConversation;
    if (conv == null) return;

    final updatedMessages = conv.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isSaved: !m.isSaved);
      }
      return m;
    }).toList();

    final idx = _conversations.indexWhere((c) => c.id == conv.id);
    if (idx != -1) {
      _conversations[idx] = conv.copyWith(messages: updatedMessages);
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String query,
    AiContextAttachment? contextAttachment,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    final conv = activeConversation;
    if (conv == null) return;

    final userMsg = AiMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      role: AiMessageRole.user,
      content: cleanQuery,
      timestamp: DateTime.now(),
      contextAttachment: contextAttachment,
    );

    var title = conv.title;
    if (conv.messages.isEmpty) {
      title = cleanQuery.length > 28 ? '${cleanQuery.substring(0, 28)}...' : cleanQuery;
    }

    final updatedWithUser = conv.copyWith(
      title: title,
      updatedAt: DateTime.now(),
      messages: [...conv.messages, userMsg],
    );

    final convIdx = _conversations.indexWhere((c) => c.id == conv.id);
    if (convIdx != -1) {
      _conversations[convIdx] = updatedWithUser;
    }

    _isThinking = true;
    notifyListeners();

    // Find best match in verified Islamic Knowledge Base
    await Future.delayed(const Duration(milliseconds: 900));

    final matchResult = _queryKnowledgeBase(cleanQuery, contextAttachment);

    final aiMsg = AiMessage(
      id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
      role: AiMessageRole.assistant,
      content: matchResult.answer,
      timestamp: DateTime.now(),
      sources: matchResult.sources,
      followUpQuestions: matchResult.followUps,
    );

    final updatedWithAi = updatedWithUser.copyWith(
      updatedAt: DateTime.now(),
      messages: [...updatedWithUser.messages, aiMsg],
    );

    if (convIdx != -1) {
      _conversations[convIdx] = updatedWithAi;
    }

    _isThinking = false;
    notifyListeners();
  }

  _QueryResult _queryKnowledgeBase(String query, AiContextAttachment? context) {
    if (context != null) {
      return _QueryResult(
        answer: 'بخصوص تدبر ودلالات سياق: "${context.title}":\n\n${context.content}\n\nيُرشدنا هذا النص القرآني/الحديثي المبارك إلى تعظيم شأن الإخلاص والتزام هدي النبي ﷺ والعمل بمقتضى ما جاء فيه من هدايات وأحكام.',
        sources: [
          AiSource(
            title: context.title,
            reference: context.source ?? 'القرآن الكريم / السنة النبوية',
          ),
          const AiSource(title: 'كتب التفسير المعتمدة', reference: 'تفسير ابن كثير / السعدي'),
        ],
        followUps: [
          'ما هي أهم الفوائد المستنبطة من هذه الآية؟',
          'ما هو سبب النزول إن وُجد؟',
          'كيف أطبق هذا التوجيه في حياتي اليومية؟',
        ],
      );
    }

    final qLower = query.toLowerCase();

    // Fuzzy search through verified Knowledge Base
    Map<String, dynamic>? bestMatch;
    int highestScore = 0;

    for (final item in _knowledgeBase) {
      final questionText = (item['question'] ?? '').toString().toLowerCase();
      final categoryText = (item['category'] ?? '').toString().toLowerCase();

      int score = 0;
      final keywords = qLower.split(RegExp(r'\s+'));
      for (final kw in keywords) {
        if (kw.length >= 3) {
          if (questionText.contains(kw)) score += 3;
          if (categoryText.contains(kw)) score += 1;
        }
      }

      if (score > highestScore) {
        highestScore = score;
        bestMatch = item;
      }
    }

    if (bestMatch != null && highestScore >= 2) {
      final answer = bestMatch['answer'] ?? '';
      final source = bestMatch['source'] ?? 'فقه الإسلام المعتمد';
      final category = bestMatch['category'] ?? 'العلوم الشرعية';

      return _QueryResult(
        answer: answer,
        sources: [
          AiSource(title: category, reference: source),
          const AiSource(title: 'المصادر الفقهية المعتمدة', reference: 'الإجماع وجمهور الفقهاء'),
        ],
        followUps: _generateRelatedQuestions(category),
      );
    }

    // Default polite authentic synthesis fallback
    return _QueryResult(
      answer: 'الحمد لله، والصلاة والسلام على رسول الله ﷺ.\n\nوفقاً للأصول الشرعية والقواعد الفقهية الكلية، فإن الإسلام دين يسر وسماحة يُراعي مقاصد الشريعة في حفظ الدين والنفس والعقل والعرض والمال.\n\nيُستحب للمسلم دائماً تحري السنة والرجوع لكبار العلماء المعتمدين فيما أشكل عليه من دقائق المسائل.',
      sources: [
        const AiSource(title: 'القواعد الفقهية الكلية', reference: 'الشريعة الإسلامية'),
        const AiSource(title: 'مقاصد الشريعة', reference: 'جمهور أهل العلم'),
      ],
      followUps: [
        'ما هي أركان وشروط صحة الصلاة؟',
        'ما هي السنن الرواتب المؤكدة؟',
        'كيف أحافظ على أذكار الصباح والمساء؟',
      ],
    );
  }

  List<String> _generateRelatedQuestions(String category) {
    if (category.contains('صلاة')) {
      return ['ما هي مبطلات الصلاة؟', 'ما حكم صلاة الاستخارة وكيفيتها؟', 'ما هي السنن الرواتب؟'];
    } else if (category.contains('صيام') || category.contains('رمضان')) {
      return ['ما هي مفسدات الصيام؟', 'ما فضل صيام الست من شوال؟', 'ما حكم القضاء والفدية؟'];
    } else if (category.contains('قرآن') || category.contains('تفسير')) {
      return ['ما فضل تلاوة سورة الكهف؟', 'ما هي السور المنجية؟', 'كيف أتدبر القرآن؟'];
    }
    return ['ما هي أحب الأعمال إلى الله؟', 'كيف أحقق الإخلاص في العبادة؟', 'ما هي أوقات إجابة الدعاء؟'];
  }
}

class _QueryResult {
  final String answer;
  final List<AiSource> sources;
  final List<String> followUps;

  const _QueryResult({
    required this.answer,
    required this.sources,
    required this.followUps,
  });
}
