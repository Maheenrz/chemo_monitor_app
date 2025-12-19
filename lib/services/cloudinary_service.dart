import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // CREDENTIALS
  static const String cloudName = 'daytmv7zr';
  static const String uploadPreset = 'chemo_unsigned'; 
  static const String apiKey = '115916637386485';
  static const String apiSecret = 'vzgVr1r_8TJeAYz3_WmFUW7yvvs';

  late CloudinaryPublic cloudinary;

  CloudinaryService() {
    cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  /// Upload image or document
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
    return await uploadFile(
      file: imageFile,
      folder: 'profile_pictures',
      fileName: 'user_$userId',
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
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp,
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

  /// Generate signature for authenticated requests
  String _generateSignature(String publicId, String timestamp) {
    // Note: For production, implement proper SHA1 signing
    // For now, using simplified version
    return '$publicId&timestamp=$timestamp$apiSecret';
  }

  /// Get optimized image URL
  String getOptimizedImageUrl(String imageUrl, {int? width, int? height}) {
    if (!imageUrl.contains('cloudinary.com')) return imageUrl;

    final parts = imageUrl.split('/upload/');
    if (parts.length != 2) return imageUrl;

    String transformation = 'c_fill';
    if (width != null) transformation += ',w_$width';
    if (height != null) transformation += ',h_$height';
    transformation += ',q_auto,f_auto';

    return '${parts[0]}/upload/$transformation/${parts[1]}';
  }
}