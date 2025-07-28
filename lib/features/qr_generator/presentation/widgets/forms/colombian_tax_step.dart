import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'colombian_tax_form.dart';

class ColombianTaxStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const ColombianTaxStep({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<ColombianTaxStep> createState() => _ColombianTaxStepState();
}

class _ColombianTaxStepState extends ConsumerState<ColombianTaxStep> {
  final _economicActivityController = TextEditingController();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      _initialized = true;
      
      // Initialize controllers with existing state
      final currentState = ref.read(colombianTaxFormProvider);
      
      _economicActivityController.text = currentState.economicActivity;
      
      // Defer listener setup to avoid provider modification during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupListeners();
      });
    }
  }

  void _setupListeners() {
    _economicActivityController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateEconomicActivity(_economicActivityController.text);
    });
  }

  @override
  void dispose() {
    _economicActivityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(colombianTaxFormProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24, 
        24, 
        24, 
        24 + MediaQuery.of(context).viewInsets.bottom
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Tributaria',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Datos fiscales opcionales para facturación avanzada',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          // Tax regime
          _buildDropdownField(
            label: 'Régimen Tributario',
            value: formState.taxRegime,
            items: ColombianTaxFormController.taxRegimes,
            onChanged: (value) {
              ref.read(colombianTaxFormProvider.notifier).updateTaxRegime(value!);
            },
            hint: 'Selecciona el régimen',
            icon: Icons.account_balance_rounded,
          ),
          
          const SizedBox(height: 24),
          
          // Economic activity
          _buildTextField(
            controller: _economicActivityController,
            label: 'Actividad Económica (Opcional)',
            hint: 'Código CIIU principal o descripción',
            maxLines: 2,
            icon: Icons.work_rounded,
          ),
          
          const SizedBox(height: 32),
          
          // Tax responsibilities section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Responsabilidades Fiscales',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecciona las responsabilidades fiscales que aplican:',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ColombianTaxFormController.commonTaxResponsibilities.map((responsibility) {
                    final isSelected = formState.taxResponsibilities.contains(responsibility);
                    return FilterChip(
                      label: Text(
                        responsibility,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontSize: 11,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(colombianTaxFormProvider.notifier).toggleTaxResponsibility(responsibility);
                      },
                      backgroundColor: const Color(0xFF3E3E3E),
                      selectedColor: const Color(0xFF1A73E8),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[600]!,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 400.ms),
          
          const SizedBox(height: 32),
          
          // Optional info notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información Opcional',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estos campos son opcionales. Puedes continuar sin completarlos y agregarlos después si es necesario.',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFEF4444)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
                child: Icon(
                  icon,
                  color: errorText != null
                      ? const Color(0xFFEF4444)
                      : Colors.grey[400],
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
            ),
          ),
        ],
      ],
    ).animate()
      .fadeIn(duration: 600.ms, delay: 300.ms)
      .slideY(begin: 0.3, duration: 600.ms, delay: 300.ms);
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    String? errorText,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFEF4444)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  icon,
                  color: errorText != null
                      ? const Color(0xFFEF4444)
                      : Colors.grey[400],
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    hint: Text(
                      hint ?? 'Seleccionar...',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    dropdownColor: const Color(0xFF2E2E2E),
                    style: const TextStyle(color: Colors.white),
                    onChanged: onChanged,
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
            ),
          ),
        ],
      ],
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
      .slideY(begin: 0.3, duration: 600.ms, delay: 200.ms);
  }
}