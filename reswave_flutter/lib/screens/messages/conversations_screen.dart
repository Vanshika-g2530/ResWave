import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/message_models.dart';
import '../../models/network_models.dart';
import '../../services/api_client.dart';
import 'chat_screen.dart';

class _MessageContact {
  final String userId;
  final String name;
  final String role;
  final ConversationModel? conversation;

  _MessageContact({
    required this.userId,
    required this.name,
    required this.role,
    this.conversation,
  });
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();

  List<_MessageContact> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Fetch accepted connections and existing conversations.
      final results = await Future.wait([
        _apiService.getConnections(),
        _apiService.getConversations(),
      ]);

      final connections = results[0] as List<ConnectionModel>;
      final conversations = results[1] as List<ConversationModel>;

      final Map<String, _MessageContact> contactsMap = {};

      // Add all accepted connections.
      for (final connection in connections) {
        if (connection.userId.isEmpty) continue;

        contactsMap[connection.userId] = _MessageContact(
          userId: connection.userId,
          name: connection.displayName,
          role: connection.role,
        );
      }

      // Attach existing conversations to their contacts.
      for (final conversation in conversations) {
        if (conversation.otherUserId.isEmpty) continue;

        contactsMap[conversation.otherUserId] = _MessageContact(
          userId: conversation.otherUserId,
          name: conversation.otherUserName,
          role: conversation.otherUserRole ?? 'Researcher',
          conversation: conversation,
        );
      }

      if (mounted) {
        setState(() {
          _contacts = contactsMap.values.toList();
          _contacts.sort(
            (a, b) => a.name.toLowerCase().compareTo(
                  b.name.toLowerCase(),
                ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openChat(_MessageContact contact) async {
    try {
      ConversationModel conversation;

      if (contact.conversation != null) {
        conversation = contact.conversation!;
      } else {
        // Create or retrieve a conversation with the accepted connection.
        conversation = await _apiService.startConversation(contact.userId);
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationTitle: contact.name,
            participantRole: contact.role,
            conversationId: conversation.id,
          ),
        ),
      );

      _loadConversations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load messages',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadConversations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: _contacts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 180),
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 56,
                              color: AppColors.darkTextMuted,
                            ),
                            SizedBox(height: 14),
                            Center(
                              child: Text(
                                'No connections yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Once someone accepts your connection request, '
                                'they will appear here. You can then start '
                                'a private academic conversation.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            final conversation = contact.conversation;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryTeal,
                                  child: Text(
                                    contact.name.isNotEmpty
                                        ? contact.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  contact.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  conversation == null
                                      ? 'Connected • Tap to start chatting'
                                      : conversation.lastMessage.isNotEmpty
                                          ? conversation.lastMessage
                                          : 'Start your conversation',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                                trailing: conversation != null &&
                                        conversation.unreadCount > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.brightTeal,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${conversation.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.darkTextMuted,
                                      ),
                                onTap: () => _openChat(contact),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
