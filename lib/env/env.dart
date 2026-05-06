import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static final String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'ONESIGNAL_APP_ID')
  static final String onesignalAppId = _Env.onesignalAppId;

  @EnviedField(varName: 'ONESIGNAL_REST_API_KEY')
  static final String onesignalRestApiKey = _Env.onesignalRestApiKey;

  @EnviedField(varName: 'GROQ_API_KEY')
  static final String groqApiKey = _Env.groqApiKey;
}
