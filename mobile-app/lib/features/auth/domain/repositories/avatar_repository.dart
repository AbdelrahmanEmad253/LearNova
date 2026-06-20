import 'package:learnova/features/auth/domain/entities/avatar_option.dart';

abstract class AvatarRepository {
  List<AvatarOption> getAvatarOptions();
}
