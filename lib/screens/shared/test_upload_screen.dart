import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/widgets/common/file_upload_widget.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';

class TestUploadScreen extends StatefulWidget {
  const TestUploadScreen({super.key});

  @override
  State<TestUploadScreen> createState() => _TestUploadScreenState();
}

class _TestUploadScreenState extends State<TestUploadScreen> {
  String? _uploadedFileUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test File Upload'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Test Cloudinary Upload',
              style: AppTextStyles.heading2,
            ),
            SizedBox(height: 32),
            FileUploadWidget(
              folder: 'test_uploads',
              uploadType: 'any',
              onFileUploaded: (url) {
                setState(() {
                  _uploadedFileUrl = url;
                });
              },
            ),
            SizedBox(height: 32),
            if (_uploadedFileUrl != null) ...[
              Text(
                'Upload Successful! ✅',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'File URL:',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _uploadedFileUrl!,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),
              if (_uploadedFileUrl!.contains('.jpg') ||
                  _uploadedFileUrl!.contains('.jpeg') ||
                  _uploadedFileUrl!.contains('.png'))
                Image.network(
                  _uploadedFileUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
            ],
          ],
        ),
      ),
    );
  }
}