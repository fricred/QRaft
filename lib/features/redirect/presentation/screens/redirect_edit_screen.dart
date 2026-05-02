import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../domain/entities/redirect_entity.dart';
import '../providers/redirect_providers.dart';

/// Screen that lets an authenticated user update the destination URL of a
/// redirect record identified by its [slug].
///
/// Usage:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => RedirectEditScreen(slug: 'abc123'),
/// ));
/// ```
///
/// When [slug] is empty (QRCodeEntity does not yet carry a slug field) the
/// screen shows a "no redirect linked" message. This is a known limitation
/// tracked as a follow-up: link QRCodeEntity.slug once the column is added to
/// the qr_codes table and the entity model is updated.
class RedirectEditScreen extends ConsumerStatefulWidget {
  const RedirectEditScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<RedirectEditScreen> createState() => _RedirectEditScreenState();
}

class _RedirectEditScreenState extends ConsumerState<RedirectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  /// The redirect record loaded from Supabase; null while loading or on error.
  RedirectEntity? _redirect;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.slug.isNotEmpty) {
      _loadRedirect();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadRedirect() async {
    try {
      final repo = ref.read(redirectRepositoryProvider);
      final entity = await repo.getRedirectBySlug(widget.slug);
      if (mounted) {
        setState(() {
          _redirect = entity;
          _urlController.text = entity?.destinationUrl ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_redirect == null) return;

    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(redirectRepositoryProvider).updateDestinationUrl(
            id: _redirect!.id,
            destinationUrl: _urlController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.redirectDestinationUpdated),
            backgroundColor: const Color(0xFF00FF88),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'redirect_edit_screen_root',
      child: Scaffold(
        key: const Key('redirect_edit_screen_root'),
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l10n.editRedirectDestination,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
        ),
      );
    }

    // No slug was provided — QRCodeEntity does not yet carry a slug field.
    if (widget.slug.isEmpty) {
      return _buildNoSlugMessage(l10n);
    }

    // Slug provided but no record found.
    if (_redirect == null && _loadError == null) {
      return _buildNotFoundMessage(l10n);
    }

    // Network / Supabase error while loading.
    if (_loadError != null) {
      return _buildErrorMessage(_loadError!);
    }

    return _buildForm(l10n);
  }

  Widget _buildForm(AppLocalizations l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slug badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  'qraft.link/${widget.slug}',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                l10n.editRedirectDestination,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // URL field
              Semantics(
                identifier: 'redirect_url_field',
                child: TextFormField(
                  key: const Key('redirect_url_field'),
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'https://example.com',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF00FF88),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2E2E2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00FF88),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'URL cannot be empty';
                    }
                    final uri = Uri.tryParse(trimmed);
                    if (uri == null ||
                        (!uri.isScheme('http') && !uri.isScheme('https'))) {
                      return 'Enter a valid URL (https://...)';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              Semantics(
                identifier: 'redirect_save_button',
                child: _isSaving
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00FF88),
                          ),
                        ),
                      )
                    : PrimaryGlassButton(
                        key: const Key('redirect_save_button'),
                        text: 'Save',
                        icon: Icons.save_rounded,
                        onPressed: _save,
                        width: double.infinity,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSlugMessage(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.link_off_rounded,
                color: Color(0xFFF59E0B),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No redirect linked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This QR code does not have a redirect slug yet. '
              'Order a laser-engraved product to get a dynamic redirect link.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SecondaryGlassButton(
              text: l10n.backButton,
              onPressed: () => Navigator.of(context).pop(),
              width: 120,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundMessage(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Redirect not found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No redirect exists for slug "${widget.slug}".',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SecondaryGlassButton(
              text: l10n.backButton,
              onPressed: () => Navigator.of(context).pop(),
              width: 120,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load redirect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
