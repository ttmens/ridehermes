import 'package:flutter/material.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/shared/utils/formatters.dart';

class CarTypeSelector extends StatelessWidget {
  final int selectedType;
  final ValueChanged<int> onChanged;
  final bool showPrice;
  final Map<int, double>? priceEstimates;

  static const carTypes = {1: '快车', 2: '专车', 3: '豪华车'};

  const CarTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.showPrice = false,
    this.priceEstimates,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: carTypes.entries.map((entry) {
        final isSelected = selectedType == entry.key;
        final price = priceEstimates?[entry.key];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(entry.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _carIcon(entry.key),
                    color: isSelected ? AppColors.primary : AppColors.textHint,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (showPrice && price != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatPrice(price),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static IconData _carIcon(int carType) {
    return switch (carType) {
      1 => Icons.directions_car,
      2 => Icons.airport_shuttle,
      3 => Icons.stars,
      _ => Icons.directions_car,
    };
  }
}
