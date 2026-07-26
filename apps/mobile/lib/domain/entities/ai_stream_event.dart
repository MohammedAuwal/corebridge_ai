enum AiStreamEventType { thinking, content }

/// A single chunk from the AI stream, tagged as either the model's
/// internal reasoning ("thinking") or the actual answer ("content").
/// Providers that don't support exposing thinking (currently OpenAI's
/// chat endpoint) only ever emit `content` events.
class AiStreamEvent {
  final AiStreamEventType type;
  final String text;

  const AiStreamEvent({required this.type, required this.text});
}
