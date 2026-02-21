/// ─── MẪU API KEYS ────────────────────────────────────────────────
/// Sao chép file này thành `api_keys.dart` trong cùng thư mục và
/// điền các key thật của bạn vào. File thật đã được gitignore.
///
///   cp lib/config/api_keys.template.dart lib/config/api_keys.dart
///
class ApiKeys {
  static const openaiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const deepgramKey = 'YOUR_DEEPGRAM_API_KEY_HERE';
  static const firebaseProject = 'YOUR_FIREBASE_PROJECT_ID';
  static const storageBucket = '$firebaseProject.firebasestorage.app';
}
