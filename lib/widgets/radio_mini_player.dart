import 'package:flutter/material.dart';
import '../screens/radio_screen.dart';
import '../services/radio_service.dart';
import '../utils/design_system.dart';

class RadioMiniPlayer extends StatelessWidget {
  const RadioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final radioService = RadioService();

    return ListenableBuilder(
      listenable: radioService,
      builder: (context, _) {
        if (!radioService.isPlaying && !radioService.isBuffering) {
          return const SizedBox.shrink();
        }

        final station = radioService.currentStation;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: DesignSystem.bgDarkest.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
            border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: DesignSystem.gold.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RadioScreen()),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: DesignSystem.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: station.photoUrl != null
                        ? Image.asset(
                            station.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.radio_rounded, color: DesignSystem.bgDarkest, size: 20),
                          )
                        : const Icon(Icons.radio_rounded, color: DesignSystem.bgDarkest, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(color: DesignSystem.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.circle, color: Color(0xFF38B982), size: 6),
                          const SizedBox(width: 4),
                          Text(
                            station.origin,
                            style: const TextStyle(color: DesignSystem.goldLight, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    radioService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: DesignSystem.goldLight,
                    size: 26,
                  ),
                  onPressed: () => radioService.togglePlayPause(),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  onPressed: () => radioService.pause(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
