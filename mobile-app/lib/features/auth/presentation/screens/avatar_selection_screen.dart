import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/features/auth/domain/entities/avatar_option.dart';
import 'package:learnova/features/auth/presentation/providers/avatar_providers.dart';
import 'package:learnova/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:learnova/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:learnova/core/constants/app_assets.dart';

class AvatarSelectionScreen extends ConsumerStatefulWidget {
  final bool isEditingProfile;

  const AvatarSelectionScreen({super.key, this.isEditingProfile = false});

  @override
  ConsumerState<AvatarSelectionScreen> createState() =>
      _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends ConsumerState<AvatarSelectionScreen> {
  int? _selectedAvatarIndex;
  Uint8List? _customImageBytes;
  String? _customImageExtension;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatarIndex = 0;
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final ext = pickedFile.path.split('.').last.toLowerCase();
        setState(() {
          _customImageBytes = bytes;
          _customImageExtension = (ext == 'png' || ext == 'webp') ? ext : 'jpg';
          _selectedAvatarIndex = null; // Deselect prefab
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    }
  }

  Future<void> _saveAvatar(List<AvatarOption> avatars) async {
    setState(() => _isUploading = true);
    try {
      final service = ref.read(userDataServiceProvider);

      if (_customImageBytes != null && _customImageExtension != null) {
        // Upload custom image
        final url = await service.uploadAndSaveAvatar(
          _customImageBytes!,
          _customImageExtension!,
        );
        if (url == null) {
          throw Exception('Failed to upload avatar.');
        }
      } else if (_selectedAvatarIndex != null) {
        // Save prefab avatar filename
        final fileName = avatars[_selectedAvatarIndex!].fileName;
        await service.savePrefabAvatar(fileName);
      }

      // Invalidate the user data cache so it refreshes
      ref.invalidate(currentUserDataProvider);

      if (mounted) {
        if (widget.isEditingProfile) {
          AppRouter.pop(context);
        } else {
          AppRouter.pushReplacement(
            context,
            const WelcomeScreen(),
            routeName: AppRoutePaths.onboardingWelcome,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving avatar: $e'),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<AvatarOption> avatars = ref.watch(avatarOptionsProvider);
    final colors = AppColors.of(context);
    return SpaceScaffold(
      topWavePaths: const [AppAssets.authTop],
      bottomWavePaths: const [AppAssets.authBottomHigh],
      topWavesColor: colors.isDark ? null : const Color(0xFF03478E),
      bottomWavesColor: colors.isDark ? null : const Color(0xFF03478E),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.textPrimary, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => AppRouter.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set Avatar',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your Prefab or upload a photo',
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 24),
            // Large preview
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 100,
                  backgroundColor:
                      ColorManager.softBlueTint.withValues(alpha: 0.8),
                  child: CircleAvatar(
                    radius: 100,
                    backgroundColor: ColorManager.transparent,
                    child: _buildLargePreview(avatars),
                  ),
                ),
                GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Container(
                    decoration: BoxDecoration(
                        color: colors.cardBackground,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: ColorManager.secondary, width: 2)),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.camera_alt,
                          color: ColorManager.secondary, size: 24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Grid of avatar options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: avatars.length + 1, // +1 for gallery button
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    // First tile: gallery upload button
                    if (index == 0) {
                      final isCustomSelected = _customImageBytes != null;
                      return GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isCustomSelected
                                ? Border.all(
                                    color: ColorManager.primary, width: 3)
                                : Border.all(
                                    color: colors.textSecondary.withValues(alpha: 0.3),
                                    width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: isCustomSelected
                                ? ColorManager.softBlueTint.withValues(alpha: 0.8)
                                : colors.cardBackground.withValues(alpha: 0.5),
                            child: isCustomSelected && _customImageBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _customImageBytes!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: colors.textSecondary,
                                    size: 28,
                                  ),
                          ),
                        ),
                      );
                    }

                    // Prefab avatar tiles (shifted by 1)
                    final avatarIndex = index - 1;
                    final isSelected = _selectedAvatarIndex == avatarIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatarIndex = avatarIndex;
                          _customImageBytes = null; // Clear custom
                          _customImageExtension = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: ColorManager.primary, width: 3)
                              : null,
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              ColorManager.softBlueTint.withValues(alpha: 0.8),
                          child: SvgPicture.asset(
                            AppAssets.avatarByFileName(avatars[avatarIndex].fileName),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
              child: _isUploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ColorManager.primary,
                      ),
                    )
                  : CustomButton(
                      text: 'Save & Continue',
                      backgroundColor: colors.buttonBackground,
                      onPressed: () => _saveAvatar(avatars),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget? _buildLargePreview(List<AvatarOption> avatars) {
    if (_customImageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _customImageBytes!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }
    if (_selectedAvatarIndex != null && _selectedAvatarIndex! < avatars.length) {
      return SvgPicture.asset(
        AppAssets.avatarByFileName(avatars[_selectedAvatarIndex!].fileName),
      );
    }
    return null;
  }
}
