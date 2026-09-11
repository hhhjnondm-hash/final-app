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
  List<Map<String, dynamic>> get allQuestions => List.unmodifiable(_knowledgeBase);

  AiConversation? get activeConversation {
    if (_conversations.isEmpty) return null;
    return _conversations.firstWhere(
      (c) => c.id == _activeConversationId,
      orElse: () => _conversations.first,
    );
  }

  /// Get list of unique categories
  List<String> get categories {
    final set = <String>{};
    for (final item in _knowledgeBase) {
      final cat = item['category']?.toString();
      if (cat != null && cat.isNotEmpty) set.add(cat);
    }
    return set.toList();
  }

  /// Get questions by category
  List<Map<String, dynamic>> getQuestionsByCategory(String category) {
    if (category == 'الكل' || category.isEmpty) {
      return _knowledgeBase;
    }
    return _knowledgeBase.where((q) => q['category'] == category).toList();
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

  void rateMessage(String messageId, bool isLike) {
    final conv = activeConversation;
    if (conv == null) return;

    final updatedMessages = conv.messages.map((m) {
      if (m.id == messageId) {
        final currentVal = m.isLiked;
        final newVal = (currentVal == isLike) ? null : isLike;
        return m.copyWith(isLiked: newVal);
      }
      return m;
    }).toList();

    final idx = _conversations.indexWhere((c) => c.id == conv.id);
    if (idx != -1) {
      _conversations[idx] = conv.copyWith(messages: updatedMessages);
      notifyListeners();
    }
  }

  /// Arabic text normalizer for accurate natural language matching
  String _normalizeArabic(String text) {
    var s = text.trim().toLowerCase();
    // Remove Tashkeel / Harakat
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // Normalize Alifs
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    // Normalize Yaa
    s = s.replaceAll('ى', 'ي');
    // Normalize Taa Marbuta
    s = s.replaceAll('ة', 'ه');
    // Remove punctuation
    s = s.replaceAll(RegExp(r'[؟?!.,;:_"\(\)\[\]«»\-–]'), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
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

    // Natural responsive delay
    await Future.delayed(const Duration(milliseconds: 600));

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
        answer: 'بخصوص تدبر ودلالات سياق: "${context.title}":\n\n${context.content}\n\nيُرشدنا هذا النص القرآني/الحديثي المبارك إلى تعظيم شأن الإخلاص والتزام هدي النبي ﷺ والعمل بمقتضى ما جاء فيه من هدايات وأحكام فقهية وتربوية.',
        sources: [
          AiSource(
            title: context.title,
            reference: context.source ?? 'القرآن الكريم / السنة النبوية',
          ),
          const AiSource(title: 'كتب التفسير المعتمدة', reference: 'تفسير ابن كثير / السعدي / القرطبي'),
        ],
        followUps: [
          'ما هي أهم الفوائد المستنبطة من هذه الآية؟',
          'ما هو سبب النزول إن وُجد؟',
          'كيف أطبق هذا التوجيه في حياتي اليومية؟',
        ],
      );
    }

    final qNorm = _normalizeArabic(query);
    final qWords = qNorm.split(' ').where((w) => w.length >= 2).toList();

    // 1. Exact or High-Score Match
    Map<String, dynamic>? bestMatch;
    double highestScore = 0.0;

    for (final item in _knowledgeBase) {
      final qText = _normalizeArabic((item['question'] ?? '').toString());
      final catText = _normalizeArabic((item['category'] ?? '').toString());
      final ansText = _normalizeArabic((item['answer'] ?? '').toString());

      if (qText == qNorm) {
        highestScore = 100.0;
        bestMatch = item;
        break;
      }

      double score = 0.0;

      // Word matching
      for (final w in qWords) {
        if (qText.contains(w)) {
          score += 4.0;
        } else if (catText.contains(w)) {
          score += 2.0;
        } else if (ansText.contains(w)) {
          score += 1.0;
        }
      }

      if (score > highestScore) {
        highestScore = score;
        bestMatch = item;
      }
    }

    if (bestMatch != null && highestScore >= 3.0) {
      final answer = bestMatch['answer'] ?? '';
      final source = bestMatch['source'] ?? 'فقه الإسلام وأصول الشريعة';
      final category = bestMatch['category'] ?? 'العلوم الشرعية';

      return _QueryResult(
        answer: answer,
        sources: [
          AiSource(title: category, reference: source),
          const AiSource(title: 'المصادر المعتمدة', reference: 'القرآن الكريم وصحيح السنة وإجماع الفقهاء'),
        ],
        followUps: _generateRelatedQuestions(category, query),
      );
    }

    // 2. Fallback contextual synthesis for uncataloged queries
    return _QueryResult(
      answer: 'الحمد لله، والصلاة والسلام على رسول الله ﷺ.\n\nبناءً على القواعد الكلية للشريعة الإسلامية وأصول الفقه المعتمدة:\n• الإسلام دين يسر وسماحة مبني على جلب المصالح ودرء المفاسد.\n• يُستحب للمسلم دائماً استحضار النية الصالحة والرجوع لأهل العلم الموثوقين فيما يشكل عليه من تفاصيل المسائل.\n\nقال تعالى: ﴿فَاسْأَلُوا أَهْلَ الذِّكْرِ إِن كُنتُمْ لَا تَعْلَمُونَ﴾ [النحل: 43].',
      sources: [
        const AiSource(title: 'القواعد الفقهية الكلية', reference: 'أصول الفقه الإسلامي'),
        const AiSource(title: 'مقاصد الشريعة', reference: 'جمهور أهل العلم'),
      ],
      followUps: [
        'ما هي شروط صحة الصلاة وأركانها؟',
        'ما هي السنن الرواتب المؤكدة؟',
        'ما هي أهم أذكار الصباح والمساء؟',
      ],
    );
  }

  List<String> _generateRelatedQuestions(String category, String query) {
    if (category.contains('صلاة') || query.contains('صلاة')) {
      return ['ما هي أركان الصلاة الأربعة عشر؟', 'ما هي مبطلات الصلاة؟', 'كيفية صلاة الاستخارة وما هو دعاؤها؟'];
    } else if (category.contains('صيام') || category.contains('رمضان')) {
      return ['ما هي مفسدات الصيام في نهار رمضان؟', 'ما فضل صيام الست من شوال؟', 'كيف تُحسب زكاة المال؟'];
    } else if (category.contains('قرآن') || category.contains('تفسير')) {
      return ['ما هي فضائل سورة الفاتحة؟', 'ما هو فضل آية الكرسي؟', 'ما هو فضل سورة الكهف يوم الجمعة؟'];
    } else if (category.contains('عقيدة') || category.contains('إيمان')) {
      return ['ما هي أركان الإيمان الستة؟', 'ما هي شروط التوبة الصادقة المقبولة؟', 'ما معنى شهادة أن لا إله إلا الله؟'];
    } else if (category.contains('أذكار') || category.contains('دعاء')) {
      return ['ما هي أهم أذكار الصباح والمساء؟', 'ما هي الأوقات التي يُستجاب فيها الدعاء؟', 'ما هي شروط الرقية الشرعية الصحيحة؟'];
    }
    return ['ما حكم بر الوالدين وحقوقهما؟', 'ما هي كبائر الذنوب في الإسلام؟', 'ما هي آداب النوم والاستيقاظ؟'];
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
