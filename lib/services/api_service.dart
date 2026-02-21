// ignore_for_file: unused_field
import 'dart:typed_data';
import '../config/api_keys.dart';

// ─── CẤU HÌNH CHẾ ĐỘ GIẢ LẬP ──────────────────────────────────────
// Đặt useMockAI = false và thêm API keys thật vào lib/config/api_keys.dart
// để bật lời gọi API thật (Deepgram STT + OpenAI GPT-4o-mini)
class MockAIConfig {
  static const bool useMockAI = true;
}
// ──────────────────────────────────────────────────────────────────

// ─── DEEPGRAM SPEECH-TO-TEXT ──────────────────────────────────────
class DeepgramService {
  static const String _deepgramApiKey = ApiKeys.deepgramKey;

  /// Chuyển đổi âm thanh (WebM/Opus bytes) thành văn bản
  static Future<String?> transcribe(Uint8List audioBytes) async {
    if (MockAIConfig.useMockAI) {
      // Chế độ giả lập — trả về null để dùng văn bản thủ công
      return null;
    }

    /* Triển khai thật — bỏ comment khi có Deepgram API key
    try {
      final response = await http.post(
        Uri.parse('https://api.deepgram.com/v1/listen?model=nova-2&language=vi'),
        headers: {
          'Authorization': 'Token $_deepgramApiKey',
          'Content-Type': 'audio/webm',
        },
        body: audioBytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results']['channels'][0]['alternatives'][0]['transcript'];
      }
    } catch (e) {
      print('[Deepgram] Lỗi: $e');
    }
    */
    return null;
  }
}

// ─── OPENAI TASK FORMATTING ───────────────────────────────────────
class AIService {
  static const String _openaiApiKey = ApiKeys.openaiKey;

  /// Định dạng mô tả nhiệm vụ thô thành cấu trúc JSON có tổ chức
  static Future<Map<String, dynamic>?> formatTask(String description) async {
    if (MockAIConfig.useMockAI) {
      return _mockFormatTask(description);
    }

    /* Triển khai thật — bỏ comment khi có OpenAI API key
    const systemPrompt = '''
You are TaskHero AI, helping PKA students format task requests.

PKA Context:
 - Compact campus, 5-10 min between buildings
 - Canteen: Building 2, Level 2
 - Buildings have 5-8 levels, Hostel separate

Return ONLY valid JSON:
{
  "title": "short action title",
  "description": "clear task description",
  "category": "food|academic|errands|tech|social|marketplace",
  "urgency": "normal|urgent|emergency",
  "suggested_compensation": <number in VND>,
  "estimated_minutes": <number>,
  "pickup": {"building": "", "level": "", "landmark": ""},
  "delivery": {"building": "", "level": "", "landmark": ""}
}''';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_openaiApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': description},
          ],
          'temperature': 0.3,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('[OpenAI] Lỗi: $e');
    }
    */
    return null;
  }

  // Giả lập AI: phân tích từ khóa thay vì gọi OpenAI
  static Map<String, dynamic> _mockFormatTask(String input) {
    final lower = input.toLowerCase();
    String category = 'errands';
    if (lower.contains('ăn') || lower.contains('cơm') || lower.contains('food') ||
        lower.contains('mua') || lower.contains('trà sữa') || lower.contains('cafe')) {
      category = 'food';
    } else if (lower.contains('học') || lower.contains('bài') || lower.contains('code') ||
        lower.contains('debug') || lower.contains('toán') || lower.contains('tutor')) {
      category = 'academic';
    } else if (lower.contains('tech') || lower.contains('laptop') || lower.contains('cài')) {
      category = 'tech';
    } else if (lower.contains('thiết kế') || lower.contains('poster') || lower.contains('design')) {
      category = 'social';
    }

    final isUrgent = lower.contains('gấp') || lower.contains('urgent') || lower.contains('ngay');
    final words = input.trim().split(' ');
    final shortTitle = words.take(6).join(' ');

    return {
      'title': shortTitle.length > 3 ? shortTitle : input,
      'description': input,
      'category': category,
      'urgency': isUrgent ? 'urgent' : 'normal',
      'suggested_compensation': 15000,
      'estimated_minutes': 20,
      'pickup': {'building': 'PKA', 'level': 'Tầng 1', 'landmark': ''},
      'delivery': {'building': 'PKA', 'level': 'Tầng 1', 'landmark': ''},
    };
  }
}
