import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/auth_service.dart';
import '../widgets/contact_list_item.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailSearchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _emailSearchResults = [];
  bool _isSearchingEmail = false;

  @override
  void dispose() {
    _searchController.dispose();
    _emailSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchUserByEmail() async {
    if (_emailSearchController.text.trim().isEmpty) return;

    setState(() {
      _isSearchingEmail = true;
    });

    try {
      List<UserModel> results = await AuthService.searchUsersByEmail(
        _emailSearchController.text.trim(),
      );
      
      setState(() {
        _emailSearchResults = results;
        _isSearchingEmail = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingEmail = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startChatWithUser(UserModel user) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null) return;

    try {
      String? chatRoomId = await chatProvider.createOrGetChatRoom(
        otherUserId: user.id,
        otherUser: user,
        currentUser: authProvider.currentUser!,
      );

      if (chatRoomId != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoom: chatProvider.getChatRoomById(chatRoomId),
              otherUser: user,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshContacts() async {
    await context.read<ChatProvider>().refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'My Contacts'),
                Tab(text: 'Find Users'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              children: [
                _buildContactsList(),
                _buildUserSearch(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshContacts,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Contacts List
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              List<UserModel> filteredContacts = chatProvider.filterContacts(_searchQuery);

              if (chatProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (filteredContacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty ? Icons.search_off : Icons.contacts_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty 
                            ? 'No contacts found'
                            : 'No contacts available',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Sync your contacts to find friends',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshContacts,
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync Contacts'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshContacts,
                child: ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    return ContactListItem(
                      user: filteredContacts[index],
                      onTap: () => _startChatWithUser(filteredContacts[index]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserSearch() {
    return Column(
      children: [
        // Email Search
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailSearchController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Search by email...',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  onSubmitted: (_) => _searchUserByEmail(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _searchUserByEmail,
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),

        // Search Results
        Expanded(
          child: _isSearchingEmail
              ? const Center(child: CircularProgressIndicator())
              : _emailSearchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search users by email',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter an email address to find users',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _emailSearchResults.length,
                      itemBuilder: (context, index) {
                        return ContactListItem(
                          user: _emailSearchResults[index],
                          onTap: () => _startChatWithUser(_emailSearchResults[index]),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
