import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';

/// Widget para mostrar el diálogo de selección de idioma
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final supportedLanguages = localeNotifier.getSupportedLanguages();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Row(
              children: [
                Icon(
                  Icons.language_rounded,
                  color: const Color(0xFF00FF88),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.language,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lista de idiomas
            ...supportedLanguages.map((language) {
              final isSelected = currentLocale.languageCode == language.code;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF00FF88).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF00FF88)
                        : Colors.grey[700]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  onTap: () async {
                    await localeNotifier.changeLocale(language.code);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF00FF88)
                          : Colors.grey[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        language.code.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    language.nativeName,
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF00FF88)
                          : Colors.white,
                      fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    language.name,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00FF88),
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: Colors.grey[600],
                        ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Botón cerrar
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.close,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Función helper para mostrar el diálogo de selección de idioma
void showLanguageSelector(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const LanguageSelector(),
  );
}