import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Bao bọc package `record` để ghi âm micro trên Android/iOS.
/// Trả về dữ liệu âm thanh M4A/AAC dưới dạng Uint8List.
class WebAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _tempFilePath;

  /// Bắt đầu ghi âm từ micro.
  /// Trả về `true` nếu ghi âm thành công, `false` nếu bị từ chối quyền.
  Future<bool> startRecording() async {
    try {
      // Kiểm tra quyền micro
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        print('[AudioRecorder] LỖI: Không có quyền micro');
        return false;
      }

      // Lấy thư mục tạm để lưu file âm thanh
      final dir = await getTemporaryDirectory();
      _tempFilePath = '${dir.path}/taskhero_recording.m4a';
      print('[AudioRecorder] Bắt đầu ghi âm vào: $_tempFilePath');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 16000, // 16kHz — tối ưu cho Deepgram STT
        ),
        path: _tempFilePath!,
      );

      print('[AudioRecorder] Ghi âm đã bắt đầu thành công');
      return true;
    } catch (e) {
      print('[AudioRecorder] LỖI: startRecording thất bại: $e');
      return false;
    }
  }

  /// Dừng ghi âm và trả về dữ liệu âm thanh dưới dạng Uint8List.
  Future<Uint8List?> stopRecording() async {
    try {
      final isRecording = await _recorder.isRecording();
      if (!isRecording) {
        print('[AudioRecorder] CẢNH BÁO: Không có phiên ghi âm nào đang chạy');
        return null;
      }

      final path = await _recorder.stop();
      print('[AudioRecorder] Dừng ghi âm. File lưu tại: $path');

      if (path == null) {
        print('[AudioRecorder] LỖI: Đường dẫn file trả về null');
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        print('[AudioRecorder] LỖI: File âm thanh không tồn tại: $path');
        return null;
      }

      final bytes = await file.readAsBytes();
      print('[AudioRecorder] Đã đọc ${bytes.length} bytes từ file âm thanh');

      // Xóa file tạm sau khi đọc
      try {
        await file.delete();
      } catch (_) {
        // Không quan trọng — bỏ qua
      }

      return bytes;
    } catch (e) {
      print('[AudioRecorder] LỖI: stopRecording thất bại: $e');
      return null;
    }
  }

  /// Giải phóng tài nguyên.
  void dispose() {
    _recorder.dispose();
    _tempFilePath = null;
  }
}
