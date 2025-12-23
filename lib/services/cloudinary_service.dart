import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  // Read credentials from .env file
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
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

  /// Upload any file (image or document) for chat
  /// Returns Map with 'url' and 'fileName'
  Future<Map<String, String>> uploadChatFile(File file, {String? customFileName}) async {
    try {
      // Extract original filename or use custom name
      final originalFileName = file.path.split('/').last;
      final fileName = customFileName ?? originalFileName;
      
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'chat_files',
          resourceType: CloudinaryResourceType.Auto,
        ),
      );

      return {
        'url': response.secureUrl,
        'fileName': fileName,
        'publicId': response.publicId,
      };
    } catch (e) {
      throw Exception('Chat file upload failed: $e');
    }
  }

  /// Upload profile picture
  /// Returns Map with 'url' and 'publicId'
  Future<Map<String, String>> uploadProfilePicture(File imageFile, String userId) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'profile_images',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return {
        'url': response.secureUrl,
        'publicId': response.publicId,
      };
    } catch (e) {
      throw Exception('Profile picture upload failed: $e');
    }
  }

  /// Get file type from URL
  String getFileType(String url) {
    if (url.contains('.jpg') || url.contains('.jpeg') || 
        url.contains('.png') || url.contains('.gif') || url.contains('.webp')) {
      return 'image';
    } else if (url.contains('.pdf')) {
      return 'pdf';
    } else if (url.contains('.doc') || url.contains('.docx')) {
      return 'document';
    } else if (url.contains('.txt')) {
      return 'text';
    } else {
      return 'file';
    }
  }

  /// Get file type from File object
  String getFileTypeFromFile(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg') || 
        path.endsWith('.png') || path.endsWith('.gif') || path.endsWith('.webp')) {
      return 'image';
    } else if (path.endsWith('.pdf')) {
      return 'pdf';
    } else if (path.endsWith('.doc') || path.endsWith('.docx')) {
      return 'document';
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
    
    final stringToSign = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    
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

    List<String> transformations = ['c_fill'];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
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