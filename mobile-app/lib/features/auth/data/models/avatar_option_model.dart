import 'package:learnova/features/auth/domain/entities/avatar_option.dart';

class AvatarOptionModel {
  final String fileName;

  const AvatarOptionModel({required this.fileName});

  AvatarOption toEntity() {
    return AvatarOption(fileName: fileName);
  }
}
