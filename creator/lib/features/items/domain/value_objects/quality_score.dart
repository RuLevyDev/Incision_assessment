import 'item_draft.dart';

class QualityScore {
  QualityScore({
    required this.value,
    required this.band,
  }) : assert(value >= 0 && value <= 100, 'Quality score must be within 0-100');

  final int value;
  final QualityBand band;
}

enum QualityBand {
  poor,
  fair,
  good,
  excellent;

  static const int minimumApprovalScore = 90;
}

class QualityScoreCalculator {
  static const int _baseScore = 40;
  static const int _titleBonus = 20;
  static const int _descriptionBonus = 15;
  static const int _categoryBonus = 10;
  static const int _oneTagBonus = 10;
  static const int _twoTagBonus = 5;

  static QualityScore calculate(ItemDraft draft) {
    var score = _baseScore;

    if (draft.title.trim().length > 12) {
      score += _titleBonus;
    }
    if (draft.description.trim().length > 60) {
      score += _descriptionBonus;
    }
    if (draft.category.trim().isNotEmpty) {
      score += _categoryBonus;
    }
    if (draft.tags.isNotEmpty) {
      score += _oneTagBonus;
      if (draft.tags.length >= 2) {
        score += _twoTagBonus;
      }
    }

    final band = bandFor(score);
    return QualityScore(value: score, band: band);
  }

  static QualityBand bandFor(int score) {
    if (score >= 90) {
      return QualityBand.excellent;
    }
    if (score >= 75) {
      return QualityBand.good;
    }
    if (score >= 60) {
      return QualityBand.fair;
    }
    return QualityBand.poor;
  }
}
