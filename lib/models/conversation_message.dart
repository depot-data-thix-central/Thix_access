enum MessageDirection { signToSpeech, speechToSign }

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.text,
    required this.direction,
    required this.createdAt,
  });

  final String id;
  final String text;
  final MessageDirection direction;
  final DateTime createdAt;
}
