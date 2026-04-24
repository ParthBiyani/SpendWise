import 'package:flutter/material.dart';

class FilterDropdown extends StatefulWidget {
  const FilterDropdown({
    super.key,
    this.icon,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.isMultiSelect = false,
    this.badge,
    this.showIcon = true,
    this.highlightWhenSelected = true,
    this.showAllOption = false,
  });

  final IconData? icon;
  final String label;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isMultiSelect;
  final int? badge;
  final bool showIcon;
  final bool highlightWhenSelected;
  final bool showAllOption;

  @override
  State<FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<FilterDropdown> {
  bool _isDropdownOpen = false;

  void _showDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    // Get button position
    final buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonBottomRight = button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay);
    
    // Calculate initial position
    var left = buttonTopLeft.dx;
    var top = buttonBottomRight.dy - 32;
    const menuWidth = 200.0;
    
    // Adjust if menu would overflow right edge
    if (left + menuWidth > overlay.size.width - 16) {
      left = overlay.size.width - menuWidth - 16;
    }
    
    // Ensure left doesn't go below 0
    if (left < 16) {
      left = 16;
    }
    
    // Adjust if menu would overflow bottom
    const menuMaxHeight = 300.0;
    if (top + menuMaxHeight > overlay.size.height) {
      top = buttonTopLeft.dy - menuMaxHeight - 8;
    }
    
    // Scroll the parent ListView to make the button fully visible
    try {
      final scrollable = Scrollable.of(context);
      {
        // Calculate the button's position relative to the viewport
        final renderViewport = scrollable.context.findRenderObject() as RenderBox?;
        if (renderViewport != null) {
          final buttonInViewport = button.localToGlobal(Offset.zero, ancestor: renderViewport);
          
          // If button is partially visible, scroll to make it fully visible
          if (buttonInViewport.dx < 0 || buttonInViewport.dx + button.size.width > renderViewport.size.width) {
            // Scroll horizontally
            scrollable.position.animateTo(
              scrollable.position.pixels + buttonInViewport.dx - 16,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    } catch (e) {
      // Silently ignore if scrollable is not found
    }
    
    final position = RelativeRect.fromLTRB(left, top, overlay.size.width - (left + menuWidth), 0);

    setState(() {
      _isDropdownOpen = true;
    });

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _FilterDropdownMenu(
        position: position,
        theme: theme,
        items: widget.items,
        selectedItems: widget.selectedItems,
        isMultiSelect: widget.isMultiSelect,
        onChanged: widget.onChanged,
        showAllOption: widget.showAllOption,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isDropdownOpen = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = widget.highlightWhenSelected && widget.selectedItems.isNotEmpty;

    return InkWell(
      onTap: () => _showDropdown(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasSelection ? theme.colorScheme.primary : Colors.white,
          border: Border.all(
            color: _isDropdownOpen
                ? theme.colorScheme.primary
                : theme.colorScheme.primary,
            width: _isDropdownOpen ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isDropdownOpen
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showIcon && widget.icon != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: hasSelection ? Colors.white : theme.textTheme.bodyMedium?.color,
                  ),
                  if (widget.badge != null && widget.badge! > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${widget.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            if (widget.showIcon && widget.icon != null) const SizedBox(width: 6),
            if (!widget.showIcon && widget.badge != null && widget.badge! > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '${widget.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Text(
              widget.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasSelection ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: hasSelection ? Colors.white : theme.textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdownMenu extends StatefulWidget {
  const _FilterDropdownMenu({
    required this.position,
    required this.theme,
    required this.items,
    required this.selectedItems,
    required this.isMultiSelect,
    required this.onChanged,
    this.showAllOption = false,
  });

  final RelativeRect position;
  final ThemeData theme;
  final List<String> items;
  final List<String> selectedItems;
  final bool isMultiSelect;
  final ValueChanged<List<String>> onChanged;
  final bool showAllOption;

  @override
  State<_FilterDropdownMenu> createState() => _FilterDropdownMenuState();
}

class _FilterDropdownMenuState extends State<_FilterDropdownMenu> {
  late List<String> _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = List<String>.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          left: widget.position.left,
          top: widget.position.top,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 200,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: widget.showAllOption ? widget.items.length + 1 : widget.items.length,
                      itemBuilder: (context, index) {
                        // Handle "All" option
                        if (widget.showAllOption && index == 0) {
                          final isAllSelected = _currentSelection.isEmpty || _currentSelection.length == widget.items.length;
                          return InkWell(
                            onTap: () {
                              if (widget.isMultiSelect) {
                                setState(() {
                                  _currentSelection.clear();
                                });
                                widget.onChanged([]);
                              } else {
                                widget.onChanged([]);
                                Navigator.of(context).pop();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isAllSelected
                                    ? widget.theme.colorScheme.primary.withValues(alpha: 0.1)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  if (widget.isMultiSelect)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Icon(
                                        isAllSelected
                                            ? Icons.check_box
                                            : (_currentSelection.isNotEmpty
                                                ? Icons.indeterminate_check_box
                                                : Icons.check_box_outline_blank),
                                        size: 20,
                                        color: isAllSelected || _currentSelection.isNotEmpty
                                            ? widget.theme.colorScheme.primary
                                            : Colors.grey,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      'All',
                                      style: widget.theme.textTheme.bodyMedium?.copyWith(
                                        color: isAllSelected
                                            ? widget.theme.colorScheme.primary
                                            : widget.theme.textTheme.bodyMedium?.color,
                                        fontWeight: isAllSelected ? FontWeight.w600 : null,
                                      ),
                                    ),
                                  ),
                                  if (!widget.isMultiSelect && isAllSelected)
                                    Icon(
                                      Icons.check,
                                      size: 20,
                                      color: widget.theme.colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        final itemIndex = widget.showAllOption ? index - 1 : index;
                        final item = widget.items[itemIndex];
                        final isSelected = _currentSelection.contains(item);
                        return InkWell(
                          onTap: () {
                            if (widget.isMultiSelect) {
                              setState(() {
                                if (isSelected) {
                                  _currentSelection.remove(item);
                                } else {
                                  _currentSelection.add(item);
                                }
                              });
                              widget.onChanged(_currentSelection);
                            } else {
                              Navigator.of(context).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                widget.onChanged([item]);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.theme.colorScheme.primary.withValues(alpha: 0.1)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                if (widget.isMultiSelect)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 20,
                                      color: isSelected
                                          ? widget.theme.colorScheme.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                                      color: isSelected
                                          ? widget.theme.colorScheme.primary
                                          : widget.theme.textTheme.bodyMedium?.color,
                                      fontWeight: isSelected ? FontWeight.w600 : null,
                                    ),
                                  ),
                                ),
                                if (!widget.isMultiSelect && isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 20,
                                    color: widget.theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
