import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';

class AppConfig {
  const AppConfig({
    required this.discoveryMinAge,
    required this.discoveryMaxAge,
  });

  final int discoveryMinAge;
  final int discoveryMaxAge;
}

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final dio = ref.watch(dioClientProvider);

  try {
    final response = await dio.get<Map<String, dynamic>>('/public/config');
    final data = response.data;
    if (data != null) {
      return AppConfig(
        discoveryMinAge: data['discoveryMinAge'] as int? ?? 60,
        discoveryMaxAge: data['discoveryMaxAge'] as int? ?? 120,
      );
    }
  } catch (e) {
    // Fallback on error
  }

  // Defaults
  return const AppConfig(discoveryMinAge: 60, discoveryMaxAge: 120);
});
