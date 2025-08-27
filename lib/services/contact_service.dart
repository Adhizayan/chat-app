import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ContactService {
  static List<Contact> _cachedContacts = [];

  // Check and request contacts permission
  static Future<bool> requestContactsPermission() async {
    try {
      PermissionStatus permission = await Permission.contacts.status;
      
      if (permission.isDenied) {
        permission = await Permission.contacts.request();
      }

      return permission.isGranted;
    } catch (e) {
      print('Error requesting contacts permission: $e');
      return false;
    }
  }

  // Get all contacts from device
  static Future<List<Contact>> getDeviceContacts() async {
    try {
      bool hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        throw Exception('Contacts permission not granted');
      }

      Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false,
        photoHighResolution: false,
      );

      _cachedContacts = contacts.toList();
      return _cachedContacts;
    } catch (e) {
      throw Exception('Failed to get device contacts: $e');
    }
  }

  // Extract phone numbers from contacts
  static List<String> extractPhoneNumbers(List<Contact> contacts) {
    List<String> phoneNumbers = [];

    for (Contact contact in contacts) {
      if (contact.phones != null) {
        for (Item phone in contact.phones!) {
          String? phoneNumber = phone.value;
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            // Clean and format phone number
            String cleanedNumber = _cleanPhoneNumber(phoneNumber);
            if (cleanedNumber.isNotEmpty && !phoneNumbers.contains(cleanedNumber)) {
              phoneNumbers.add(cleanedNumber);
            }
          }
        }
      }
    }

    return phoneNumbers;
  }

  // Find users that match device contacts
  static Future<List<UserModel>> findContactUsers() async {
    try {
      // Get device contacts
      List<Contact> contacts = await getDeviceContacts();
      
      // Extract phone numbers
      List<String> phoneNumbers = extractPhoneNumbers(contacts);
      
      if (phoneNumbers.isEmpty) {
        return [];
      }

      // Split phone numbers into chunks (Firestore 'whereIn' has a limit of 10)
      List<UserModel> allUsers = [];
      int chunkSize = 10;
      
      for (int i = 0; i < phoneNumbers.length; i += chunkSize) {
        int end = (i + chunkSize < phoneNumbers.length) 
            ? i + chunkSize 
            : phoneNumbers.length;
        
        List<String> chunk = phoneNumbers.sublist(i, end);
        List<UserModel> chunkUsers = await AuthService.getUsersByPhoneNumbers(chunk);
        allUsers.addAll(chunkUsers);
      }

      return allUsers;
    } catch (e) {
      throw Exception('Failed to find contact users: $e');
    }
  }

  // Get contact info by phone number
  static Contact? getContactByPhoneNumber(String phoneNumber) {
    String cleanedTarget = _cleanPhoneNumber(phoneNumber);
    
    for (Contact contact in _cachedContacts) {
      if (contact.phones != null) {
        for (Item phone in contact.phones!) {
          String? contactPhone = phone.value;
          if (contactPhone != null) {
            String cleanedContactPhone = _cleanPhoneNumber(contactPhone);
            if (cleanedContactPhone == cleanedTarget) {
              return contact;
            }
          }
        }
      }
    }
    return null;
  }

  // Get display name for a user (prefer contact name over user's display name)
  static String getDisplayName(UserModel user) {
    if (user.phoneNumber != null) {
      Contact? contact = getContactByPhoneNumber(user.phoneNumber!);
      if (contact != null && contact.displayName != null && contact.displayName!.isNotEmpty) {
        return contact.displayName!;
      }
    }
    return user.displayName;
  }

  // Clean and format phone number
  static String _cleanPhoneNumber(String phoneNumber) {
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

  // Sync contacts with server
  static Future<void> syncContacts() async {
    try {
      List<UserModel> contactUsers = await findContactUsers();
      
      // Update current user's contact list
      List<String> contactUserIds = contactUsers.map((user) => user.id).toList();
      
      await AuthService.updateUserProfile();
      
      // Store contact sync timestamp in shared preferences
      // This could be used to implement incremental sync
      
    } catch (e) {
      print('Failed to sync contacts: $e');
      // Don't throw here as contact sync failures shouldn't break the app
    }
  }

  // Check if contact sync is enabled (from app settings)
  static Future<bool> isContactSyncEnabled() async {
    // This would check shared preferences or user settings
    // For now, return true if permission is granted
    return await requestContactsPermission();
  }

  // Get contact suggestions (users not in contacts but in the app)
  static Future<List<UserModel>> getContactSuggestions() async {
    try {
      // This could implement a suggestion algorithm based on:
      // - Mutual contacts
      // - Recent interactions
      // - Location (if enabled)
      // For now, return empty list
      return [];
    } catch (e) {
      print('Failed to get contact suggestions: $e');
      return [];
    }
  }

  // Format phone number for display
  static String formatPhoneNumberForDisplay(String phoneNumber) {
    String cleaned = _cleanPhoneNumber(phoneNumber);
    
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
}
