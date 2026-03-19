// ignore_for_file: unused_field
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

// ─── CẤU HÌNH CHẾ ĐỘ GIẢ LẬP ──────────────────────────────────────
// Đặt useMockAI = false và thêm API keys thật vào lib/config/api_keys.dart
// để bật lời gọi API thật (Deepgram STT + OpenAI GPT-4o-mini)
class MockAIConfig {
  static const bool useMockAI = false;
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
      } else {
        print('[Deepgram] HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[Deepgram] Lỗi: $e');
    }
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
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_openaiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'system_instruction': {
            'parts': [{'text': systemPrompt}]
          },
          'contents': [
            {'parts': [{'text': description}]}
          ],
          'generationConfig': {
             'temperature': 0.3,
             'maxOutputTokens': 400,
             'responseMimeType': 'application/json'
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'] as String;
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        }
      } else {
        print('[Gemini] HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[Gemini] Lỗi: $e');
    }
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
