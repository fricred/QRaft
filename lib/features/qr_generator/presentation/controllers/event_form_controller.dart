import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/qr_data_models.dart';

/// Immutable state for the Event QR form.
class EventFormState {
  final String name;
  final String title;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String location;
  final String description;
  final bool isValid;

  const EventFormState({
    this.name = '',
    this.title = '',
    this.startDateTime,
    this.endDateTime,
    this.location = '',
    this.description = '',
    this.isValid = false,
  });

  EventFormState copyWith({
    String? name,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? location,
    String? description,
    bool? isValid,
    bool clearEndDateTime = false,
  }) {
    return EventFormState(
      name: name ?? this.name,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: clearEndDateTime ? null : (endDateTime ?? this.endDateTime),
      location: location ?? this.location,
      description: description ?? this.description,
      isValid: isValid ?? this.isValid,
    );
  }

  /// Build an [EventData] from current state; returns null if form is invalid.
  EventData? toEventData() {
    if (title.trim().isEmpty || startDateTime == null) return null;
    return EventData(
      title: title.trim(),
      location: location.trim(),
      startDateTime: startDateTime!,
      endDateTime: endDateTime,
      description: description.trim().isEmpty ? null : description.trim(),
    );
  }
}

/// StateNotifier that manages [EventFormState].
class EventFormController extends StateNotifier<EventFormState> {
  EventFormController() : super(const EventFormState());

  void updateName(String v) {
    state = state.copyWith(name: v);
  }

  void updateTitle(String v) {
    state = state.copyWith(title: v, isValid: _validate(title: v));
  }

  void updateStartDateTime(DateTime? v) {
    state = state.copyWith(startDateTime: v, isValid: _validate(startDateTime: v));
  }

  void updateEndDateTime(DateTime? v) {
    if (v == null) {
      state = state.copyWith(clearEndDateTime: true);
    } else {
      state = state.copyWith(endDateTime: v);
    }
  }

  void updateLocation(String v) {
    state = state.copyWith(location: v);
  }

  void updateDescription(String v) {
    state = state.copyWith(description: v);
  }

  /// Pre-fill state from an existing [EventData] (edit mode).
  void loadFromEntity(EventData data, String qrName) {
    state = EventFormState(
      name: qrName,
      title: data.title,
      startDateTime: data.startDateTime,
      endDateTime: data.endDateTime,
      location: data.location,
      description: data.description ?? '',
      isValid: true,
    );
  }

  void reset() => state = const EventFormState();

  bool _validate({String? title, DateTime? startDateTime}) {
    final t = title ?? state.title;
    final s = startDateTime ?? state.startDateTime;
    return t.trim().isNotEmpty && s != null;
  }
}

final eventFormProvider =
    StateNotifierProvider.autoDispose<EventFormController, EventFormState>(
  (ref) => EventFormController(),
);
