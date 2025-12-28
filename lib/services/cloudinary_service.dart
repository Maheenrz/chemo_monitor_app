import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  // Read credentials from .env file
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  late CloudinaryPublic cloudinary;

  CloudinaryService() {
    if (cloudName.isEmpty) {
      throw Exception('CLOUDINARY_CLOUD_NAME not found in .env file');
    }
    if (uploadPreset.isEmpty) {
      throw Exception('CLOUDINARY_UPLOAD_PRESET not found in .env file');
    }

    cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  Future<Map<String, String>> uploadChatFile(File file,
      {String? customFileName}) async {
    try {
      final originalFileName = file.path.split('/').last;
      final fileName = customFileName ?? originalFileName;

      print('📤 Uploading file: $fileName');
      print('📤 File path: ${file.path}');

      // Determine if it's an image or document
      final extension = fileName.toLowerCase().split('.').last;
      final isImage =
          ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
      final isPdf = extension == 'pdf';

      print(
          '📤 File type: ${isImage ? "Image" : (isPdf ? "PDF" : "Document")}');

      // Set resource type based on file type
      final resourceType = (isPdf || !isImage)
          ? CloudinaryResourceType.Raw
          : CloudinaryResourceType.Auto;

      print('📤 Uploading with resource type: $resourceType');

      // Upload file
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'chat_files',
          resourceType: resourceType,
        ),
      );

      print('✅ Upload successful!');
      print('✅ URL: ${response.secureUrl}');
      print('✅ Public ID: ${response.publicId}');

      return {
        'url': response.secureUrl,
        'fileName': fileName,
        'publicId': response.publicId,
      };
    } catch (e) {
      print('❌ Upload failed: $e');

      // More specific error messages
      if (e.toString().contains('File size exceeds')) {
        throw Exception('File is too large. Maximum file size is 10MB.');
      } else if (e.toString().contains('Invalid file type')) {
        throw Exception(
            'File type not supported. Please upload images, PDFs, or documents.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your connection.');
      }

      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Upload profile picture
  Future<Map<String, String>> uploadProfilePicture(
      File imageFile, String userId) async {
    try {
      print('📤 Uploading profile picture for user: $userId');

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'profile_images',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('✅ Profile picture uploaded successfully!');
      print('✅ URL: ${response.secureUrl}');

      return {
        'url': response.secureUrl,
        'publicId': response.publicId,
      };
    } catch (e) {
      print('❌ Profile picture upload failed: $e');
      throw Exception('Profile picture upload failed: $e');
    }
  }

  /// Get file type from URL
  String getFileType(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.gif') ||
        lowerUrl.contains('.webp') ||
        lowerUrl.contains('.bmp')) {
      return 'image';
    } else if (lowerUrl.contains('.pdf')) {
      return 'pdf';
    } else if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx')) {
      return 'document';
    } else if (lowerUrl.contains('.xls') || lowerUrl.contains('.xlsx')) {
      return 'spreadsheet';
    } else if (lowerUrl.contains('.ppt') || lowerUrl.contains('.pptx')) {
      return 'presentation';
    } else if (lowerUrl.contains('.txt')) {
      return 'text';
    } else {
      return 'file';
    }
  }

  /// Get file type from File object
  String getFileTypeFromFile(File file) {
    final path = file.path.toLowerCase();

    if (path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.endsWith('.bmp')) {
      return 'image';
    } else if (path.endsWith('.pdf')) {
      return 'pdf';
    } else if (path.endsWith('.doc') || path.endsWith('.docx')) {
      return 'document';
    } else if (path.endsWith('.xls') || path.endsWith('.xlsx')) {
      return 'spreadsheet';
    } else if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
      return 'presentation';
    } else if (path.endsWith('.txt')) {
      return 'text';
    } else {
      return 'file';
    }
  }

  /// Get file name from file path
  String getFileNameFromPath(String filePath) {
    return filePath.split('/').last;
  }

  /// Extract filename from Cloudinary URL
  String extractFileNameFromUrl(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) return 'file';

      final lastSegment = pathSegments.last;
      final decodedLastSegment = Uri.decodeComponent(lastSegment);

      return decodedLastSegment;
    } catch (e) {
      print('Error extracting filename: $e');
      return 'file';
    }
  }

  /// Delete file from Cloudinary
  Future<bool> deleteFile(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature({
        'public_id': publicId,
        'timestamp': timestamp,
      });

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['result'] == 'ok';
      }
      return false;
    } catch (e) {
      print('Delete failed: $e');
      return false;
    }
  }

  /// Generate signature for authenticated requests (SHA-1)
  String _generateSignature(Map<String, dynamic> params) {
    final sortedKeys = params.keys.toList()..sort();

    final stringToSign =
        sortedKeys.map((key) => '$key=${params[key]}').join('&');

    final fullString = '$stringToSign$apiSecret';

    final bytes = utf8.encode(fullString);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  /// Extract public ID from Cloudinary URL
  String extractPublicId(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;

      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        throw Exception('Invalid Cloudinary URL');
      }

      final relevantSegments = pathSegments.sublist(uploadIndex + 2);

      final publicIdWithExt = relevantSegments.join('/');
      final lastDotIndex = publicIdWithExt.lastIndexOf('.');

      if (lastDotIndex != -1) {
        return publicIdWithExt.substring(0, lastDotIndex);
      }

      return publicIdWithExt;
    } catch (e) {
      print('Error extracting public ID: $e');
      return '';
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(
    String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!imageUrl.contains('cloudinary.com')) return imageUrl;

    final parts = imageUrl.split('/upload/');
    if (parts.length != 2) return imageUrl;

    List<String> transformations = [];

    if (width != null || height != null) {
      transformations.add('c_fill');
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
    }

    transformations.add('q_$quality');
    transformations.add('f_$format');

    final transformation = transformations.join(',');

    return '${parts[0]}/upload/$transformation/${parts[1]}';
  }

  /// Get thumbnail URL (optimized for avatars)
  String getThumbnailUrl(String imageUrl, {int size = 200}) {
    return getOptimizedImageUrl(
      imageUrl,
      width: size,
      height: size,
      quality: 'auto',
      format: 'auto',
    );
  }
}
