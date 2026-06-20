import 'package:learnova/features/auth/data/models/avatar_option_model.dart';

class AvatarLocalDataSource {
  const AvatarLocalDataSource();

  List<AvatarOptionModel> getAvatarOptions() {
    return const [
      AvatarOptionModel(fileName: 'avatar1.svg'),
      AvatarOptionModel(fileName: 'avatar2.svg'),
      AvatarOptionModel(fileName: 'avatar3.svg'),
      AvatarOptionModel(fileName: 'avatar4.svg'),
      AvatarOptionModel(fileName: 'avatar5.svg'),
      AvatarOptionModel(fileName: 'avatar6.svg'),
      AvatarOptionModel(fileName: 'avatar7.svg'),
      AvatarOptionModel(fileName: 'avatar8.svg'),
    ];
  }
}
