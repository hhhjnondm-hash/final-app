import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../data/morning_azkar_data.dart';
import '../models/azkar_item.dart';

class MorningAzkarScreen extends StatefulWidget {
  const MorningAzkarScreen({super.key});

  @override
  State<MorningAzkarScreen> createState() => _MorningAzkarScreenState();
}

class _MorningAzkarScreenState extends State<MorningAzkarScreen> {
  int currentIndex = 0;
  int currentRepetition = 0;
  bool showCelebration = false;

  @override
  Widget build(BuildContext context) {
    if (showCelebration) {
      return _buildCelebrationScreen();
    }

    final azkarItem = morningAzkarData[currentIndex];
    final progress = (currentRepetition / azkarItem.repetitions).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: DesignSystem.radialGlowBackground(),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Progress Bar
              _buildProgressBar(progress, azkarItem),

              // Main Content
              Expanded(
                child: _buildAzkarCard(azkarItem),
              ),

              // Navigation Buttons
              _buildNavigationButtons(azkarItem),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: DesignSystem.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: DesignSystem.spacingM),
          const Text(
            'أذكار الصباح',
            style: TextStyle(
              color: DesignSystem.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, AzkarItem azkarItem) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الذكر رقم ${currentIndex + 1}',
                style: const TextStyle(
                  color: DesignSystem.textMuted,
                  fontSize: 14,
                ),
              ),
              Text(
                'من ${morningAzkarData.length}',
                style: const TextStyle(
                  color: DesignSystem.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.gold),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingS),
          Text(
            'التكرار: $currentRepetition / ${azkarItem.repetitions}',
            style: const TextStyle(
              color: DesignSystem.gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAzkarCard(AzkarItem azkarItem) {
    return Padding(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      child: Container(
        decoration: DesignSystem.glassCard(),
        child: Padding(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          child: Column(
            children: [
              // Title
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacingM,
                  vertical: DesignSystem.spacingS,
                ),
                decoration: BoxDecoration(
                  gradient: DesignSystem.goldGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                ),
                child: Text(
                  azkarItem.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: DesignSystem.spacingL),
              
              // Azkar Text
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    azkarItem.text,
                    style: const TextStyle(
                      color: DesignSystem.white,
                      fontSize: 22,
                      height: 2.0,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              
              // Repetition Info
              const SizedBox(height: DesignSystem.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacingM,
                  vertical: DesignSystem.spacingS,
                ),
                decoration: BoxDecoration(
                  color: DesignSystem.violet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                  border: Border.all(
                    color: DesignSystem.violet.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  azkarItem.repetitionText,
                  style: const TextStyle(
                    color: DesignSystem.violet,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(AzkarItem azkarItem) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      child: Row(
        children: [
          // Previous Button
          Expanded(
            child: Container(
              decoration: currentIndex > 0
                  ? DesignSystem.glassButton()
                  : BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                    ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: DesignSystem.white),
                onPressed: currentIndex > 0
                    ? () {
                        setState(() {
                          currentIndex--;
                          currentRepetition = 0;
                        });
                      }
                    : null,
              ),
            ),
          ),
          
          const SizedBox(width: DesignSystem.spacingM),
          
          // Count Button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (currentRepetition < azkarItem.repetitions) {
                    currentRepetition++;
                  } else {
                    // Move to next azkar
                    if (currentIndex < morningAzkarData.length - 1) {
                      currentIndex++;
                      currentRepetition = 0;
                    } else {
                      // Show celebration
                      showCelebration = true;
                    }
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: DesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                  boxShadow: DesignSystem.blueGlow,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: DesignSystem.spacingM),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: DesignSystem.spacingS),
                      Text(
                        currentRepetition < azkarItem.repetitions
                            ? 'إكمال'
                            : 'التالي',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: DesignSystem.spacingM),
          
          // Next Button
          Expanded(
            child: Container(
              decoration: currentIndex < morningAzkarData.length - 1
                  ? DesignSystem.glassButton()
                  : BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                    ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: DesignSystem.white),
                onPressed: currentIndex < morningAzkarData.length - 1
                    ? () {
                        setState(() {
                          currentIndex++;
                          currentRepetition = 0;
                        });
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationScreen() {
    return Scaffold(
      body: Container(
        decoration: DesignSystem.radialGlowBackground(),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Celebration Icon
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: DesignSystem.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: DesignSystem.goldGlow,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
                const SizedBox(height: DesignSystem.spacingXL),
                
                // Celebration Text
                const Text(
                  'ما شاء الله!',
                  style: TextStyle(
                    color: DesignSystem.gold,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignSystem.spacingM),
                const Text(
                  'أتممت أذكار الصباح',
                  style: TextStyle(
                    color: DesignSystem.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignSystem.spacingS),
                const Text(
                  'بارك الله فيك',
                  style: TextStyle(
                    color: DesignSystem.textMuted,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: DesignSystem.spacing2XL),
                
                // Restart Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIndex = 0;
                      currentRepetition = 0;
                      showCelebration = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingXL,
                      vertical: DesignSystem.spacingM,
                    ),
                    decoration: BoxDecoration(
                      gradient: DesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      boxShadow: DesignSystem.blueGlow,
                    ),
                    child: const Text(
                      'البداية من جديد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignSystem.spacingL),
                
                // Back Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingXL,
                      vertical: DesignSystem.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Text(
                      'العودة',
                      style: TextStyle(
                        color: DesignSystem.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}