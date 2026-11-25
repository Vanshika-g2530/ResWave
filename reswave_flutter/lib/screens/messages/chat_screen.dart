import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/message_models.dart';
import '../../services/api_client.dart';

class ChatScreen extends StatefulWidget {
  final String conversationTitle;
  final String participantRole;
  final String? conversationId;
  final String? targetUserId;

  const ChatScreen({
    super.key,
    required this.conversationTitle,
    required this.participantRole,
    this.conversationId,
    this.targetUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ResWaveApiService _apiService = ResWaveApiService();

  String? _activeConvId;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _activeConvId = widget.conversationId;
    _initializeChat();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      if (_activeConvId == null && widget.targetUserId != null) {
        final conv = await _apiService.startConversation(widget.targetUserId!);
        _activeConvId = conv.id;
      }
      if (_activeConvId != null) {
        final msgs = await _apiService.getMessages(_activeConvId!);
        if (mounted) setState(() => _messages = msgs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _activeConvId == null) return;
    _msgController.clear();
    setState(() => _isSending = true);
    try {
      final msg = await _apiService.sendMessage(_activeConvId!, text);
      setState(() => _messages.add(msg));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _apiService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversationTitle, style: const TextStyle(fontSize: 16)),
            Text(widget.participantRole, style: const TextStyle(fontSize: 11, color: AppColors.brightTeal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _initializeChat,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Academic collaboration channel initialized. Send a message to begin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.darkTextSecondary),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final m = _messages[index];
                            final isMe = m.senderId == myUid;
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.primaryTeal : AppColors.darkSurface,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(14),
                                    topRight: const Radius.circular(14),
                                    bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                                    bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                                  ),
                                  border: Border.all(color: isMe ? AppColors.deepTeal : AppColors.darkBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.text,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : AppColors.darkTextPrimary,
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      m.senderName,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isMe ? Colors.white70 : AppColors.darkTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Message input bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.darkSurface,
                    border: Border(top: BorderSide(color: AppColors.darkBorder)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Discuss research questions or findings...',
                              filled: true,
                              fillColor: AppColors.darkBackground,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                          icon: _isSending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
