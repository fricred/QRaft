import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../domain/entities/product_entity.dart';

/// Customization section with size and finish selectors in a glassmorphism card.
class CustomizationSection extends StatelessWidget {
  final List<String> availableSizes;
  final String selectedSize;
  final ValueChanged<String> onSizeChanged;
  final List<ProductFinish> availableFinishes;
  final ProductFinish? selectedFinish;
  final ValueChanged<ProductFinish> onFinishChanged;

  const CustomizationSection({
    super.key,
    required this.availableSizes,
    required this.selectedSize,
    required this.onSizeChanged,
    required this.availableFinishes,
    required this.selectedFinish,
    required this.onFinishChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                  const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Text(
                  l10n.customization,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Size selector
                _SizeSelector(
                  label: l10n.selectSize,
                  sizes: availableSizes,
                  selectedSize: selectedSize,
                  onSizeChanged: onSizeChanged,
                ),

                const SizedBox(height: 24),

                // Finish selector
                _FinishSelector(
                  label: l10n.selectFinish,
                  finishes: availableFinishes,
                  selectedFinish: selectedFinish,
                  onFinishChanged: onFinishChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Size selector with animated chips
class _SizeSelector extends StatelessWidget {
  final String label;
  final List<String> sizes;
  final String selectedSize;
  final ValueChanged<String> onSizeChanged;

  const _SizeSelector({
    required this.label,
    required this.sizes,
    required this.selectedSize,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sizes.asMap().entries.map((entry) {
            final index = entry.key;
            final size = entry.value;
            final isSelected = size == selectedSize;

            return _SizeChip(
              size: size,
              isSelected: isSelected,
              onTap: () => onSizeChanged(size),
            ).animate(delay: (50 * index).ms)
              .scale(begin: const Offset(0.9, 0.9), duration: 200.ms, curve: Curves.easeOutBack);
          }).toList(),
        ),
      ],
    );
  }
}

/// Individual size chip with selection animation
class _SizeChip extends StatefulWidget {
  final String size;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SizeChip> createState() => _SizeChipState();
}

class _SizeChipState extends State<_SizeChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                  )
                : null,
            color: widget.isSelected ? null : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.size,
              style: TextStyle(
                color: widget.isSelected ? Colors.white : Colors.grey[400],
                fontSize: 16,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Finish selector with horizontal scrolling cards
class _FinishSelector extends StatelessWidget {
  final String label;
  final List<ProductFinish> finishes;
  final ProductFinish? selectedFinish;
  final ValueChanged<ProductFinish> onFinishChanged;

  const _FinishSelector({
    required this.label,
    required this.finishes,
    required this.selectedFinish,
    required this.onFinishChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: finishes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final finish = finishes[index];
              final isSelected = finish.id == selectedFinish?.id;

              return _FinishCard(
                finish: finish,
                isSelected: isSelected,
                onTap: () => onFinishChanged(finish),
              ).animate(delay: (50 * index).ms)
                .fadeIn(duration: 200.ms)
                .slideX(begin: 0.1, duration: 200.ms, curve: Curves.easeOutQuart);
            },
          ),
        ),
      ],
    );
  }
}

/// Individual finish card with price modifier
class _FinishCard extends StatefulWidget {
  final ProductFinish finish;
  final bool isSelected;
  final VoidCallback onTap;

  const _FinishCard({
    required this.finish,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FinishCard> createState() => _FinishCardState();
}

class _FinishCardState extends State<_FinishCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF00FF88)
                  : Colors.white.withValues(alpha: 0.1),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color preview
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.finish.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Finish name
              Text(
                widget.finish.name,
                style: TextStyle(
                  color: widget.isSelected ? Colors.white : Colors.grey[400],
                  fontSize: 11,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              // Price modifier
              if (widget.finish.priceModifier > 0)
                Text(
                  '+\$${widget.finish.priceModifier.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
