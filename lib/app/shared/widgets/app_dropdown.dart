import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ── Public option model ───────────────────────────────────────────────────────
class BottomSheetOption<T> {
  final T value;
  final String label;

  const BottomSheetOption({required this.value, required this.label});
}

// ── Main widget ───────────────────────────────────────────────────────────────
class AppBottomSheet<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<BottomSheetOption<T>> options;
  final ValueChanged<T?> onChanged;
  final bool required;
  final String? errorText;

  const AppBottomSheet({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.value,
    this.required = false,
    this.errorText,
  });

  String get _displayLabel {
    try {
      return options.firstWhere((o) => o.value == value).label;
    } catch (_) {
      return '';
    }
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // useRootNavigator ensures we always have a valid navigator
      useRootNavigator: true,
      builder: (sheetCtx) => _DropdownSheet<T>(
        title: label,
        options: options,
        selected: value,
        // ✅ Pass sheetCtx into onSelect so Navigator.pop uses the sheet's
        //    own context, never a potentially-deactivated ancestor context.
        onSelect: (v) {
          Navigator.of(sheetCtx).pop();
          onChanged(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final isSelected = value != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDarkGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(color: AppColors.errorRed, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Tappable field
          GestureDetector(
            onTap: () => _openSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError
                      ? AppColors.errorRed
                      : isSelected
                      ? AppColors.primaryGreen
                      : AppColors.primaryGreen.withValues(alpha: 0.5),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_drop_down_circle_outlined,
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.darkGrey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSelected ? _displayLabel : hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.textDarkGreen
                            : AppColors.darkGrey,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.darkGrey,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Error text
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                errorText!,
                style: const TextStyle(color: AppColors.errorRed, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom-sheet picker ───────────────────────────────────────────────────────
class _DropdownSheet<T> extends StatelessWidget {
  final String title;
  final List<BottomSheetOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onSelect;

  const _DropdownSheet({
    required this.title,
    required this.options,
    required this.onSelect,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDarkGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                // ✅ Use context from this build method (sheet's own context)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Options list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final opt = options[i];
                final isSelected = opt.value == selected;
                return InkWell(
                  onTap: () => onSelect(opt.value),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDarkGreen,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
