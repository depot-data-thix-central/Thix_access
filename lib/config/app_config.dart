import 'env.dart';

class AppConfig {
  const AppConfig({required this.environment, required this.appName});

  final String environment;
  final String appName;

  static const current = AppConfig(
    environment: Env.environment,
    appName: 'THIX ACCESS',
  );
}
