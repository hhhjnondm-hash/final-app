import 'package:flutter/material.dart';

enum AiMessageRole {
  user,
  assistant,
  system,
}

enum AiContentType {
  general,
  quranVerse,
  hadith,
  dua,
  prayerRule,
}

class AiSource {
  final String title;
  final String reference;
  final String? type;

  const AiSource({
    required this.title,
    required this.reference,
    this.type,
  });

  factory AiSource.fromJson(Map<String, dynamic> json) {
    return AiSource(
      title: json['title'] ?? '',
      reference: json['reference'] ?? '',
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'reference': reference,
    'type': type,
  };
}

class AiContextAttachment {
  final String title;
  final String content;
  final String? source;
  final int? surahNumber;
  final int? ayahNumber;

  const AiContextAttachment({
    required this.title,
    required this.content,
    this.source,
    this.surahNumber,
    this.ayahNumber,
  });
}

class AiMessage {
  final String id;
  final AiMessageRole role;
  final String content;
  final DateTime timestamp;
  final List<AiSource> sources;
  final List<String> followUpQuestions;
  final AiContextAttachment? contextAttachment;
  final bool isSaved;

  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.sources = const [],
    this.followUpQuestions = const [],
    this.contextAttachment,
    this.isSaved = false,
  });

  AiMessage copyWith({
    bool? isSaved,
    String? content,
  }) {
    return AiMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      sources: sources,
      followUpQuestions: followUpQuestions,
      contextAttachment: contextAttachment,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class AiConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AiMessage> messages;

  const AiConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  AiConversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<AiMessage>? messages,
  }) {
    return AiConversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
