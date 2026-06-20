import 'package:flutter/material.dart';
import 'package:learnova/core/constants/app_assets.dart';

/// The type keys sent to the `use-perk` Edge Function.
abstract class PerkType {
  static const String owlHint = 'owl_hint';
  static const String slyFox = 'sly_fox';
}

/// Base class for all exam perks.
///
/// Each perk defines what question types it supports and carries display
/// metadata used by [PerkCardWidget].
abstract class ExamPerk {
  /// Unique identifier matching the key stored server-side.
  String get id;

  /// Human-readable name shown on the card.
  String get name;

  /// Short flavour-text description shown when the card is peeked.
  String get description;

  /// Material icon rendered on the card face (legacy/fallback).
  IconData get icon;

  /// Full playcard image asset path.
  String get imageAsset;

  /// Primary gradient colour for the card's glow / accent.
  Color get accentColor;

  /// Secondary gradient colour.
  Color get accentColorAlt;

  /// The `perk_type` value sent to the Edge Function.
  String get apiKey;

  /// Question types this perk may be cast on (e.g. `['mcq']`).
  List<String> get allowedQuestionTypes;

  /// Whether [questionType] is in [allowedQuestionTypes].
  bool canBeUsedOn(String questionType) =>
      allowedQuestionTypes.contains(questionType);
}

// ──────────────────────────────────────────────────
// Concrete perks
// ──────────────────────────────────────────────────

class OwlOfWisdomPerk extends ExamPerk {
  @override
  String get id => PerkType.owlHint;

  @override
  String get name => 'Owl of Wisdom';

  @override
  String get description =>
      'The ancient owl whispers a hint to guide your thinking.';

  @override
  IconData get icon => Icons.auto_awesome;

  @override
  String get imageAsset => AppAssets.perkOwl;

  @override
  Color get accentColor => const Color(0xFFFFD54F); // amber-gold
  @override
  Color get accentColorAlt => const Color(0xFFFFA726); // orange

  @override
  String get apiKey => PerkType.owlHint;

  @override
  List<String> get allowedQuestionTypes => const ['mcq'];
}

class SlyFoxPerk extends ExamPerk {
  @override
  String get id => PerkType.slyFox;

  @override
  String get name => 'Sly Fox 5000';

  @override
  String get description =>
      'The cunning fox sniffs out a wrong answer and strikes it out.';

  @override
  IconData get icon => Icons.remove_circle_outline;

  @override
  String get imageAsset => AppAssets.perkFox;

  @override
  Color get accentColor => const Color(0xFFEF5350); // red
  @override
  Color get accentColorAlt => const Color(0xFFFF7043); // deep-orange

  @override
  String get apiKey => PerkType.slyFox;

  @override
  List<String> get allowedQuestionTypes => const ['mcq'];
}
