import 'dart:async';
import 'dart:convert';

/// A single Server-Sent Event.
class SseEvent {
  final String event;
  final String data;

  const SseEvent({required this.event, required this.data});

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}

/// Lightweight SSE parser — no external dependencies.
///
/// Takes a raw byte stream (from Dio's `ResponseType.stream`) and yields
/// [SseEvent] objects according to the SSE specification:
///   - Lines starting with `event:` set the event type
///   - Lines starting with `data:` accumulate the data payload
///   - An empty line signals the end of an event
///   - Lines starting with `:` are comments (ignored)
class SseClient {
  SseClient._();

  /// Parse a raw byte stream into a stream of [SseEvent]s.
  static Stream<SseEvent> parse(Stream<List<int>> byteStream) async* {
    String currentEvent = 'message';
    final dataBuffer = StringBuffer();

    await for (final line
        in utf8.decoder.bind(byteStream).transform(const LineSplitter())) {
      // Empty line = dispatch the accumulated event
      if (line.isEmpty) {
        if (dataBuffer.isNotEmpty) {
          yield SseEvent(
            event: currentEvent,
            data: dataBuffer.toString(),
          );
          dataBuffer.clear();
          currentEvent = 'message';
        }
        continue;
      }

      // Comment line — ignore
      if (line.startsWith(':')) continue;

      // Field parsing
      final colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue;

      final field = line.substring(0, colonIndex);
      // SSE spec: if there's a space after the colon, skip it
      final value =
          (colonIndex + 1 < line.length && line[colonIndex + 1] == ' ')
              ? line.substring(colonIndex + 2)
              : line.substring(colonIndex + 1);

      switch (field) {
        case 'event':
          currentEvent = value;
          break;
        case 'data':
          if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
          dataBuffer.write(value);
          break;
        // 'id' and 'retry' are part of SSE spec but unused here
        default:
          break;
      }
    }

    // Flush any trailing event without a final empty line
    if (dataBuffer.isNotEmpty) {
      yield SseEvent(event: currentEvent, data: dataBuffer.toString());
    }
  }
}
