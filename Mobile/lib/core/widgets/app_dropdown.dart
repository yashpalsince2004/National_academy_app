import 'package:flutter/material.dart';
import 'package:national_academy/core/constants/app_colors.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
  final Color? activeColor;

  AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.activeColor,
  });
}

class AppDropdown<T> extends FormField<T> {
  final String? label;
  final String? headerText;
  final T value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final String hintText;
  final bool isFullWidthButton;
  final BorderRadius? borderRadius;
  final bool showDownArrow;
  final EdgeInsetsGeometry? padding;
  final TextAlign textAlign;

  AppDropdown({
    super.key,
    this.label,
    this.headerText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText = 'Select option',
    this.isFullWidthButton = true,
    this.borderRadius,
    this.showDownArrow = true,
    this.padding,
    this.textAlign = TextAlign.start,
    super.validator,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<T> state) {
            final context = state.context;
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final dropdown = state.widget as AppDropdown<T>;

            // Find current selected item
            final currentItem = items.firstWhere(
              (item) => item.value == value,
              orElse: () => AppDropdownItem(value: value, label: ''),
            );

            void showDropdownMenu() async {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final size = renderBox.size;
              final offset = renderBox.localToGlobal(Offset.zero);

              final List<PopupMenuEntry<T>> entries = [];

              // Add Header if present
              if (headerText != null) {
                entries.add(
                  PopupMenuItem<T>(
                    enabled: false,
                    height: 36,
                    child: Center(
                      child: Text(
                        headerText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
                entries.add(const PopupMenuDivider(height: 1));
              }

              // Add Items
              for (int i = 0; i < items.length; i++) {
                final item = items[i];
                final isSelected = item.value == value;

                entries.add(
                  PopupMenuItem<T>(
                    value: item.value,
                    enabled: item.enabled,
                    height: 48,
                    child: Opacity(
                      opacity: item.enabled ? 1.0 : 0.4,
                      child: Row(
                        children: [
                          // Checkmark Prefix
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              color: item.activeColor ?? (isDark ? AppColors.primaryOnDark : AppColors.primary),
                              size: 18,
                            )
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 12),

                          // Label Text
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? (item.activeColor ?? (isDark ? AppColors.primaryOnDark : AppColors.primary))
                                    : (isDark ? Colors.white : AppColors.textPrimary),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14.5,
                              ),
                            ),
                          ),

                          // Trailing Icon
                          if (item.icon != null)
                            Icon(
                              item.icon,
                              size: 18,
                              color: isSelected
                                  ? (item.activeColor ?? (isDark ? AppColors.primaryOnDark : AppColors.primary))
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                  ),
                );

                // Add dividers between all items except the last one
                if (i < items.length - 1) {
                  entries.add(const AppPopupMenuDivider());
                }
              }

              final selectedValue = await showMenu<T>(
                context: context,
                position: RelativeRect.fromLTRB(
                  offset.dx,
                  offset.dy + size.height + 4,
                  offset.dx + size.width,
                  offset.dy + size.height + 100,
                ),
                items: entries,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF333335) : AppColors.hairline,
                  ),
                ),
                color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF5F5F7),
                elevation: 4,
              );

              if (selectedValue != null) {
                state.didChange(selectedValue);
                onChanged(selectedValue);
              }
            }

            final dropdownBorderRadius = dropdown.borderRadius ?? BorderRadius.circular(14);

            final dropdownWidget = InkWell(
              onTap: showDropdownMenu,
              borderRadius: dropdownBorderRadius,
              child: Container(
                padding: dropdown.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceTile1 : Colors.white,
                  borderRadius: dropdownBorderRadius,
                  border: Border.all(
                    color: state.hasError
                        ? Colors.red
                        : (isDark ? const Color(0xFF333335) : AppColors.hairline),
                  ),
                ),
                child: Row(
                  mainAxisSize: isFullWidthButton ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isFullWidthButton)
                      Expanded(
                        child: Text(
                          currentItem.label.isNotEmpty
                              ? currentItem.label
                              : (headerText ?? 'Select Option'),
                          textAlign: dropdown.textAlign,
                          style: TextStyle(
                            color: currentItem.label.isNotEmpty
                                ? (isDark ? Colors.white : AppColors.textPrimary)
                                : AppColors.textLight,
                            fontWeight: FontWeight.normal,
                            fontSize: 14.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Text(
                        currentItem.label.isNotEmpty
                            ? currentItem.label
                            : (headerText ?? 'Select Option'),
                        textAlign: dropdown.textAlign,
                        style: TextStyle(
                          color: currentItem.label.isNotEmpty
                              ? (isDark ? Colors.white : AppColors.textPrimary)
                              : AppColors.textLight,
                          fontWeight: FontWeight.normal,
                          fontSize: 14.5,
                        ),
                      ),
                    if (dropdown.showDownArrow) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textLight,
                      ),
                    ],
                  ],
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null) ...[
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
                dropdownWidget,
                if (state.hasError) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      state.errorText ?? '',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ],
            );
          },
        );
}

class AppPopupMenuDivider extends PopupMenuEntry<Never> {
  const AppPopupMenuDivider({super.key});

  @override
  double get height => 1;

  @override
  bool represents(void value) => false;

  @override
  State<AppPopupMenuDivider> createState() => _AppPopupMenuDividerState();
}

class _AppPopupMenuDividerState extends State<AppPopupMenuDivider> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300,
    );
  }
}
