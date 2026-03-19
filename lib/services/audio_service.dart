import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

/// Bao bọc package `record` để ghi âm micro trên Android/iOS và Web.
/// Trả về dữ liệu âm thanh dưới dạng Uint8List.
class WebAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _tempFilePath;

  Future<bool> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        print('[AudioRecorder] LỖI: Không có quyền micro');
        return false;
      }

      if (kIsWeb) {
        // Trên web không dùng tệp tin vật lý (path_provider không hoạt động trên web)
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus, // Web hỗ trợ tốt định dạng này
            bitRate: 128000,
            sampleRate: 16000,
          ),
          path: '', // Thêm chuỗi rỗng để thỏa mãn tham số bắt buộc
        );
        print('[AudioRecorder] Bắt đầu ghi âm trên Web (Blob)');
      } else {
        // Trên thiết bị thực (Mobile/Desktop)
        final dir = await getTemporaryDirectory();
        _tempFilePath = '${dir.path}/taskhero_recording.m4a';
        print('[AudioRecorder] Bắt đầu ghi âm vào: $_tempFilePath');

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 16000, // 16kHz tối ưu cho Deepgram STT
          ),
          path: _tempFilePath!,
        );
      }
      return true;
    } catch (e) {
      print('[AudioRecorder] LỖI: startRecording thất bại: $e');
      return false;
    }
  }

  Future<Uint8List?> stopRecording() async {
    try {
      final isRecording = await _recorder.isRecording();
      if (!isRecording) {
        print('[AudioRecorder] CẢNH BÁO: Không có phiên ghi âm nào đang chạy');
        return null;
      }

      final path = await _recorder.stop();
      print('[AudioRecorder] Dừng ghi âm. Kết quả trả về: $path');

      if (path == null) {
        print('[AudioRecorder] LỖI: Đường dẫn trả về null');
        return null;
      }

      if (kIsWeb) {
        // Trên web, stop() trả về một Blob URL. Cần fetch để lấy Uint8List.
        final response = await http.get(Uri.parse(path));
        print('[AudioRecorder] Đã fetch blob trên Web: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        // Xử lý tệp tin vật lý
        final file = io.File(path);
        if (!await file.exists()) {
          print('[AudioRecorder] LỖI: File âm thanh không tồn tại: $path');
          return null;
        }

        final bytes = await file.readAsBytes();
        print('[AudioRecorder] Đã đọc ${bytes.length} bytes từ file âm thanh');

        try {
          await file.delete();
        } catch (_) {}

        return bytes;
      }
    } catch (e) {
      print('[AudioRecorder] LỖI: stopRecording thất bại: $e');
      return null;
    }
  }

  void dispose() {
    _recorder.dispose();
    _tempFilePath = null;
  }
}
