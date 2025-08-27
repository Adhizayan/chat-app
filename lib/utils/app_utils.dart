import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AppUtils {
  // Date formatting utilities
  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Same day - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      // This week - show day name and time
      return '${DateFormat('EEE HH:mm').format(timestamp)}';
    } else if (difference.inDays < 365) {
      // This year - show month, day and time
      return DateFormat('MMM dd, HH:mm').format(timestamp);
    } else {
      // Older than a year
      return DateFormat('MMM dd, yyyy HH:mm').format(timestamp);
    }
  }

  static String formatChatListTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Same day - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEE').format(timestamp);
    } else if (difference.inDays < 365) {
      // This year - show month and day
      return DateFormat('MMM dd').format(timestamp);
    } else {
      // Older than a year
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  static String formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 30) {
      return 'just now';
    } else if (difference.inMinutes < 1) {
      return 'less than a minute ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(lastSeen);
    }
  }

  // Text utilities
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Phone number utilities
  static String cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Handle different country code formats
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    } else if (cleaned.startsWith('0') && !cleaned.startsWith('00')) {
      // This is a simplification - in a real app, you'd need to handle country codes properly
      cleaned = cleaned.substring(1);
    }
    
    return cleaned;
  }

  static String formatPhoneNumber(String phoneNumber) {
    String cleaned = cleanPhoneNumber(phoneNumber);
    
    // Basic formatting - in a real app, you'd use a proper phone formatting library
    if (cleaned.length >= 10) {
      String formatted = cleaned;
      if (cleaned.startsWith('+1') && cleaned.length == 12) {
        // US number
        formatted = '+1 (${cleaned.substring(2, 5)}) ${cleaned.substring(5, 8)}-${cleaned.substring(8)}';
      } else if (cleaned.length == 10) {
        // US number without country code
        formatted = '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
      }
      return formatted;
    }
    
    return phoneNumber;
  }

  // Validation utilities
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhoneNumber(String phoneNumber) {
    String cleaned = cleanPhoneNumber(phoneNumber);
    return cleaned.length >= 10 && cleaned.length <= 15;
  }

  // Color utilities
  static Color getAvatarColor(String text) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];

    int hash = text.hashCode;
    return colors[hash.abs() % colors.length];
  }

  // File utilities
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  static IconData getFileIcon(String fileName) {
    String extension = getFileExtension(fileName);
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Network utilities
  static bool isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  // Message utilities
  static String getMessagePreview(String content, int maxLength) {
    if (content.isEmpty) return '';
    
    // Remove extra whitespace and line breaks
    String cleaned = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return truncateText(cleaned, maxLength);
  }

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = (bytes.bitLength - 1) ~/ 10;
    
    if (i >= suffixes.length) i = suffixes.length - 1;
    
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Theme utilities
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getContrastColor(Color color) {
    // Calculate luminance
    double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Navigation utilities
  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: confirmColor != null 
                ? TextButton.styleFrom(foregroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Debug utilities
  static void debugLog(String message, [String? tag]) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final logTag = tag != null ? '[$tag]' : '[DEBUG]';
    print('$timestamp $logTag $message');
  }
}
