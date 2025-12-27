// lib/screens/shared/message_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/messaging_service.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/services/file_download_service.dart';
import 'package:chemo_monitor_app/models/message_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class MessageScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;

  const MessageScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> with TickerProviderStateMixin {
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final FileDownloadService _fileDownloadService = FileDownloadService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  String? _currentUserId;
  String? _currentUserName;
  bool _isLoading = false;
  bool _isUploadingFile = false;
  late AnimationController _sendButtonController;
  Map<String, bool> _downloadingFiles = {}; // Track downloading files
  Map<String, double> _downloadProgress = {}; // Track download progress

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _markMessagesAsRead();
    
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = profile?.name ?? 'User';
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _messagingService.markConversationAsRead(user.uid, widget.otherUserId);
    }
  }

  Future<void> _pickAndSendFile() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Send File',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Photo Library
              _buildFileOption(
                icon: Icons.photo_library_rounded,
                title: 'Photo Library',
                subtitle: 'Choose from gallery',
                color: AppColors.wisteriaBlue,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              
              // Camera
              _buildFileOption(
                icon: Icons.camera_alt_rounded,
                title: 'Camera',
                subtitle: 'Take a photo',
                color: AppColors.pastelPetal,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              
              // 🆕 DOCUMENTS (PDF, DOCX, etc.)
              _buildFileOption(
                icon: Icons.insert_drive_file_rounded,
                title: 'Documents',
                subtitle: 'PDF, Word, Excel, etc.',
                color: AppColors.frozenWater,
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 ADD this new method for document picking:
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await _sendFileMessage(file);
      }
    } catch (e) {
      _showErrorSnackbar('Error picking document: ${e.toString()}');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await _sendFileMessage(File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackbar('Error picking image: ${e.toString()}');
    }
  }

  Future<void> _sendFileMessage(File file) async {
    if (_currentUserId == null || _currentUserName == null) return;

    setState(() => _isUploadingFile = true);

    try {
      await _messagingService.sendFileMessage(
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        receiverId: widget.otherUserId,
        receiverName: widget.otherUserName,
        file: file,
      );
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar('Failed to send file: ${e.toString()}');
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.pastelPetal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.softGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openImageViewer(String imageUrl, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          imageUrl: imageUrl,
          fileName: fileName,
        ),
      ),
    );
  }

  // REPLACE the _downloadFile method:
  Future<void> _downloadFile(String url, String fileName) async {
    final fileKey = '$url-$fileName';
    
    if (_downloadingFiles[fileKey] == true) {
      _showErrorSnackbar('Already downloading this file...');
      return;
    }

    setState(() {
      _downloadingFiles[fileKey] = true;
      _downloadProgress[fileKey] = 0.0;
    });

    try {
      // Show downloading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Downloading $fileName...')),
            ],
          ),
          backgroundColor: AppColors.frozenWater,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 30),
        ),
      );

      // Download and open file
      await _fileDownloadService.downloadAndOpenFile(
        url,
        fileName,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress[fileKey] = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadingFiles[fileKey] = false;
          _downloadProgress.remove(fileKey);
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSuccessSnackbar('✅ File opened: $fileName');
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingFiles[fileKey] = false;
          _downloadProgress.remove(fileKey);
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        String errorMessage = 'Failed to download file';
        
        if (e.toString().contains('Permission denied')) {
          errorMessage = 'Storage permission required. Please enable in Settings.';
        } else if (e.toString().contains('No app')) {
          errorMessage = 'No app available to open this file type';
        } else if (e.toString().contains('Network')) {
          errorMessage = 'Network error. Check your connection.';
        }

        _showErrorSnackbar(errorMessage);
        
        // Show alternative options
        _showDownloadOptionsDialog(url, fileName);
      }
    }
  }

  void _showDownloadOptionsDialog(String url, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.wisteriaBlue),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Download Options',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose an option to download:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            
            _buildDialogOption(
              icon: Icons.copy_rounded,
              title: 'Copy Download Link',
              subtitle: 'Paste in your browser to download',
              color: AppColors.wisteriaBlue,
              onTap: () {
                Navigator.pop(context);
                _copyDownloadLink(url);
              },
            ),
            
            const SizedBox(height: 8),
            
            _buildDialogOption(
              icon: Icons.open_in_browser_rounded,
              title: 'Open in Browser',
              subtitle: 'Download directly from browser',
              color: AppColors.frozenWater,
              onTap: () {
                Navigator.pop(context);
                _openInBrowser(url);
              },
            ),
            
            const SizedBox(height: 8),
            
            _buildDialogOption(
              icon: Icons.share_rounded,
              title: 'Share Link',
              subtitle: 'Share download link',
              color: AppColors.softGreen,
              onTap: () {
                Navigator.pop(context);
                _shareDownloadLink(url, fileName);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _copyDownloadLink(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      _showSuccessSnackbar('Download link copied! Paste in your browser.');
    } catch (e) {
      _showErrorSnackbar('Failed to copy link');
    }
  }

  Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (opened) {
        _showSuccessSnackbar('Opening in browser...');
      } else {
        _showErrorSnackbar('Could not open browser');
        _copyDownloadLink(url);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to open browser');
      _copyDownloadLink(url);
    }
  }

  Future<void> _shareDownloadLink(String url, String fileName) async {
    try {
      await Clipboard.setData(ClipboardData(text: 'Download $fileName: $url'));
      _showSuccessSnackbar('Download link copied for sharing');
    } catch (e) {
      _showErrorSnackbar('Failed to share link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.wisteriaBlue, // SOLID COLOR - Changed from gradient
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.otherUserId}',
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.wisteriaBlue, // SOLID COLOR - Changed from gradient
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.otherUserName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.otherUserRole,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_isUploadingFile)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.5,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_currentUserId == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.wisteriaBlue),
        ),
      );
    }

    return StreamBuilder<List<MessageModel>>(
      stream: _messagingService.getConversation(_currentUserId!, widget.otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.wisteriaBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final showDateSeparator = _shouldShowDateSeparator(messages, index);
            
            return Column(
              children: [
                if (showDateSeparator) _buildDateSeparator(message.timestamp),
                _buildMessageBubble(message),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowDateSeparator(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    
    final current = messages[index].timestamp;
    final previous = messages[index - 1].timestamp;
    
    return current.day != previous.day ||
           current.month != previous.month ||
           current.year != previous.year;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    String dateText;
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      dateText = 'Today';
    } else if (date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.honeydew,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.wisteriaBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.otherUserName}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: AppColors.pastelPetal),
          const SizedBox(height: 16),
          Text(
            'Error loading messages',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isMe = message.senderId == _currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(false),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: message.messageType == 'file' && message.fileType == 'image'
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.wisteriaBlue : Colors.white, // SOLID COLOR
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == 'file' && message.fileUrl != null)
                    _buildFileContent(message, isMe),
                  
                  if (message.message.isNotEmpty && 
                      !(message.messageType == 'file' && message.fileType == 'image'))
                    Padding(
                      padding: message.messageType == 'file' && message.fileType != 'image'
                          ? EdgeInsets.zero
                          : const EdgeInsets.only(bottom: 6),
                      child: Text(
                        message.message,
                        style: TextStyle(
                          fontSize: 15,
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  
                  _buildMessageFooter(message, isMe),
                ],
              ),
            ),
          ),
          if (isMe) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isMe) {
    return Container(
      width: 32,
      height: 32,
      margin: EdgeInsets.only(
        left: isMe ? 8 : 0,
        right: isMe ? 0 : 8,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.wisteriaBlue, // SOLID COLOR - Changed from gradient
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.wisteriaBlue.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: isMe
            ? const Icon(Icons.person_rounded, color: Colors.white, size: 16)
            : Text(
                widget.otherUserName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Update _buildFileContent to show download progress:
  Widget _buildFileContent(MessageModel message, bool isMe) {
    final fileKey = '${message.fileUrl}-${message.fileName}';
    final isDownloading = _downloadingFiles[fileKey] == true;
    final progress = _downloadProgress[fileKey] ?? 0.0;
    
    if (message.fileType == 'image' && message.fileUrl != null) {
      return GestureDetector(
        onTap: () => _openImageViewer(message.fileUrl!, message.fileName ?? 'Image'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.network(
                message.fileUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 200,
                    color: AppColors.lightBackground,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.wisteriaBlue),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: AppColors.lightBackground,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, color: AppColors.textSecondary, size: 48),
                        const SizedBox(height: 8),
                        Text('Image unavailable', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                      GestureDetector(
                        onTap: () => _downloadFile(message.fileUrl!, message.fileName ?? 'image.jpg'),
                        child: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Document/File bubble with progress
      String fileType = 'file';
      String fileName = message.fileName ?? 'File';
      
      if (fileName.toLowerCase().endsWith('.pdf')) {
        fileType = 'pdf';
      } else if (fileName.toLowerCase().endsWith('.doc') || 
                 fileName.toLowerCase().endsWith('.docx')) {
        fileType = 'document';
      } else if (fileName.toLowerCase().endsWith('.xls') || 
                 fileName.toLowerCase().endsWith('.xlsx')) {
        fileType = 'spreadsheet';
      }
      
      return GestureDetector(
        onTap: isDownloading ? null : () => _downloadFile(message.fileUrl!, fileName),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withOpacity(0.2) : AppColors.honeydew,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withOpacity(0.3) : AppColors.wisteriaBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getFileIcon(fileType),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fileType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDownloading 
                              ? 'Downloading ${(progress * 100).toInt()}%' 
                              : 'Tap to download & open',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white60 : AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDownloading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMe ? Colors.white : AppColors.wisteriaBlue,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.download_rounded,
                      color: isMe ? Colors.white : AppColors.wisteriaBlue,
                      size: 20,
                    ),
                ],
              ),
              
              // Progress bar
              if (isDownloading) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: isMe 
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.lightBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMe ? Colors.white : AppColors.wisteriaBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'document':
        return Icons.description_rounded;
      case 'spreadsheet':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildMessageFooter(MessageModel message, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('hh:mm a').format(message.timestamp),
          style: TextStyle(
            fontSize: 11,
            color: isMe ? Colors.white70 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(message),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(MessageModel message) {
    IconData icon = Icons.done_rounded;
    Color color = Colors.white70;
    
    if (message.isPending) {
      icon = Icons.access_time_rounded;
      color = Colors.white60;
    } else if (message.isReadStatus) {
      icon = Icons.done_all_rounded;
      color = AppColors.frozenWater;
    } else if (message.isDelivered) {
      icon = Icons.done_all_rounded;
      color = Colors.white70;
    }
    
    return Icon(icon, size: 14, color: color);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.honeydew,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: Icon(Icons.add_circle_rounded, color: AppColors.wisteriaBlue, size: 28),
                onPressed: _isUploadingFile || _isLoading ? null : _pickAndSendFile,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    if (text.isNotEmpty) {
                      _sendButtonController.forward();
                    } else {
                      _sendButtonController.reverse();
                    }
                  },
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isUploadingFile,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOut),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.wisteriaBlue, // SOLID COLOR - Changed from gradient
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.wisteriaBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: (_isLoading || _isUploadingFile) ? null : _sendMessage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || 
        _currentUserId == null || 
        _currentUserName == null ||
        _isUploadingFile) {
      return;
    }

    final text = _messageController.text.trim();
    _messageController.clear();
    _sendButtonController.reverse();
    _focusNode.unfocus();

    setState(() => _isLoading = true);

    try {
      await _messagingService.sendTextMessage(
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        receiverId: widget.otherUserId,
        receiverName: widget.otherUserName,
        message: text,
      );
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar('Failed to send message');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Full Screen Image Viewer
class _ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const _ImageViewerScreen({
    required this.imageUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fileName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () async {
              try {
                final uri = Uri.parse(imageUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to download image')),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}