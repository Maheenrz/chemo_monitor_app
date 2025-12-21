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

  /// Upload image (used by Profile Edit Screen)
  /// [imageFile] - The image file to upload
  /// [folder] - Optional folder name in Cloudinary (e.g., 'profile_images')
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder ?? 'uploads',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Upload any file (image or document)
  /// Returns URL of uploaded file
  Future<String> uploadFile({
    required File file,
    required String folder,
    String? fileName,
  }) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Auto,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    return await uploadImage(
      imageFile,
      folder: 'profile_images',
    );
  }

  /// Upload medical document
  Future<String> uploadMedicalDocument(File file, String patientId) async {
    return await uploadFile(
      file: file,
      folder: 'patient_documents/$patientId',
    );
  }

  /// Upload chat attachment
  Future<String> uploadChatAttachment(File file, String chatId) async {
    return await uploadFile(
      file: file,
      folder: 'chat_attachments/$chatId',
    );
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
    // Sort parameters alphabetically
    final sortedKeys = params.keys.toList()..sort();
    
    // Create the string to sign
    final stringToSign = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    
    // Add API secret
    final fullString = '$stringToSign$apiSecret';
    
    // Generate SHA-1 hash
    final bytes = utf8.encode(fullString);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Extract public ID from Cloudinary URL
  /// Example: https://res.cloudinary.com/demo/image/upload/v1234567890/profile_images/abc123.jpg
  /// Returns: profile_images/abc123
  String extractPublicId(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the index of 'upload'
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        throw Exception('Invalid Cloudinary URL');
      }
      
      // Get everything after the version (v1234567890)
      final relevantSegments = pathSegments.sublist(uploadIndex + 2);
      
      // Join and remove file extension
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

// ============================================================================
// SETUP INSTRUCTIONS FOR .ENV FILE
// ============================================================================

/*

1. YOUR .ENV FILE SHOULD CONTAIN:
   ```
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   CLOUDINARY_UPLOAD_PRESET=your_upload_preset
   ```

2. MAKE SURE flutter_dotenv IS IN pubspec.yaml:
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
     cloudinary_public: ^0.21.0
     image_picker: ^1.0.4
     http: ^1.1.0
     crypto: ^3.0.3
   ```

3. ADD .ENV TO ASSETS in pubspec.yaml:
   ```yaml
   flutter:
     assets:
       - .env
   ```

4. LOAD .ENV IN main.dart:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   Future<void> main() async {
     await dotenv.load(fileName: ".env");
     runApp(MyApp());
   }
   ```

5. MAKE SURE .ENV IS IN .gitignore:
   ```
   .env
   ```

6. USAGE EXAMPLE:
   ```dart
   final cloudinaryService = CloudinaryService();
   
   try {
     final imageUrl = await cloudinaryService.uploadImage(
       imageFile,
       folder: 'profile_images',
     );
     print('Uploaded: $imageUrl');
   } catch (e) {
     print('Error: $e');
   }
   ```

*/