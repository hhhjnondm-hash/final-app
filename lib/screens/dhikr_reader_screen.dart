import 'package:flutter/material.dart';
import '../data/all_azkar_data.dart';
import '../models/azkar_models.dart';
import '../services/azkar_service.dart';
import '../utils/design_system.dart';
import '../widgets/dhikr_card.dart';

class DhikrReaderScreen extends StatefulWidget {
  final AzkarCategoryMeta category;

  const DhikrReaderScreen({
    super.key,
    required this.category,
  });

  @override
  State<DhikrReaderScreen> createState() => _DhikrReaderScreenState();
}

class _DhikrReaderScreenState extends State<DhikrReaderScreen> {
  final AzkarService _azkarService = AzkarService();
  bool _isFocusMode = false;
  int _focusIndex = 0;

  @override
  void initState() {
    super.initState();
    _azkarService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _azkarService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final azkarList = AllAzkarData.getAzkarForCategory(widget.category.type);
    final completedCount = azkarList.where((d) => _azkarService.isCompleted(d.id)).length;
    final totalCount = azkarList.length;
    final progress = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    if (_isFocusMode) {
      return _buildFocusMode(azkarList);
    }

    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      appBar: AppBar(
        backgroundColor: DesignSystem.bgDarkest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: DesignSystem.goldLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.titleArabic,
          style: const TextStyle(
            color: DesignSystem.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded, color: DesignSystem.goldLight),
            tooltip: 'وضع التركيز',
            onPressed: () {
              setState(() {
                _isFocusMode = true;
                _focusIndex = 0;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.category.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
                border: Border.all(color: widget.category.accentColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إنجاز ${widget.category.titleArabic}',
                        style: const TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$completedCount من $totalCount أذكار',
                        style: TextStyle(
                          color: widget.category.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.category.accentColor),
                    ),
                  ),
                ],
              ),
            ),

            // Azkar List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(DesignSystem.spacingL),
                physics: const BouncingScrollPhysics(),
                itemCount: azkarList.length,
                itemBuilder: (context, index) {
                  final dhikr = azkarList[index];
                  return DhikrCard(
                    dhikr: dhikr,
                    index: index,
                    onCountChanged: () => setState(() {}),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusMode(List<DhikrItem> azkarList) {
    if (_focusIndex >= azkarList.length) _focusIndex = 0;
    final dhikr = azkarList[_focusIndex];
    final count = _azkarService.getRepetition(dhikr.id);
    final isCompleted = count >= dhikr.targetRepetitions;

    return Scaffold(
      backgroundColor: const Color(0xFF020710),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar: Exit Focus & Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: DesignSystem.textMuted),
                    onPressed: () => setState(() => _isFocusMode = false),
                  ),
                  Text(
                    '${_focusIndex + 1} / ${azkarList.length}',
                    style: const TextStyle(
                      color: DesignSystem.goldLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _azkarService.isFavorite(dhikr.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _azkarService.isFavorite(dhikr.id) ? const Color(0xFFE11D48) : DesignSystem.textMuted,
                    ),
                    onPressed: () => _azkarService.toggleFavorite(dhikr.id),
                  ),
                ],
              ),

              // Central Big Dhikr View
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Text(
                      dhikr.title,
                      style: const TextStyle(
                        color: DesignSystem.goldLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      dhikr.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DesignSystem.textWhite,
                        fontSize: 22,
                        height: 2.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Big Touch Trigger & Next/Prev Controls
              Column(
                children: [
                  // Massive Tap Button to Increment Count
                  InkWell(
                    onTap: () {
                      _azkarService.incrementRepetition(dhikr);
                      if (_azkarService.isCompleted(dhikr.id) && _focusIndex < azkarList.length - 1) {
                        setState(() => _focusIndex++);
                      }
                    },
                    borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCompleted ? null : DesignSystem.goldGradient,
                        color: isCompleted ? const Color(0xFF19B88A) : null,
                        boxShadow: isCompleted
                            ? [BoxShadow(color: const Color(0xFF19B88A).withValues(alpha: 0.4), blurRadius: 30)]
                            : DesignSystem.goldGlow,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$count',
                              style: TextStyle(
                                color: isCompleted ? Colors.white : DesignSystem.bgDarkest,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'من ${dhikr.targetRepetitions}',
                              style: TextStyle(
                                color: isCompleted ? Colors.white70 : DesignSystem.bgDarkest.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Next / Prev Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _focusIndex > 0 ? () => setState(() => _focusIndex--) : null,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('السابق'),
                      ),
                      TextButton.icon(
                        onPressed: _focusIndex < azkarList.length - 1 ? () => setState(() => _focusIndex++) : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('التالي'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
