import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learnova/core/services/supabase/supabase_config.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Check DB data', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    await SupabaseConfig.initialize();

    try {
      final levels = await SupabaseConfig.client.from('levels').select();
      print('LEVELS: $levels');
      final courses = await SupabaseConfig.client.from('courses').select();
      print('COURSES: $courses');
    } catch (e) {
      print('Error: $e');
    }
  });
}
