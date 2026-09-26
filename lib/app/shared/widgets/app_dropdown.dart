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
  final bool showSearch;
  final String? searchHint;
  final bool sortAlphabetically;
  final ValueChanged<String>? onAddNew;
  final String? addNewLabel;

  const AppBottomSheet({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.value,
    this.required = false,
    this.errorText,
    this.showSearch = false,
    this.searchHint,
    this.sortAlphabetically = false,
    this.onAddNew,
    this.addNewLabel,
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
        showSearch: showSearch,
        searchHint: searchHint,
        sortAlphabetically: sortAlphabetically,
        onAddNew: onAddNew,
        addNewLabel: addNewLabel,
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
class _DropdownSheet<T> extends StatefulWidget {
  final String title;
  final List<BottomSheetOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onSelect;
  final bool showSearch;
  final String? searchHint;
  final bool sortAlphabetically;
  final ValueChanged<String>? onAddNew;
  final String? addNewLabel;

  const _DropdownSheet({
    required this.title,
    required this.options,
    required this.onSelect,
    this.selected,
    this.showSearch = false,
    this.searchHint,
    this.sortAlphabetically = false,
    this.onAddNew,
    this.addNewLabel,
  });

  @override
  State<_DropdownSheet<T>> createState() => _DropdownSheetState<T>();
}

class _DropdownSheetState<T> extends State<_DropdownSheet<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<BottomSheetOption<T>> _allOptions;

  @override
  void initState() {
    super.initState();
    _initOptions();
  }

  @override
  void didUpdateWidget(_DropdownSheet<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options ||
        oldWidget.sortAlphabetically != widget.sortAlphabetically) {
      _initOptions();
    }
  }

  void _initOptions() {
    _allOptions = List.from(widget.options);
    if (widget.sortAlphabetically) {
      _allOptions.sort(
        (a, b) => a.label.trim().toLowerCase().compareTo(b.label.trim().toLowerCase()),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddCustomDialog(BuildContext context) {
    final customNameCtrl = TextEditingController(text: _searchCtrl.text.trim());
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.addNewLabel ?? 'Add New Disease',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDarkGreen,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the name of the new disease / diagnosis:',
              style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customNameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Migraine, Sciatica...',
                hintStyle: const TextStyle(color: AppColors.darkGrey, fontSize: 14),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = customNameCtrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.of(dialogCtx).pop(); // close dialog
                Navigator.of(context).pop(); // close bottom sheet
                widget.onAddNew?.call(val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _allOptions
        : _allOptions.where((opt) => opt.label.toLowerCase().contains(query)).toList();

    final hasExactMatch = query.isNotEmpty &&
        _allOptions.any((opt) => opt.label.trim().toLowerCase() == query);

    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Container(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: isKeyboardOpen
            ? (mediaQuery.size.height - mediaQuery.padding.top) * 0.95
            : mediaQuery.size.height * 0.85,
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textDarkGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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

          // Search bar
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Search...',
                  hintStyle: const TextStyle(color: AppColors.darkGrey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.darkGrey),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.25)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

          // Quick add card when user is searching and no exact match
          if (widget.onAddNew != null && query.isNotEmpty && !hasExactMatch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () {
                  final name = _searchCtrl.text.trim();
                  Navigator.of(context).pop();
                  widget.onAddNew!(name);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: AppColors.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add "${_searchCtrl.text.trim()}"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Tap to add as new disease and select',
                              style: TextStyle(fontSize: 11, color: AppColors.darkGrey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryGreen),
                    ],
                  ),
                ),
              ),
            ),

          // Options list or empty state
          Flexible(
            child: filtered.isEmpty
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            query.isNotEmpty
                                ? (widget.onAddNew != null
                                    ? 'No disease found matching "$query"'
                                    : 'No options found matching "$query"')
                                : 'No options available',
                            style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.onAddNew != null && query.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                final name = _searchCtrl.text.trim();
                                Navigator.of(context).pop();
                                widget.onAddNew!(name);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: Text('Add "${_searchCtrl.text.trim()}" as Disease'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final opt = filtered[i];
                      final isSelected = opt.value == widget.selected;
                      return InkWell(
                        onTap: () => widget.onSelect(opt.value),
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

          // Bottom "Add Other / New Disease" button
          if (widget.onAddNew != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: OutlinedButton.icon(
                onPressed: () => _showAddCustomDialog(context),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(widget.addNewLabel ?? 'Add Other / New Disease'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
