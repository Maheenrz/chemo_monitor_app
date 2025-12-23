import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/messaging_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FileUploadWidget extends StatefulWidget {
  final Function(String fileUrl) onFileUploaded;
  final String uploadType; // 'image', 'document', 'any'
  final String folder;
  final String? currentUserId;
  final String? currentUserName;
  final String? receiverId;
  final String? receiverName;
  final bool forMessaging; // NEW: Specify if for messaging

  const FileUploadWidget({
    super.key,
    required this.onFileUploaded,
    this.uploadType = 'any',
    required this.folder,
    this.currentUserId,
    this.currentUserName,
    this.receiverId,
    this.receiverName,
    this.forMessaging = false, // Default to false
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final MessagingService _messagingService = MessagingService();
  bool _uploading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadFile(File(image.path));
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        await _uploadFile(File(result.files.single.path!));
      }
    } catch (e) {
      _showError('Failed to pick document: $e');
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() => _uploading = true);

    try {
      // FOR MESSAGING: Use MessagingService
      if (widget.forMessaging && 
          widget.currentUserId != null && 
          widget.currentUserName != null && 
          widget.receiverId != null && 
          widget.receiverName != null) {
        
        // Use the CORRECT method: sendFileMessage
        await _messagingService.sendFileMessage(
          senderId: widget.currentUserId!,
          senderName: widget.currentUserName!,
          receiverId: widget.receiverId!,
          receiverName: widget.receiverName!,
          file: file,
        );
        
        // Call the callback (you might want to modify MessagingService to return URL)
        widget.onFileUploaded('file_uploaded_for_messaging');
        
      } else {
        // FOR PROFILE/OTHER UPLOADS: Use CloudinaryService directly
        // You need to inject CloudinaryService or create a separate method
        // For now, throw error or handle differently
        throw Exception('File upload for non-messaging not implemented yet');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uploading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Uploading...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (widget.uploadType == 'image' || widget.uploadType == 'any')
          ElevatedButton.icon(
            onPressed: _pickAndUploadImage,
            icon: const Icon(Icons.image),
            label: const Text('Upload Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        if (widget.uploadType == 'any') const SizedBox(height: 8),
        if (widget.uploadType == 'document' || widget.uploadType == 'any')
          ElevatedButton.icon(
            onPressed: _pickAndUploadDocument,
            icon: const Icon(Icons.file_present),
            label: const Text('Upload Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}