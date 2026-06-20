class WeeklyChallengeModel {
  final String id;
  final String moduleId;
  final String title;
  final String? description;
  final bool isActive;
  final int xpRewardEasy;
  final int xpRewardMid;
  final int xpRewardHard;
  final DateTime? availableFrom;
  final DateTime? availableUntil;

  const WeeklyChallengeModel({
    required this.id,
    required this.moduleId,
    required this.title,
    this.description,
    required this.isActive,
    required this.xpRewardEasy,
    required this.xpRewardMid,
    required this.xpRewardHard,
    this.availableFrom,
    this.availableUntil,
  });

  factory WeeklyChallengeModel.fromJson(Map<String, dynamic> json) {
    return WeeklyChallengeModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      xpRewardEasy: json['xp_reward_easy'] as int? ?? 20,
      xpRewardMid: json['xp_reward_mid'] as int? ?? 50,
      xpRewardHard: json['xp_reward_hard'] as int? ?? 100,
      availableFrom: json['available_from'] != null ? DateTime.parse(json['available_from']) : null,
      availableUntil: json['available_until'] != null ? DateTime.parse(json['available_until']) : null,
    );
  }
}
