import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../controllers/event_form_controller.dart';

/// Form widget for the Event QR type.
///
/// Fields:
///   - QR Code Name (required)
///   - Event Title (required)
///   - Start Date & Time (required)
///   - End Date & Time (optional)
///   - Location (optional)
///   - Description (optional, max 500 chars — T-02-07 DoS mitigation)
class EventForm extends ConsumerWidget {
  final VoidCallback onContinue;

  const EventForm({super.key, required this.onContinue});

  static const _inputDecoration = InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF3A3A3A),
    labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
    hintStyle: TextStyle(color: Color(0xFF6B7280)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF4B5563)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF06B6D4), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(eventFormProvider.notifier);

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: _inputDecoration,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ────────────────────────────────────────────
            Text(
              'Calendar Event',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.3, duration: 600.ms),

            const SizedBox(height: 8),

            Text(
              'Generate an iCal QR code that adds your event to any calendar app',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 100.ms),

            const SizedBox(height: 32),

            // ── QR Code Name ──────────────────────────────────────────────
            _buildLabel('QR Code Name *'),
            const SizedBox(height: 8),
            FormBuilderTextField(
              name: 'qr_name',
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'My Event QR',
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Please enter a name'),
                FormBuilderValidators.minLength(2, errorText: 'At least 2 characters'),
              ]),
              onChanged: (v) => controller.updateName(v ?? ''),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 20),

            // ── Event Title ───────────────────────────────────────────────
            _buildLabel('Event Title *'),
            const SizedBox(height: 8),
            FormBuilderTextField(
              name: 'title',
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Team Meeting',
              ),
              validator: FormBuilderValidators.required(errorText: 'Event title is required'),
              onChanged: (v) => controller.updateTitle(v ?? ''),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 20),

            // ── Start Date & Time ─────────────────────────────────────────
            _buildLabel('Start Date & Time *'),
            const SizedBox(height: 8),
            FormBuilderDateTimePicker(
              name: 'start_date_time',
              inputType: InputType.both,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Select start date and time',
                suffixIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF06B6D4)),
              ),
              validator: FormBuilderValidators.required(errorText: 'Start date and time is required'),
              onChanged: (v) => controller.updateStartDateTime(v),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 250.ms),

            const SizedBox(height: 20),

            // ── End Date & Time ───────────────────────────────────────────
            _buildLabel('End Date & Time'),
            const SizedBox(height: 8),
            FormBuilderDateTimePicker(
              name: 'end_date_time',
              inputType: InputType.both,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Select end date and time (optional)',
                suffixIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF06B6D4)),
              ),
              onChanged: (v) => controller.updateEndDateTime(v),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 20),

            // ── Location ──────────────────────────────────────────────────
            _buildLabel('Location'),
            const SizedBox(height: 8),
            FormBuilderTextField(
              name: 'location',
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Conference Room A (optional)',
              ),
              onChanged: (v) => controller.updateLocation(v ?? ''),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 350.ms),

            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────────────────
            _buildLabel('Description'),
            const SizedBox(height: 8),
            FormBuilderTextField(
              name: 'description',
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              maxLength: 500,
              // T-02-07: cap at 500 chars to avoid QR module explosion
              decoration: const InputDecoration(
                hintText: 'Event details (optional)',
                alignLabelWithHint: true,
              ),
              onChanged: (v) => controller.updateDescription(v ?? ''),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
