import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/features/island_map/domain/entities/topic.dart';
import 'package:learnova/features/island_map/domain/entities/topic_resource.dart';
import 'package:learnova/features/island_map/presentation/providers/island_map_providers.dart';
import 'package:learnova/features/content/domain/entities/content_item_payload.dart';
import 'package:learnova/features/content/presentation/screens/content_video_player.dart';
import 'package:learnova/features/content/presentation/screens/content_audio_player.dart';
import 'package:learnova/features/content/presentation/screens/content_document_reader.dart';

class ModuleTopicsScreen extends ConsumerWidget {
  final String moduleId;
  final String moduleTitle;

  const ModuleTopicsScreen({
    super.key,
    required this.moduleId,
    required this.moduleTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final Size size = MediaQuery.of(context).size;
    final topicsAsyncValue = ref.watch(moduleTopicsProvider(moduleId));

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackground(),
          ),

          // Fixed Top Wave
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.mapTop,
                width: size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          moduleTitle,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: topicsAsyncValue.when(
                    data: (topics) => _buildTopicsList(context, colors, topics),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Failed to load topics: $e',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsList(BuildContext context, AppColors colors, List<Topic> topics) {
    if (topics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No topics available for this module.',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return _buildTopicCard(context, colors, topic);
      },
    );
  }

  Widget _buildTopicCard(BuildContext context, AppColors colors, Topic topic) {
    return Card(
      color: colors.cardBackground,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (topic.resources.isEmpty)
              Text(
                'No resources found matching your learning style.',
                style: TextStyle(color: colors.textSecondary, fontStyle: FontStyle.italic),
              )
            else
              ...topic.resources.map((res) => _buildResourceTile(context, colors, res)),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTile(BuildContext context, AppColors colors, TopicResource resource) {
    IconData icon;
    String route;
    
    switch (resource.formatType) {
      case 'Visual':
        icon = Icons.play_circle_fill;
        route = AppRoutePaths.contentVideoPlayer;
        break;
      case 'Auditory':
        icon = Icons.audiotrack;
        route = AppRoutePaths.contentAudioPlayer;
        break;
      case 'Textual':
      default:
        icon = Icons.description;
        route = AppRoutePaths.contentDocumentReader;
        break;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.buttonBackground.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.buttonBackground),
      ),
      title: Text(
        '${resource.formatType} Lesson',
        style: TextStyle(color: colors.textPrimary),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colors.textSecondary),
      onTap: () {
        final itemPayload = ContentItemPayload(
          id: resource.id,
          title: '${resource.formatType} Lesson',
          contentType: resource.formatType,
          meta: '10 mins', // Default meta for now
          mediaUrl: resource.resourceUrl,
        );

        Widget playerScreen;
        switch (resource.formatType) {
          case 'Visual':
            playerScreen = VideoPlayerPlaceholderScreen(item: itemPayload);
            break;
          case 'Auditory':
            playerScreen = AudioStudyPlayerScreen(item: itemPayload);
            break;
          case 'Textual':
          default:
            playerScreen = DocumentReaderPlaceholderScreen(item: itemPayload);
            break;
        }

        AppRouter.push(
          context,
          playerScreen,
          routeName: route,
        );
      },
    );
  }
}
