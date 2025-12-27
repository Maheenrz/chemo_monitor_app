import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class FileDownloadService {
  final Dio _dio = Dio();

  /// Request storage permissions
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      if (await Permission.photos.isDenied) {
        final result = await Permission.photos.request();
        if (result.isGranted) return true;
      }
      
      // For older Android versions
      if (await Permission.storage.isDenied) {
        final result = await Permission.storage.request();
        if (result.isGranted) return true;
      }

      // Try manage external storage for Android 11+
      if (await Permission.manageExternalStorage.isDenied) {
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      }

      return true; // Already granted
    }
    return true; // iOS handles permissions differently
  }

  /// Download file to device storage
  Future<String> downloadFile(
    String url,
    String fileName, {
    Function(int, int)? onProgress,
  }) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get download directory
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Try to get Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        
        if (!await directory.exists()) {
          // Fallback to app documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // iOS
        directory = await getApplicationDocumentsDirectory();
      }

      // Create ChemoMonitor subfolder
      final chemoDir = Directory('${directory.path}/ChemoMonitor');
      if (!await chemoDir.exists()) {
        await chemoDir.create(recursive: true);
      }

      // Clean filename
      final cleanFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filePath = '${chemoDir.path}/$cleanFileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        print('✅ File already exists: $filePath');
        return filePath;
      }

      // Download file
      print('📥 Downloading: $url');
      print('📁 Saving to: $filePath');

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received, total);
          }
        },
      );

      print('✅ Download complete: $filePath');
      return filePath;
      
    } catch (e) {
      print('❌ Download error: $e');
      rethrow;
    }
  }

  /// Open file in device's default app
  Future<bool> openFile(String filePath) async {
    try {
      print('📂 Opening file: $filePath');
      
      final result = await OpenFilex.open(filePath);
      
      print('📱 Open result: ${result.type} - ${result.message}');
      
      // Check result
      switch (result.type) {
        case ResultType.done:
          return true;
        case ResultType.fileNotFound:
          throw Exception('File not found');
        case ResultType.noAppToOpen:
          throw Exception('No app available to open this file type');
        case ResultType.permissionDenied:
          throw Exception('Permission denied');
        case ResultType.error:
          throw Exception(result.message ?? 'Unknown error');
        default:
          return false;
      }
    } catch (e) {
      print('❌ Error opening file: $e');
      rethrow;
    }
  }

  /// Download and open file
  Future<void> downloadAndOpenFile(
    String url,
    String fileName, {
    Function(int, int)? onProgress,
  }) async {
    try {
      // Download file
      final filePath = await downloadFile(url, fileName, onProgress: onProgress);
      
      // Small delay to ensure file is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Open file
      await openFile(filePath);
    } catch (e) {
      rethrow;
    }
  }

  /// Get file size in human-readable format
  String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}