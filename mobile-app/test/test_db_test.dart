import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learnova/core/services/supabase/supabase_config.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Check DB data', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    await SupabaseConfig.initialize();

    try {
      final qs = await SupabaseConfig.client.from('level_assessment_questions').select('id, assessment_id, difficulty, order_index');
      print('LEVEL EXAM Qs: $qs');
      final levels = await SupabaseConfig.client.from('level_assessments').select('id, level_id');
      print('LEVEL ASSESSMENTS: $levels');
    } catch (e) {
      print('Error: $e');
    }
  });
}
