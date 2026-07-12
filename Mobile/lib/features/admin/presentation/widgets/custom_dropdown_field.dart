import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CustomDropdownField<T> extends FormField<T> {
  final String labelText;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final void Function(T?) onChanged;
  final IconData prefixIcon;
  final String? optionalLabel;

  CustomDropdownField({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
    required this.prefixIcon,
    this.optionalLabel,
    super.validator,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<T> fieldState) {
            final context = fieldState.context;
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final displayValue = fieldState.value;
            final hasError = fieldState.hasError;

            // Resolve selected label text
            final displayLabel = displayValue != null
                ? itemLabelBuilder(displayValue)
                : (optionalLabel ?? 'Select $labelText');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withOpacity(0.5),
                      builder: (context) => _DropdownSelectorSheet<T>(
                        title: labelText,
                        items: items,
                        selectedValue: displayValue,
                        itemLabelBuilder: itemLabelBuilder,
                        onSelected: (newValue) {
                          fieldState.didChange(newValue);
                          onChanged(newValue);
                        },
                        optionalLabel: optionalLabel,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: labelText,
                      prefixIcon: Icon(prefixIcon),
                      suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                      errorText: hasError ? fieldState.errorText : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      displayLabel,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: displayValue == null
                            ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
                            : (isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

class _DropdownSelectorSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) itemLabelBuilder;
  final ValueChanged<T?> onSelected;
  final String? optionalLabel;

  const _DropdownSelectorSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.itemLabelBuilder,
    required this.onSelected,
    this.optionalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceTile3 : Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Mockup Header ("new" or field name category)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F6F6),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                ),
                child: Center(
                  child: Text(
                    title.toLowerCase(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // Dropdown Items List
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Optional Item (if provided)
                      if (optionalLabel != null) ...[
                        _buildItem(
                          context: context,
                          label: optionalLabel!,
                          isSelected: selectedValue == null,
                          onTap: () {
                            onSelected(null);
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(height: 1, thickness: 1),
                      ],

                      // Standard Items
                      for (int i = 0; i < items.length; i++) ...[
                        _buildItem(
                          context: context,
                          label: itemLabelBuilder(items[i]),
                          isSelected: selectedValue == items[i],
                          onTap: () {
                            onSelected(items[i]);
                            Navigator.pop(context);
                          },
                        ),
                        if (i < items.length - 1)
                          const Divider(height: 1, thickness: 1),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            // Left Checkmark
            SizedBox(
              width: 32,
              child: isSelected
                  ? Icon(Icons.check, color: activeColor, size: 20)
                  : const SizedBox.shrink(),
            ),

            // Item text label
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? activeColor
                      : (isDark ? Colors.grey.shade300 : AppColors.ink),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

            // Right Custom Circle Icon matching the mockup design
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
