import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';

class MarkdownTextWidget extends StatelessWidget {
  final String text;
  final Color textColor;

  const MarkdownTextWidget({
    super.key,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseMarkdown(text, textColor),
    );
  }

  List<Widget> _parseMarkdown(String text, Color color) {
    List<Widget> widgets = [];
    List<String> lines = text.split('\n');

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: 8));
        continue;
      }

      // Headers (##)
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.substring(3),
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
        ));
      }
      // Bold text (**)
      else if (line.contains('**')) {
        widgets.add(_buildMixedText(line, color));
      }
      // Bullet points (• or -)
      else if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
        widgets.add(Padding(
          padding: EdgeInsets.only(left: 8, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: color, fontSize: 16)),
              Expanded(
                child: Text(
                  line.replaceFirst(RegExp(r'^[\s•-]+'), ''),
                  style: AppTextStyles.bodyMedium.copyWith(color: color),
                ),
              ),
            ],
          ),
        ));
      }
      // Warning/Alert (⚠️)
      else if (line.contains('⚠️')) {
        widgets.add(Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Text(
            line,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.orange[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ));
      }
      // Normal text
      else {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            line,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
          ),
        ));
      }
    }

    return widgets;
  }

  Widget _buildMixedText(String line, Color color) {
    List<TextSpan> spans = [];
    RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (Match match in boldPattern.allMatches(line)) {
      // Add normal text before bold
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: line.substring(lastIndex, match.start),
          style: AppTextStyles.bodyMedium.copyWith(color: color),
        ));
      }
      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastIndex),
        style: AppTextStyles.bodyMedium.copyWith(color: color),
      ));
    }

    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}