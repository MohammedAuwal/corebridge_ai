/// An image attached to the current outgoing message, sent to the AI
/// as vision content for that turn only. Not persisted to Firestore —
/// see the note in the conversation history about why.
class ChatAttachment {
  final String mimeType;
  final String base64Data;
  final String fileName;

  const ChatAttachment({
    required this.mimeType,
    required this.base64Data,
    required this.fileName,
  });
}
