import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/marketplace_providers.dart';
import '../../domain/entities/material_entity.dart';

class MaterialFilterBar extends ConsumerWidget {
  const MaterialFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider);
    final activeFilter = ref.watch(activeMaterialFilterProvider);

    return catalogAsync.when(
      loading: () => _ShimmerChipRow(),
      error: (_, __) => const SizedBox.shrink(),
      data: (variants) {
        // Extract unique materials preserving insertion order
        final seen = <String>{};
        final materials = <MaterialEntity>[];
        for (final v in variants) {
          if (seen.add(v.material.id)) {
            materials.add(v.material);
          }
        }

        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              // "Todos" chip
              _FilterChip(
                label: 'Todos',
                isSelected: activeFilter.isEmpty,
                onTap: () {
                  ref.read(activeMaterialFilterProvider.notifier).state = '';
                },
              ),
              ...materials.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FilterChip(
                    label: m.displayNameEs,
                    isSelected: activeFilter == m.id,
                    onTap: () {
                      ref.read(activeMaterialFilterProvider.notifier).state =
                          m.id;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00FF88)
              : const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FF88)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey[300],
            fontSize: 14,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder row shown while catalog is loading.
class _ShimmerChipRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF2E2E2E),
        highlightColor: const Color(0xFF3E3E3E),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final width = [72.0, 64.0, 80.0, 60.0][i];
            return Container(
              width: width,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(22),
              ),
            );
          },
        ),
      ),
    );
  }
}
