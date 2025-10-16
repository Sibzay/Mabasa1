import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authStateProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) async {
    try {
      final me = await AuthService().me();
      return me;
    } catch (_) {
      return null;
    }
  },
);
