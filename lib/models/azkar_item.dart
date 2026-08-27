class AzkarItem {
  final String title;
  final String text;
  final int repetitions;
  final String repetitionText;

  const AzkarItem({
    required this.title,
    required this.text,
    required this.repetitions,
    this.repetitionText = 'مرة',
  });
}